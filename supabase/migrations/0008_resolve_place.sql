-- BigBack · 0008 · resolve_place: map a MapKit result to our canonical place.
-- Order: known Apple ID → existing place nearby with a similar name → open-data staging match
-- (promoted into places) → new user-sourced place. Apple's name/coordinates are used only to
-- match; when nothing matches, the user-confirmed name is stored as a user-sourced record.

create or replace function public.resolve_place(
  p_apple_place_id text,
  p_name           text,
  p_lat            double precision,
  p_lng            double precision,
  p_category       text default null,
  p_address        text default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid  uuid := auth.uid();
  v_id   uuid;
  v_key  text := public.search_key(p_name);
  v_here extensions.geography := extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography;
  v_imp  public.place_import;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_name is null or char_length(trim(p_name)) = 0 then raise exception 'name required'; end if;
  if p_lat not between -90 and 90 or p_lng not between -180 and 180 then raise exception 'bad coordinates'; end if;

  -- 1. already linked
  if p_apple_place_id is not null then
    select id into v_id from public.places where apple_place_id = p_apple_place_id;
    if v_id is not null then return v_id; end if;
  end if;

  -- 2. an existing place within 75 m with a similar name
  select p.id into v_id
  from public.places p
  where extensions.st_dwithin(p.location, v_here, 75)
    and extensions.similarity(p.name_key, v_key) > 0.45
  order by extensions.similarity(p.name_key, v_key) desc, extensions.st_distance(p.location, v_here)
  limit 1;
  if v_id is not null then
    if p_apple_place_id is not null then
      update public.places set apple_place_id = p_apple_place_id
      where id = v_id and apple_place_id is null;
    end if;
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
    insert into public.places (name, location, address, locality, region, postcode, country, primary_category,
                               phone, website, apple_place_id, fsq_place_id, overture_id, osm_id, source, created_by)
    values (v_imp.name, v_imp.location, v_imp.address, v_imp.locality, v_imp.region, v_imp.postcode,
            coalesce(v_imp.country, 'CA'), coalesce(v_imp.categories[1], p_category), v_imp.phone, v_imp.website,
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
  insert into public.places (name, location, address, primary_category, apple_place_id, source, created_by)
  values (left(trim(p_name), 120), v_here, p_address, p_category, p_apple_place_id, 'user', v_uid)
  returning id into v_id;
  return v_id;
end;
$$;

revoke execute on function public.resolve_place(text, text, double precision, double precision, text, text) from public, anon;
grant execute on function public.resolve_place(text, text, double precision, double precision, text, text) to authenticated;
