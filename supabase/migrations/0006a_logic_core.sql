-- BigBack · 0006a · business logic part 1: guard triggers, ranking engine, reads (feed / place scores /
-- Tonight picks / search), social actions (tag, plans, Let's eat), notifications, account deletion.
--
-- Conventions
--   * Client-callable RPCs check auth.uid() themselves and are SECURITY DEFINER only when they must
--     write rows the caller cannot write directly (rankings, party members, decide votes).
--   * Internal helpers start with "_" and have EXECUTE revoked from anon/authenticated.
--   * search_path is pinned on every function.

-- ===========================================================================
-- 1. GUARD TRIGGERS (system-owned columns; table-level UPDATE grants make column REVOKE useless)
-- ===========================================================================
create or replace function public._is_client()
returns boolean
language sql
stable
set search_path = ''
as $$
  -- true when the statement runs as an API role (not inside a SECURITY DEFINER function / service role)
  select current_user in ('authenticated', 'anon');
$$;

create or replace function public._guard_profiles()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if public._is_client() then
    new.school_id  := old.school_id;
    new.created_at := old.created_at;
  end if;
  return new;
end;
$$;
create trigger profiles_guard before update on public.profiles
  for each row execute function public._guard_profiles();

create or replace function public._guard_meals()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if public._is_client() then
    if new.user_id <> old.user_id then
      raise exception 'meal owner cannot change';
    end if;
    -- rating fields are owned by submit_rating() / rerate_visit()
    new.tier          := old.tier;
    new.score_at_post := old.score_at_post;
    new.posted_at     := old.posted_at;
    new.visit_delta   := old.visit_delta;
    if new.status = 'posted' and old.status <> 'posted' then
      raise exception 'use submit_rating() to post a meal';
    end if;
    if old.status = 'posted' and new.status in ('live', 'unrated') then
      raise exception 'a posted meal cannot go back to live/unrated';
    end if;
    if old.status = 'posted' and new.place_id <> old.place_id then
      raise exception 'place of a posted meal cannot change';
    end if;
    if new.vibe is distinct from old.vibe and old.status = 'posted' then
      raise exception 'use move_ranking() to change the vibe of a ranked place';
    end if;
  end if;
  if new.status in ('unrated', 'posted', 'archived') and new.ended_at is null then
    new.ended_at := now();
  end if;
  return new;
end;
$$;
create trigger meals_guard before update on public.meals
  for each row execute function public._guard_meals();

create or replace function public._guard_immutable_parent()
returns trigger
language plpgsql
set search_path = ''
as $$
-- TG_ARGV[0] = column that must never change on UPDATE from a client (e.g. meal_id, plan_id)
declare
  v_old text := to_jsonb(old) ->> tg_argv[0];
  v_new text := to_jsonb(new) ->> tg_argv[0];
begin
  if public._is_client() and v_old is distinct from v_new then
    raise exception '% cannot change', tg_argv[0];
  end if;
  if public._is_client() and (to_jsonb(old) ? 'user_id') and (to_jsonb(old) ->> 'user_id') is distinct from (to_jsonb(new) ->> 'user_id') then
    raise exception 'user_id cannot change';
  end if;
  return new;
end;
$$;
create trigger meal_media_guard before update on public.meal_media
  for each row execute function public._guard_immutable_parent('meal_id');
create trigger plan_guests_guard before update on public.plan_guests
  for each row execute function public._guard_immutable_parent('plan_id');
create trigger party_members_guard before update on public.party_members
  for each row execute function public._guard_immutable_parent('party_id');
create trigger reactions_guard before update on public.reactions
  for each row execute function public._guard_immutable_parent('meal_id');
create trigger comments_guard before update on public.comments
  for each row execute function public._guard_immutable_parent('meal_id');
create trigger dish_ratings_guard before update on public.dish_ratings
  for each row execute function public._guard_immutable_parent('meal_id');
create trigger saves_guard before update on public.saves
  for each row execute function public._guard_immutable_parent('place_id');

-- Follows: private accounts turn follows into requests; accepted_at bookkeeping.
create or replace function public._follows_before()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if exists (select 1 from public.profiles p where p.id = new.followee_id and p.is_private) then
      new.status := 'requested';
      new.accepted_at := null;
    else
      new.status := 'accepted';
      new.accepted_at := now();
    end if;
  elsif tg_op = 'UPDATE' then
    if new.follower_id <> old.follower_id or new.followee_id <> old.followee_id then
      raise exception 'follow endpoints cannot change';
    end if;
    if new.status = 'accepted' and old.status <> 'accepted' then
      new.accepted_at := now();
    end if;
  end if;
  return new;
end;
$$;
create trigger follows_before before insert or update on public.follows
  for each row execute function public._follows_before();

-- Blocking someone removes follows both ways.
create or replace function public._blocks_after()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.follows
  where (follower_id = new.blocker_id and followee_id = new.blocked_id)
     or (follower_id = new.blocked_id and followee_id = new.blocker_id);
  return new;
end;
$$;
create trigger blocks_after after insert on public.blocks
  for each row execute function public._blocks_after();

-- Crew owner is always a member.
create or replace function public._crews_after()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.crew_members (crew_id, user_id, role)
  values (new.id, new.owner_id, 'owner')
  on conflict (crew_id, user_id) do update set role = 'owner';
  return new;
end;
$$;
create trigger crews_after after insert on public.crews
  for each row execute function public._crews_after();

-- ===========================================================================
-- 2. RANKING ENGINE
--    One ordered list per (user, tier). The client fetches its tier list, runs binary insertion
--    against SAME-VIBE places only (max 3 This-or-That swipes), then sends the final index.
-- ===========================================================================
create or replace function public._recompute_tier_scores(p_user uuid, p_tier public.tier)
returns void
language sql
set search_path = ''
as $$
  update public.rankings r
  set score = public.tier_score(p_tier, r.position, n.cnt),
      updated_at = now()
  from (select count(*)::int as cnt from public.rankings where user_id = p_user and tier = p_tier) n
  where r.user_id = p_user and r.tier = p_tier;
$$;

create or replace function public._remove_ranking(p_user uuid, p_place uuid)
returns public.tier
language plpgsql
set search_path = ''
as $$
declare
  v_tier public.tier;
  v_pos  int;
begin
  delete from public.rankings
  where user_id = p_user and place_id = p_place
  returning tier, position into v_tier, v_pos;
  if v_tier is not null then
    update public.rankings set position = position - 1
    where user_id = p_user and tier = v_tier and position > v_pos;
    perform public._recompute_tier_scores(p_user, v_tier);
  end if;
  return v_tier;
end;
$$;

create or replace function public._insert_ranking(
  p_user uuid, p_place uuid, p_tier public.tier, p_vibe public.vibe,
  p_position int, p_settled boolean, p_meal uuid, p_visits int default 1)
returns numeric
language plpgsql
set search_path = ''
as $$
declare
  v_n   int;
  v_pos int;
  v_score numeric;
begin
  select count(*) into v_n from public.rankings where user_id = p_user and tier = p_tier;
  v_pos := least(greatest(coalesce(p_position, v_n), 0), v_n);
  update public.rankings set position = position + 1
  where user_id = p_user and tier = p_tier and position >= v_pos;
  insert into public.rankings (user_id, place_id, tier, vibe, position, settled, last_meal_id, visits)
  values (p_user, p_place, p_tier, p_vibe, v_pos, coalesce(p_settled, true), p_meal, greatest(p_visits, 1));
  perform public._recompute_tier_scores(p_user, p_tier);
  select score into v_score from public.rankings where user_id = p_user and place_id = p_place;
  return v_score;
end;
$$;

-- Rate a meal: reaction tier + vibe + final position (from client-side binary insertion)
-- + the comparisons the user made. Posts the meal and returns the new score/rank.
-- p_comparisons: [{"winner": uuid, "loser": uuid, "tie": bool}, ...]
create or replace function public.submit_rating(
  p_meal_id     uuid,
  p_tier        public.tier,
  p_vibe        public.vibe,
  p_position    int,
  p_settled     boolean default true,
  p_comparisons jsonb default '[]'::jsonb)
returns table (score numeric, tier_position int, tier_count int, vibe_rank int)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid();
  v_meal   public.meals;
  v_old    public.rankings;
  v_score  numeric;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select * into v_meal from public.meals where id = p_meal_id and user_id = v_uid for update;
  if not found then raise exception 'meal not found'; end if;
  if v_meal.status not in ('live', 'unrated') then raise exception 'meal already rated'; end if;
  if jsonb_typeof(coalesce(p_comparisons, '[]'::jsonb)) <> 'array' or jsonb_array_length(p_comparisons) > 10 then
    raise exception 'comparisons must be an array of at most 10 items';
  end if;

  select * into v_old from public.rankings where user_id = v_uid and place_id = v_meal.place_id;
  perform public._remove_ranking(v_uid, v_meal.place_id);
  v_score := public._insert_ranking(v_uid, v_meal.place_id, p_tier, p_vibe, p_position, p_settled,
                                    p_meal_id, coalesce(v_old.visits, 0) + 1);

  insert into public.comparisons (user_id, winner_place_id, loser_place_id, is_tie, source, meal_id)
  select v_uid, (c ->> 'winner')::uuid, (c ->> 'loser')::uuid, coalesce((c ->> 'tie')::boolean, false), 'rate', p_meal_id
  from jsonb_array_elements(coalesce(p_comparisons, '[]'::jsonb)) c
  where (c ->> 'winner') is not null and (c ->> 'loser') is not null and (c ->> 'winner') <> (c ->> 'loser');

  update public.meals
  set tier = p_tier, vibe = p_vibe, score_at_post = v_score,
      status = 'posted', posted_at = now(), ended_at = coalesce(ended_at, now())
  where id = p_meal_id;

  return query
  select r.score, r.position, (select count(*)::int from public.rankings x where x.user_id = v_uid and x.tier = r.tier),
         (select count(*)::int + 1 from public.rankings y
           where y.user_id = v_uid and y.vibe = r.vibe and y.score > r.score)
  from public.rankings r where r.user_id = v_uid and r.place_id = v_meal.place_id;
end;
$$;

-- Repeat visit: one tap instead of a full re-rank. better/worse moves the place one step past
-- its nearest same-vibe neighbour inside the tier; same keeps it. Posts the meal.
create or replace function public.rerate_visit(p_meal_id uuid, p_direction text)
returns table (score numeric, tier_position int)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid  uuid := auth.uid();
  v_meal public.meals;
  v_r    public.rankings;
  v_target int;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_direction not in ('better', 'same', 'worse') then raise exception 'direction must be better|same|worse'; end if;
  select * into v_meal from public.meals where id = p_meal_id and user_id = v_uid for update;
  if not found then raise exception 'meal not found'; end if;
  if v_meal.status not in ('live', 'unrated') then raise exception 'meal already rated'; end if;
  select * into v_r from public.rankings where user_id = v_uid and place_id = v_meal.place_id;
  if not found then raise exception 'place not ranked yet: use submit_rating'; end if;

  v_target := v_r.position;
  if p_direction = 'better' then
    select max(position) into v_target from public.rankings
    where user_id = v_uid and tier = v_r.tier and vibe = v_r.vibe and position < v_r.position;
    v_target := coalesce(v_target, v_r.position);
  elsif p_direction = 'worse' then
    select min(position) into v_target from public.rankings
    where user_id = v_uid and tier = v_r.tier and vibe = v_r.vibe and position > v_r.position;
    v_target := coalesce(v_target, v_r.position);
  end if;

  if v_target <> v_r.position then
    perform public._remove_ranking(v_uid, v_r.place_id);
    perform public._insert_ranking(v_uid, v_r.place_id, v_r.tier, v_r.vibe, v_target, true, p_meal_id, v_r.visits + 1);
  else
    update public.rankings set visits = visits + 1, last_meal_id = p_meal_id, updated_at = now()
    where user_id = v_uid and place_id = v_r.place_id;
  end if;

  update public.meals m
  set tier = v_r.tier, vibe = v_r.vibe, visit_delta = p_direction, status = 'posted', posted_at = now(),
      score_at_post = (select r.score from public.rankings r where r.user_id = v_uid and r.place_id = v_r.place_id)
  where m.id = p_meal_id;

  return query select r.score, r.position from public.rankings r where r.user_id = v_uid and r.place_id = v_r.place_id;
end;
$$;

-- Drag-to-reorder in the user's list, optionally across tiers or vibes.
create or replace function public.move_ranking(
  p_place_id uuid, p_tier public.tier, p_position int, p_vibe public.vibe default null)
returns numeric
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_r   public.rankings;
  v_score numeric;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select * into v_r from public.rankings where user_id = v_uid and place_id = p_place_id;
  if not found then raise exception 'place not ranked'; end if;
  perform public._remove_ranking(v_uid, p_place_id);
  v_score := public._insert_ranking(v_uid, p_place_id, p_tier, coalesce(p_vibe, v_r.vibe), p_position, true,
                                    v_r.last_meal_id, v_r.visits);
  return v_score;
end;
$$;

-- Settle it / Defend your #1: record one extra comparison; if the result contradicts the current
-- order (same tier), swap them.
create or replace function public.record_comparison(
  p_winner uuid, p_loser uuid, p_source public.comparison_source default 'settle', p_tie boolean default false)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_w public.rankings;
  v_l public.rankings;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_source not in ('settle', 'defend') then raise exception 'source must be settle or defend'; end if;
  insert into public.comparisons (user_id, winner_place_id, loser_place_id, is_tie, source)
  values (v_uid, p_winner, p_loser, p_tie, p_source);
  if p_tie then return; end if;
  select * into v_w from public.rankings where user_id = v_uid and place_id = p_winner;
  select * into v_l from public.rankings where user_id = v_uid and place_id = p_loser;
  if v_w.place_id is null or v_l.place_id is null or v_w.tier <> v_l.tier then return; end if;
  if v_w.position > v_l.position then
    update public.rankings set position = case place_id when p_winner then v_l.position else v_w.position end,
                               settled = true
    where user_id = v_uid and place_id in (p_winner, p_loser);
    perform public._recompute_tier_scores(v_uid, v_w.tier);
  else
    update public.rankings set settled = true where user_id = v_uid and place_id = p_winner;
  end if;
end;
$$;

-- ===========================================================================
-- 3. READS
-- ===========================================================================

-- Home feed: posted meals from people you follow (+ your own), newest first. Keyset pagination.
-- Returns meals rows so PostgREST can embed: .rpc('get_feed').select('*, place:places(*), author:profiles(*), media:meal_media(*)')
create or replace function public.get_feed(p_before timestamptz default null, p_limit int default 20)
returns setof public.meals
language sql
stable
set search_path = ''
as $$
  select m.*
  from public.meals m
  where m.status = 'posted'
    and m.visibility = 'followers'
    and m.posted_at < coalesce(p_before, 'infinity'::timestamptz)
    and (
      m.user_id = (select auth.uid())
      or exists (select 1 from public.follows f
                 where f.follower_id = (select auth.uid()) and f.followee_id = m.user_id and f.status = 'accepted')
    )
    and not public.is_blocked_between((select auth.uid()), m.user_id)
  order by m.posted_at desc
  limit least(greatest(coalesce(p_limit, 20), 1), 50);
$$;

-- Posted meals at one place that the viewer may see (place page).
create or replace function public.get_place_meals(p_place_id uuid, p_before timestamptz default null, p_limit int default 20)
returns setof public.meals
language sql
stable
set search_path = ''
as $$
  select m.* from public.meals m
  where m.place_id = p_place_id and m.status = 'posted'
    and m.posted_at < coalesce(p_before, 'infinity'::timestamptz)
    and public.can_view_meal(m.id)
  order by (exists (select 1 from public.follows f where f.follower_id = (select auth.uid())
                    and f.followee_id = m.user_id and f.status = 'accepted')) desc,
           m.posted_at desc
  limit least(greatest(coalesce(p_limit, 20), 1), 50);
$$;

-- Is the place open at a given time (local time of the place's city)? null = unknown hours.
create or replace function public.is_open_at(p_place_id uuid, p_at timestamptz default now(), p_tz text default 'America/Toronto')
returns boolean
language sql
stable
set search_path = ''
as $$
  with t as (
    select (p_at at time zone p_tz) as local_ts
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

-- Predicted score for a user: similarity-weighted average of others' scores, shrunk toward the
-- campus Bayesian score (or 7.0 when unknown). k = 2 pseudo-ratings of prior.
create or replace function public.predicted_score(p_place_id uuid, p_user uuid default auth.uid())
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  with prior as (
    select coalesce(
      (select ps.bayes_score from public.place_stats ps
        join public.profiles pr on pr.school_id = ps.school_id
        where pr.id = p_user and ps.place_id = p_place_id),
      7.0) as m
  ), w as (
    select r.score,
           coalesce(greatest(s.corr, 0) + 0.1, 0.1) as wt
    from public.rankings r
    left join public.user_similarity s on s.user_a = p_user and s.user_b = r.user_id
    where r.place_id = p_place_id and r.user_id <> p_user
  )
  select round(((select coalesce(sum(wt * score), 0) from w) + 2 * (select m from prior))
               / ((select coalesce(sum(wt), 0) from w) + 2), 1);
$$;

-- Everything the place page needs in one call.
create or replace function public.get_place_scores(p_place_id uuid)
returns table (
  my_score numeric, my_tier public.tier, my_vibe public.vibe,
  following_avg numeric, following_count int,
  campus_score numeric, campus_count int,
  predicted numeric,
  saved boolean, friends_saved int,
  open_now boolean)
language sql
stable
security definer
set search_path = ''
as $$
  with me as (select auth.uid() as uid),
  mine as (select r.score, r.tier, r.vibe from public.rankings r, me where r.user_id = me.uid and r.place_id = p_place_id),
  fol as (
    select r.score from public.rankings r
    join public.follows f on f.followee_id = r.user_id and f.status = 'accepted'
    join me on f.follower_id = me.uid
    where r.place_id = p_place_id
  ),
  camp as (
    select ps.bayes_score, ps.n_ratings from public.place_stats ps
    join public.profiles pr on pr.school_id = ps.school_id
    join me on pr.id = me.uid
    where ps.place_id = p_place_id
  )
  select
    (select score from mine), (select tier from mine), (select vibe from mine),
    (select round(avg(score), 1) from fol), (select count(*)::int from fol),
    (select bayes_score from camp), coalesce((select n_ratings from camp), 0),
    public.predicted_score(p_place_id, (select uid from me)),
    exists (select 1 from public.saves s, me where s.user_id = me.uid and s.place_id = p_place_id),
    (select count(*)::int from public.saves s
       join public.follows f on f.followee_id = s.user_id and f.status = 'accepted'
       join me on f.follower_id = me.uid
       where s.place_id = p_place_id),
    public.is_open_at(p_place_id);
$$;

-- Fuzzy place search near a point (our places table; MapKit search runs on-device too).
create or replace function public.search_places(
  p_query text, p_lat double precision default null, p_lng double precision default null, p_limit int default 20)
returns table (place_id uuid, name text, address text, distance_m double precision, similarity real)
language sql
stable
set search_path = ''
as $$
  select p.id, p.name, p.address,
         case when p_lat is null then null
              else extensions.st_distance(p.location, extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography) end,
         extensions.similarity(p.name_key, public.search_key(p_query))
  from public.places p
  where not p.is_permanently_closed
    and (p.name_key operator(extensions.%) public.search_key(p_query) or p.name_key like '%' || public.search_key(p_query) || '%')
  order by extensions.similarity(p.name_key, public.search_key(p_query)) desc,
           case when p_lat is null then 0
                else extensions.st_distance(p.location, extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography) end
  limit least(greatest(coalesce(p_limit, 20), 1), 50);
$$;

-- Places within a radius (map viewport / nearby list).
create or replace function public.nearby_places(
  p_lat double precision, p_lng double precision, p_radius_m int default 2000, p_limit int default 100)
returns table (place_id uuid, distance_m double precision)
language sql
stable
set search_path = ''
as $$
  select p.id,
         extensions.st_distance(p.location, extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography)
  from public.places p
  where not p.is_permanently_closed
    and extensions.st_dwithin(p.location, extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography,
                              least(greatest(p_radius_m, 100), 20000))
  order by 2
  limit least(greatest(coalesce(p_limit, 100), 1), 300);
$$;

-- Tonight: ranked picks for right now, each with the data for a one-line reason.
-- p_craving matches cuisines, tags, category or name. p_novelty 0 = old faithful, 1 = somewhere new.
create or replace function public.tonight_picks(
  p_lat double precision, p_lng double precision,
  p_craving text default null, p_vibe public.vibe default null,
  p_max_price smallint default null, p_radius_m int default 3000,
  p_novelty real default 0.5, p_limit int default 20)
returns table (
  place_id uuid, name text, distance_m double precision, walk_minutes int,
  predicted numeric, open_now boolean, saved boolean, been boolean,
  follow_loved int, top_friend_handle text, top_friend_score numeric, campus_score numeric,
  rank_score numeric)
language sql
stable
security definer
set search_path = ''
as $$
  with me as (
    select auth.uid() as uid,
           extensions.st_setsrid(extensions.st_makepoint(p_lng, p_lat), 4326)::extensions.geography as here
  ),
  cand as (
    select p.id, p.name, extensions.st_distance(p.location, me.here) as dist
    from public.places p, me
    where not p.is_permanently_closed
      and extensions.st_dwithin(p.location, me.here, least(greatest(p_radius_m, 200), 20000))
      and (p_max_price is null or p.price_level is null or p.price_level <= p_max_price)
      and (p_craving is null
           or public.search_key(p_craving) = any (select public.search_key(c) from unnest(p.cuisines || p.tags) c)
           or public.search_key(p.primary_category) = public.search_key(p_craving)
           or p.name_key like '%' || public.search_key(p_craving) || '%')
  ),
  fol as (
    select r.place_id, r.score, pr.handle::text as handle,
           row_number() over (partition by r.place_id order by r.updated_at desc, r.score desc) as rn
    from public.rankings r
    join public.follows f on f.followee_id = r.user_id and f.status = 'accepted'
    join me on f.follower_id = me.uid
    join public.profiles pr on pr.id = r.user_id
    where r.place_id in (select id from cand)
      and (p_vibe is null or r.vibe = p_vibe)
  ),
  scored as (
    select c.id, c.name, c.dist,
           public.predicted_score(c.id, (select uid from me)) as pred,
           public.is_open_at(c.id) as open_now,
           exists (select 1 from public.saves s, me where s.user_id = me.uid and s.place_id = c.id) as saved,
           exists (select 1 from public.rankings r, me where r.user_id = me.uid and r.place_id = c.id) as been,
           (select count(*)::int from fol where fol.place_id = c.id and fol.score >= 8.0) as loved,
           (select handle from fol where fol.place_id = c.id and fol.rn = 1) as top_handle,
           (select score from fol where fol.place_id = c.id and fol.rn = 1) as top_score,
           (select ps.bayes_score from public.place_stats ps
              join public.profiles pr on pr.school_id = ps.school_id, me
              where pr.id = me.uid and ps.place_id = c.id) as campus
    from cand c
  )
  select id, name, dist, greatest(1, round(dist / 80.0))::int,  -- ~80 m per walking minute
         pred, open_now, saved, been, loved, top_handle, top_score, campus,
         round((
             pred
           + 0.35 * least(loved, 4)
           + case when saved then 0.8 else 0 end
           + case when been then (0.5 - p_novelty) * 1.2 else (p_novelty - 0.5) * 1.2 end
           - least(dist / 1000.0, 3) * 0.4
           - case when open_now is false then 5 else 0 end
         )::numeric, 2) as rank_score
  from scored
  order by rank_score desc
  limit least(greatest(coalesce(p_limit, 20), 1), 50);
$$;

-- Weekly streak: consecutive ISO weeks (ending this week or last) with a posted meal at a NEW place.
create or replace function public.user_streak(p_user uuid default auth.uid())
returns int
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_week date := date_trunc('week', now())::date;
  v_streak int := 0;
  v_weeks date[];
begin
  if not public.can_view_user_content(p_user) then return null; end if;
  select array_agg(distinct date_trunc('week', first_post)::date order by date_trunc('week', first_post)::date desc)
  into v_weeks
  from (select min(posted_at) as first_post from public.meals
        where user_id = p_user and status = 'posted' group by place_id) f;
  if v_weeks is null then return 0; end if;
  if not (v_week = any (v_weeks)) then v_week := v_week - 7; end if;  -- this week not done yet
  while v_week = any (v_weeks) loop
    v_streak := v_streak + 1;
    v_week := v_week - 7;
  end loop;
  return v_streak;
end;
$$;

-- Campus leaderboard for a season: most new places ranked.
create or replace function public.leaderboard(p_season_id uuid, p_limit int default 50)
returns table (user_id uuid, handle text, display_name text, places int, rank int)
language sql
stable
security definer
set search_path = ''
as $$
  with s as (select * from public.seasons where id = p_season_id),
  counts as (
    select m.user_id, count(distinct m.place_id)::int as places
    from public.meals m, s
    join public.profiles pr on pr.school_id = s.school_id
    where m.user_id = pr.id and m.status = 'posted'
      and m.posted_at >= s.starts_on and m.posted_at < s.ends_on + 1
      and not pr.is_private
    group by m.user_id
  )
  select c.user_id, p.handle::text, p.display_name, c.places,
         (rank() over (order by c.places desc))::int
  from counts c join public.profiles p on p.id = c.user_id
  where not public.is_blocked_between(auth.uid(), c.user_id)
  order by c.places desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200);
$$;

-- Taste match % between the viewer and another user (null until 5 shared places).
create or replace function public.taste_match(p_other uuid)
returns table (match_pct int, shared int)
language sql
stable
security definer
set search_path = ''
as $$
  select case when s.n_shared >= 5 then round((s.corr + 1) * 50)::int end, s.n_shared
  from public.user_similarity s
  where s.user_a = auth.uid() and s.user_b = p_other and public.can_view_user_content(p_other);
$$;

