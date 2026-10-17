-- BigBack · Restaurants come from the map, not from manual entry.
-- The app searches Apple Maps (MapKit) on the phone, anywhere in the world, for free. Our database only stores
-- a place once someone interacts with it (rates, saves, plans), keyed by its Apple Place ID. These two changes
-- let the app's map results carry BigBack signals without first copying every restaurant into the database.

-- 1. Signals for a list of MapKit results: your score, friends who went, campus score, saved, open now.
--    Apple IDs we've never seen come back with place_id = null (no BigBack data yet).
create or replace function public.place_signals(p_apple_ids text[])
returns table (
  apple_place_id text, place_id uuid, predicted numeric, my_score numeric, saved boolean,
  follow_count int, follow_loved int, top_friend_handle text, top_friend_score numeric,
  campus_score numeric, open_now boolean)
language sql
stable
security definer
set search_path = ''
as $$
  with ids as (
    select distinct a from unnest(p_apple_ids[1:100]) a where a is not null
  ),
  pl as (
    select ids.a, p.id from ids left join public.places p on p.apple_place_id = ids.a
  ),
  fol as (
    select r.place_id, r.score, pr.handle::text as handle,
           row_number() over (partition by r.place_id order by r.updated_at desc, r.score desc) as rn
    from public.rankings r
    join public.follows f on f.followee_id = r.user_id and f.status = 'accepted' and f.follower_id = (select auth.uid())
    join public.profiles pr on pr.id = r.user_id
    where r.place_id in (select id from pl where id is not null)
  )
  select pl.a, pl.id,
         case when pl.id is not null then public.predicted_score(pl.id, (select auth.uid())) end,
         (select r.score from public.rankings r where r.user_id = (select auth.uid()) and r.place_id = pl.id),
         exists (select 1 from public.saves s where s.user_id = (select auth.uid()) and s.place_id = pl.id),
         (select count(*)::int from fol where fol.place_id = pl.id),
         (select count(*)::int from fol where fol.place_id = pl.id and fol.score >= 8.0),
         (select fol.handle from fol where fol.place_id = pl.id and fol.rn = 1),
         (select fol.score from fol where fol.place_id = pl.id and fol.rn = 1),
         (select ps.bayes_score from public.place_stats ps
            join public.profiles me on me.school_id = ps.school_id
            where me.id = (select auth.uid()) and ps.place_id = pl.id),
         case when pl.id is not null then public.is_open_at(pl.id) end
  from pl
  where (select auth.uid()) is not null;
$$;

revoke execute on function public.place_signals(text[]) from public, anon;
grant execute on function public.place_signals(text[]) to authenticated;

-- 2. "Let's eat" can deal from the map: constraints.place_ids (up to 30) are always candidates,
--    alongside any nearby places already in the database.
create or replace function public.create_decide_session(
  p_member_ids uuid[], p_lat double precision, p_lng double precision,
  p_crew_id uuid default null, p_constraints jsonb default '{}'::jsonb, p_size int default 8)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_session uuid;
  v_members uuid[];
  v_radius int := coalesce((p_constraints ->> 'radius_m')::int, 3000);
  v_budget smallint := (p_constraints ->> 'max_price')::smallint;
  v_craving text := p_constraints ->> 'craving';
  -- Places the app already found on the map (MapKit results passed through resolve_place).
  v_ids uuid[] := coalesce((select array_agg(x::uuid)
                            from (select jsonb_array_elements_text(coalesce(p_constraints -> 'place_ids', '[]'::jsonb)) x
                                  limit 30) t), '{}');
  v_here extensions.geography := extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select array_agg(distinct u) into v_members
  from (select unnest(coalesce(p_member_ids, '{}')) u
        union select v_uid
        union select cm.user_id from public.crew_members cm where p_crew_id is not null and cm.crew_id = p_crew_id) x
  where not public.is_blocked_between(v_uid, u);
  if array_length(v_members, 1) > 12 then raise exception 'max 12 people'; end if;

  insert into public.decide_sessions (host_id, crew_id, constraints, center)
  values (v_uid, p_crew_id, coalesce(p_constraints, '{}'::jsonb), v_here)
  returning id into v_session;

  insert into public.decide_participants (session_id, user_id)
  select v_session, u from unnest(v_members) u;

  insert into public.decide_candidates (session_id, place_id, position, group_score, reason)
  select v_session, s.id, (row_number() over (order by s.gscore desc))::int - 1, round(s.gscore, 1), s.reason
  from (
    select p.id,
           avg(public.predicted_score(p.id, m.u)) as gscore,
           min(public.predicted_score(p.id, m.u)) as worst,
           count(sv.user_id) as saved_by,
           case when count(sv.user_id) >= 2 then 'On ' || count(sv.user_id) || ' of your Want-to-Try lists'
                when count(sv.user_id) = 1 then 'On a Want-to-Try list'
                else null end as reason
    from public.places p
    cross join unnest(v_members) m(u)
    left join public.saves sv on sv.place_id = p.id and sv.user_id = m.u
    where not p.is_permanently_closed
      and (p.id = any (v_ids)
           or (extensions.st_dwithin(p.location, v_here, least(greatest(v_radius, 200), 20000))
               and (v_budget is null or p.price_level is null or p.price_level <= v_budget)
               and (v_craving is null
                    or public.search_key(v_craving) = any (select public.search_key(c) from unnest(p.cuisines || p.tags) c)
                    or p.name_key like '%' || public.search_key(v_craving) || '%')))
      and coalesce(public.is_open_at(p.id, coalesce((p_constraints ->> 'starts_at')::timestamptz, now())), true)
      and not exists (select 1 from public.rankings r
                      where r.place_id = p.id and r.user_id = any (v_members) and r.tier = 'nah')
    group by p.id
    having min(public.predicted_score(p.id, m.u)) >= 5.0
    order by avg(public.predicted_score(p.id, m.u)) + 0.4 * count(sv.user_id) desc
    limit least(greatest(coalesce(p_size, 8), 3), 15)
  ) s;
  return v_session;
end;
$$;
