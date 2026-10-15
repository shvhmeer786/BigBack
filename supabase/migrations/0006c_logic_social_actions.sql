-- BigBack · 0006c · social actions: tagging, plans, Let's eat, Food Fights
-- (account deletion lives in the delete-account Edge Function via auth.admin.deleteUser)

create or replace function public.tag_friends(p_meal_id uuid, p_user_ids uuid[])
returns uuid  -- party id
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid  uuid := auth.uid();
  v_meal public.meals;
  v_party uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select * into v_meal from public.meals where id = p_meal_id and user_id = v_uid;
  if not found then raise exception 'meal not found'; end if;
  if coalesce(array_length(p_user_ids, 1), 0) > 20 then raise exception 'too many tags'; end if;

  v_party := v_meal.party_id;
  if v_party is null then
    insert into public.parties (place_id, host_id, plan_id) values (v_meal.place_id, v_uid, v_meal.plan_id)
    returning id into v_party;
    update public.meals set party_id = v_party where id = p_meal_id;
  end if;

  insert into public.party_members (party_id, user_id, status, invited_by)
  select v_party, u, 'pending', v_uid
  from unnest(p_user_ids) u
  where u <> v_uid
    and exists (select 1 from public.profiles p where p.id = u)
    and not public.is_blocked_between(v_uid, u)
  on conflict (party_id, user_id) do nothing;
  return v_party;
end;
$$;

-- Accept/decline a tag. Accepting creates your own meal at the same place (unrated, ready to rate).
create or replace function public.respond_party_invite(p_party_id uuid, p_accept boolean)
returns uuid  -- your meal id when accepted
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_party public.parties;
  v_meal uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select * into v_party from public.parties where id = p_party_id;
  if not found then raise exception 'party not found'; end if;
  if not exists (select 1 from public.party_members where party_id = p_party_id and user_id = v_uid) then
    raise exception 'not invited';
  end if;
  if not p_accept then
    update public.party_members set status = 'declined', responded_at = now()
    where party_id = p_party_id and user_id = v_uid;
    return null;
  end if;
  select id into v_meal from public.meals where party_id = p_party_id and user_id = v_uid;
  if v_meal is null then
    insert into public.meals (user_id, place_id, party_id, plan_id, status, started_at)
    values (v_uid, v_party.place_id, p_party_id, v_party.plan_id,
            case when exists (select 1 from public.meals where user_id = v_uid and status = 'live') then 'unrated'::public.meal_status else 'live'::public.meal_status end,
            v_party.created_at)
    returning id into v_meal;
  end if;
  update public.party_members set status = 'accepted', responded_at = now(), meal_id = v_meal
  where party_id = p_party_id and user_id = v_uid;
  return v_meal;
end;
$$;

-- Join someone's table by scanning their QR (join_code).
create or replace function public.join_party(p_join_code text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_party public.parties;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select * into v_party from public.parties where join_code = p_join_code and ended_at is null
    and created_at > now() - interval '12 hours';
  if not found then raise exception 'table not found or expired'; end if;
  if public.is_blocked_between(v_uid, v_party.host_id) then raise exception 'table not found or expired'; end if;
  insert into public.party_members (party_id, user_id, status, invited_by)
  values (v_party.id, v_uid, 'pending', v_party.host_id)
  on conflict (party_id, user_id) do nothing;
  return public.respond_party_invite(v_party.id, true);
end;
$$;

-- Create a plan ("Go here") and invite people in one call.
create or replace function public.create_plan(
  p_place_id uuid, p_starts_at timestamptz, p_invitee_ids uuid[] default '{}',
  p_crew_id uuid default null, p_note text default null, p_decide_session_id uuid default null)
returns public.plans
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_plan public.plans;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_crew_id is not null and not public.is_crew_member(p_crew_id, v_uid) then raise exception 'not in crew'; end if;
  insert into public.plans (host_id, place_id, starts_at, crew_id, note, decide_session_id)
  values (v_uid, p_place_id, p_starts_at, p_crew_id, p_note, p_decide_session_id)
  returning * into v_plan;

  insert into public.plan_guests (plan_id, user_id, rsvp, invited_by, responded_at)
  values (v_plan.id, v_uid, 'going', v_uid, now());

  insert into public.plan_guests (plan_id, user_id, rsvp, invited_by)
  select v_plan.id, u, 'invited', v_uid
  from (select unnest(coalesce(p_invitee_ids, '{}')) as u
        union
        select cm.user_id from public.crew_members cm where p_crew_id is not null and cm.crew_id = p_crew_id) x
  where u <> v_uid and not public.is_blocked_between(v_uid, u)
  on conflict (plan_id, user_id) do nothing;
  return v_plan;
end;
$$;

create or replace function public.rsvp(p_plan_id uuid, p_rsvp public.rsvp)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_rsvp = 'invited' then raise exception 'invalid rsvp'; end if;
  update public.plan_guests set rsvp = p_rsvp, responded_at = now()
  where plan_id = p_plan_id and user_id = v_uid;
  if not found then
    -- joining by invite link (anyone with the link may RSVP)
    if not exists (select 1 from public.plans where id = p_plan_id and status = 'planned') then
      raise exception 'plan not found';
    end if;
    insert into public.plan_guests (plan_id, user_id, rsvp, responded_at) values (p_plan_id, v_uid, p_rsvp, now());
  end if;
end;
$$;

-- Plan by invite code (for deep links) — returns the plan if the code is valid.
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
      and extensions.st_dwithin(p.location, v_here, least(greatest(v_radius, 200), 20000))
      and (v_budget is null or p.price_level is null or p.price_level <= v_budget)
      and (v_craving is null
           or public.search_key(v_craving) = any (select public.search_key(c) from unnest(p.cuisines || p.tags) c)
           or p.name_key like '%' || public.search_key(v_craving) || '%')
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

-- Swipe. Returns the matched place when everyone has liked the same place.
create or replace function public.decide_vote(p_session_id uuid, p_place_id uuid, p_liked boolean)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_part uuid;
  v_status public.decide_status;
  v_total int;
  v_likes int;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select status into v_status from public.decide_sessions where id = p_session_id for update;
  if v_status is null then raise exception 'session not found'; end if;
  if v_status <> 'open' then
    return (select matched_place_id from public.decide_sessions where id = p_session_id);
  end if;
  select id into v_part from public.decide_participants where session_id = p_session_id and user_id = v_uid;
  if v_part is null then
    -- anyone with the invite who is signed in can join
    insert into public.decide_participants (session_id, user_id) values (p_session_id, v_uid) returning id into v_part;
  end if;
  if not exists (select 1 from public.decide_candidates where session_id = p_session_id and place_id = p_place_id) then
    raise exception 'not a candidate';
  end if;
  insert into public.decide_votes (session_id, place_id, participant_id, liked)
  values (p_session_id, p_place_id, v_part, p_liked)
  on conflict (session_id, place_id, participant_id) do update set liked = excluded.liked, created_at = now();

  select count(*) into v_total from public.decide_participants where session_id = p_session_id;
  select count(*) into v_likes from public.decide_votes
  where session_id = p_session_id and place_id = p_place_id and liked;
  if v_likes >= v_total then
    update public.decide_sessions
    set status = 'matched', matched_place_id = p_place_id, decided_at = now()
    where id = p_session_id;
    return p_place_id;
  end if;
  return null;
end;
$$;

-- Host ends the swiping: most likes wins (ties -> higher group score).
create or replace function public.decide_finalize(p_session_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_place uuid;
begin
  if not exists (select 1 from public.decide_sessions where id = p_session_id and host_id = v_uid) then
    raise exception 'only the host can decide';
  end if;
  select c.place_id into v_place
  from public.decide_candidates c
  left join public.decide_votes v on v.session_id = c.session_id and v.place_id = c.place_id and v.liked
  where c.session_id = p_session_id
  group by c.place_id, c.group_score, c.position
  order by count(v.participant_id) desc, c.group_score desc nulls last, c.position
  limit 1;
  update public.decide_sessions set status = 'matched', matched_place_id = v_place, decided_at = now()
  where id = p_session_id and status = 'open';
  return (select matched_place_id from public.decide_sessions where id = p_session_id);
end;
$$;

-- Food Fight vote — only for people with a posted meal at both places.
create or replace function public.fight_vote(p_matchup_id uuid, p_winner uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_m public.fight_matchups;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select * into v_m from public.fight_matchups where id = p_matchup_id;
  if not found then raise exception 'matchup not found'; end if;
  if now() < v_m.opens_at or now() >= v_m.closes_at then raise exception 'voting is closed'; end if;
  if p_winner not in (v_m.place_a, v_m.place_b) then raise exception 'winner must be one of the two places'; end if;
  if (select count(distinct place_id) from public.meals
      where user_id = v_uid and status = 'posted' and place_id in (v_m.place_a, v_m.place_b)) < 2 then
    raise exception 'you need a meal at both places to vote';
  end if;
  insert into public.fight_votes (matchup_id, user_id, winner_place_id) values (p_matchup_id, v_uid, p_winner)
  on conflict (matchup_id, user_id) do update set winner_place_id = excluded.winner_place_id, created_at = now();
end;
$$;

-- App Store 5.1.1(v): in-app account deletion. Storage objects are removed by the
-- delete-account Edge Function (it calls this after deleting the user's files).
