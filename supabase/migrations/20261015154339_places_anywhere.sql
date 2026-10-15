-- BigBack · 0011 · Rank restaurants anywhere, not just Waterloo.
-- Sign-up stays UW-only (@uwaterloo.ca), but students eat at home, on co-op and on trips. Every place
-- now carries its own time zone and country (from MapKit), so "open now" is right outside Ontario and
-- US places aren't stored as Canadian.
-- resolve_place gains two optional parameters. CREATE OR REPLACE can't add parameters and two
-- overloads would make PostgREST calls ambiguous, so the old version is renamed and locked
-- (the Supabase MCP holds DROP statements; drop _resolve_place_v1 from the SQL editor later).

alter table public.places add column if not exists timezone text;
comment on column public.places.timezone is
  'IANA time zone of the place (MapKit MKMapItem.timeZone). Null means America/Toronto.';

-- The place's own time zone wins; p_tz is only the fallback for places without one.
create or replace function public.is_open_at(p_place_id uuid, p_at timestamptz default now(), p_tz text default 'America/Toronto')
returns boolean
language sql
stable
set search_path = ''
as $$
  with t as (
    select (p_at at time zone coalesce(
      (select pl.timezone from public.places pl where pl.id = p_place_id), p_tz)) as local_ts
  ), d as (
    select extract(dow from local_ts)::int as dow,
           ((extract(dow from local_ts)::int + 6) % 7) as yday,
           local_ts::time as tod
    from t
  )
  select case
    when not exists (select 1 from public.place_hours h where h.place_id = p_place_id) then null
    else exists (
      select 1 from public.place_hours h, d
      where h.place_id = p_place_id and (
        (h.dow = d.dow and h.closes > h.opens and d.tod >= h.opens and d.tod < h.closes)
        or (h.dow = d.dow and h.closes <= h.opens and d.tod >= h.opens)
        or (h.dow = d.yday and h.closes <= h.opens and d.tod < h.closes)
      )
    )
  end;
$$;

alter function public.resolve_place(text, text, double precision, double precision, text, text)
  rename to _resolve_place_v1;
revoke execute on function public._resolve_place_v1(text, text, double precision, double precision, text, text)
  from public, anon, authenticated;

create or replace function public.resolve_place(
  p_apple_place_id text,
  p_name           text,
  p_lat            double precision,
  p_lng            double precision,
  p_category       text default null,
  p_address        text default null,
  p_country        text default null,   -- ISO 3166-1 alpha-2 from MapKit, e.g. CA, US
  p_timezone       text default null)   -- IANA name from MKMapItem.timeZone, e.g. America/Vancouver
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := auth.uid();
  v_id      uuid;
  v_key     text := public.search_key(p_name);
  v_here    extensions.geography := extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography;
  v_imp     public.place_import;
  v_country text := upper(nullif(trim(p_country), ''));
  v_tz      text := nullif(trim(p_timezone), '');
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_name is null or char_length(trim(p_name)) = 0 then raise exception 'name required'; end if;
  if p_lat not between -90 and 90 or p_lng not between -180 and 180 then raise exception 'bad coordinates'; end if;
  if v_country !~ '^[A-Z]{2}$' then v_country := null; end if;
  if v_tz is not null and not exists (select 1 from pg_catalog.pg_timezone_names z where z.name = v_tz) then
    v_tz := null;
  end if;

  -- 1. already linked (fill in a missing time zone on the way)
  if p_apple_place_id is not null then
    select id into v_id from public.places where apple_place_id = p_apple_place_id;
    if v_id is not null then
      update public.places set timezone = v_tz where id = v_id and timezone is null and v_tz is not null;
      return v_id;
    end if;
  end if;

  -- 2. an existing place within 75 m with a similar name
  select p.id into v_id
  from public.places p
  where extensions.st_dwithin(p.location, v_here, 75)
    and extensions.similarity(p.name_key, v_key) > 0.45
  order by extensions.similarity(p.name_key, v_key) desc, extensions.st_distance(p.location, v_here)
  limit 1;
  if v_id is not null then
    update public.places
    set apple_place_id = coalesce(apple_place_id, p_apple_place_id),
        timezone       = coalesce(timezone, v_tz)
    where id = v_id
      and ((apple_place_id is null and p_apple_place_id is not null) or (timezone is null and v_tz is not null));
    return v_id;
  end if;

  -- 3. open-data staging (FSQ / Overture / OSM) → promote
  select i.* into v_imp
  from public.place_import i
  where i.matched_place_id is null
    and extensions.st_dwithin(i.location, v_here, 75)
    and extensions.similarity(i.name_key, v_key) > 0.45
  order by extensions.similarity(i.name_key, v_key) desc, extensions.st_distance(i.location, v_here)
  limit 1;
  if found then
    insert into public.places (name, location, address, locality, region, postcode, country, timezone, primary_category,
                               phone, website, apple_place_id, fsq_place_id, overture_id, osm_id, source, created_by)
    values (v_imp.name, v_imp.location, v_imp.address, v_imp.locality, v_imp.region, v_imp.postcode,
            coalesce(v_imp.country, v_country, 'CA'), v_tz, coalesce(v_imp.categories[1], p_category),
            v_imp.phone, v_imp.website,
            p_apple_place_id,
            case when v_imp.source = 'fsq' then v_imp.source_id end,
            case when v_imp.source = 'overture' then v_imp.source_id end,
            case when v_imp.source = 'osm' then v_imp.source_id end,
            v_imp.source, v_uid)
    returning id into v_id;
    update public.place_import set matched_place_id = v_id
    where source = v_imp.source and source_id = v_imp.source_id;
    return v_id;
  end if;

  -- 4. new user-sourced place (rate-limited against spam)
  if (select count(*) from public.places
      where created_by = v_uid and source = 'user' and created_at > now() - interval '1 day') >= 30 then
    raise exception 'too many new places today';
  end if;
  insert into public.places (name, location, address, country, timezone, primary_category, apple_place_id, source, created_by)
  values (left(trim(p_name), 120), v_here, p_address, coalesce(v_country, 'CA'), v_tz, p_category, p_apple_place_id, 'user', v_uid)
  returning id into v_id;
  return v_id;
end;
$$;

revoke execute on function public.resolve_place(text, text, double precision, double precision, text, text, text, text) from public, anon;
grant execute on function public.resolve_place(text, text, double precision, double precision, text, text, text, text) to authenticated;
