-- BigBack · 0012 · Fixes from the Supabase security and performance advisors.

-- 1. Follow/block helpers answer only about the caller.
-- They are SECURITY DEFINER (RLS policies need them to see past the blocks/follows policies), so as
-- RPCs they let any signed-in user ask "does X follow Y?" or "did X block Y?" about strangers.
-- Every policy and internal caller passes the current user as one side (checked on 2026-10-15);
-- system jobs run without a user and keep the full answer. Anything else gets NULL, which every
-- caller treats as "not allowed" (policies and _notify fail closed).
create or replace function public.is_blocked_between(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when a is null or b is null then false
    when (select auth.uid()) is null or (select auth.uid()) in (a, b) then exists (
      select 1 from public.blocks
      where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a))
  end;
$$;

create or replace function public.is_following(p_follower uuid, p_followee uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_follower is null or p_followee is null then false
    when (select auth.uid()) is null or (select auth.uid()) in (p_follower, p_followee) then exists (
      select 1 from public.follows
      where follower_id = p_follower and followee_id = p_followee and status = 'accepted')
  end;
$$;

-- 2. Signed-out callers never need the visibility helpers (every policy that uses them is for
-- `authenticated`). Signed-in users keep EXECUTE because RLS policies call them as that role.
revoke execute on function public.can_view_meal(uuid) from public, anon;
revoke execute on function public.can_view_plan(uuid) from public, anon;
revoke execute on function public.can_view_user_content(uuid) from public, anon;
revoke execute on function public.is_blocked_between(uuid, uuid) from public, anon;
revoke execute on function public.is_following(uuid, uuid) from public, anon;
revoke execute on function public.is_crew_member(uuid, uuid) from public, anon;
revoke execute on function public.is_party_member(uuid, uuid) from public, anon;
revoke execute on function public.is_decide_participant(uuid, uuid) from public, anon;
grant execute on function public.can_view_meal(uuid) to authenticated, service_role;
grant execute on function public.can_view_plan(uuid) to authenticated, service_role;
grant execute on function public.can_view_user_content(uuid) to authenticated, service_role;
grant execute on function public.is_blocked_between(uuid, uuid) to authenticated, service_role;
grant execute on function public.is_following(uuid, uuid) to authenticated, service_role;
grant execute on function public.is_crew_member(uuid, uuid) to authenticated, service_role;
grant execute on function public.is_party_member(uuid, uuid) to authenticated, service_role;
grant execute on function public.is_decide_participant(uuid, uuid) to authenticated, service_role;

-- 3. Trigger functions are fired by Postgres, never called through the API.
revoke execute on function public._blocks_after() from public, anon, authenticated;
revoke execute on function public._crews_after() from public, anon, authenticated;
revoke execute on function public._follows_before() from public, anon, authenticated;
revoke execute on function public._notify_comment() from public, anon, authenticated;
revoke execute on function public._notify_decide_match() from public, anon, authenticated;
revoke execute on function public._notify_follows() from public, anon, authenticated;
revoke execute on function public._notify_meal_posted() from public, anon, authenticated;
revoke execute on function public._notify_party_member() from public, anon, authenticated;
revoke execute on function public._notify_plan_guest() from public, anon, authenticated;
revoke execute on function public._notify_reaction() from public, anon, authenticated;

-- 4. Index every foreign key the advisor flagged, so deleting an account or a meal (which cascades)
-- doesn't scan whole tables.
create index if not exists comparisons_loser_place_id_fk_idx on public.comparisons (loser_place_id);
create index if not exists comparisons_meal_id_fk_idx on public.comparisons (meal_id);
create index if not exists decide_candidates_place_id_fk_idx on public.decide_candidates (place_id);
create index if not exists decide_sessions_crew_id_fk_idx on public.decide_sessions (crew_id);
create index if not exists decide_sessions_matched_place_id_fk_idx on public.decide_sessions (matched_place_id);
create index if not exists decide_votes_place_id_fk_idx on public.decide_votes (place_id);
create index if not exists dishes_created_by_fk_idx on public.dishes (created_by);
create index if not exists fight_matchups_place_a_fk_idx on public.fight_matchups (place_a);
create index if not exists fight_matchups_place_b_fk_idx on public.fight_matchups (place_b);
create index if not exists fight_matchups_winner_place_id_fk_idx on public.fight_matchups (winner_place_id);
create index if not exists fight_votes_winner_place_id_fk_idx on public.fight_votes (winner_place_id);
create index if not exists food_fights_winner_place_id_fk_idx on public.food_fights (winner_place_id);
create index if not exists meals_cover_media_id_fk_idx on public.meals (cover_media_id);
create index if not exists notifications_actor_id_fk_idx on public.notifications (actor_id);
create index if not exists notifications_meal_id_fk_idx on public.notifications (meal_id);
create index if not exists notifications_place_id_fk_idx on public.notifications (place_id);
create index if not exists notifications_plan_id_fk_idx on public.notifications (plan_id);
create index if not exists party_members_invited_by_fk_idx on public.party_members (invited_by);
create index if not exists party_members_meal_id_fk_idx on public.party_members (meal_id);
create index if not exists place_import_matched_place_id_fk_idx on public.place_import (matched_place_id);
create index if not exists places_created_by_fk_idx on public.places (created_by);
create index if not exists plan_guests_invited_by_fk_idx on public.plan_guests (invited_by);
create index if not exists plans_crew_id_fk_idx on public.plans (crew_id);
create index if not exists plans_decide_session_id_fk_idx on public.plans (decide_session_id);
create index if not exists quick_takes_user_id_fk_idx on public.quick_takes (user_id);
create index if not exists rankings_last_meal_id_fk_idx on public.rankings (last_meal_id);
create index if not exists saves_source_meal_id_fk_idx on public.saves (source_meal_id);
create index if not exists signup_allowlist_school_id_fk_idx on public.signup_allowlist (school_id);
create index if not exists user_badges_badge_key_fk_idx on public.user_badges (badge_key);

-- Left as is on purpose:
-- * ai_requests and place_import have RLS on and no policies: server-only tables, clients get nothing.
-- * The remaining "signed-in users can execute SECURITY DEFINER" findings are the app's RPCs
--   (submit_rating, get_feed, tonight_picks, ...). Each checks auth.uid() itself.
-- * "Unused index" findings are expected before launch (no traffic yet).
