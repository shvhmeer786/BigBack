-- BigBack · 0005 · access helpers + Row Level Security on every table
--
-- Visibility model (decided 2026-10-15):
--   * Feed = people you follow. Every posted Meal is visible to all followers.
--   * Public profile  -> any signed-in user can see the person's posted meals & rankings.
--   * Private profile -> only accepted followers can.
--   * Blocks in either direction hide everything.
--   * Meals with visibility 'only_me' are visible to the owner (and their party) only.
--   * People in the same party (eating together) always see each other's meals/media.

-- ---------------------------------------------------------------------------
-- Helpers (SECURITY DEFINER so policies can call them without recursive RLS)
-- ---------------------------------------------------------------------------
create or replace function public.is_blocked_between(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.blocks
    where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a)
  );
$$;

create or replace function public.is_following(p_follower uuid, p_followee uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.follows
    where follower_id = p_follower and followee_id = p_followee and status = 'accepted'
  );
$$;

-- Can the current user see this author's content (posted meals, rankings, saves, dish ratings)?
create or replace function public.can_view_user_content(p_author uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    p_author = (select auth.uid())
    or (
      (select auth.uid()) is not null
      and not public.is_blocked_between((select auth.uid()), p_author)
      and (
        not coalesce((select p.is_private from public.profiles p where p.id = p_author), true)
        or public.is_following((select auth.uid()), p_author)
      )
    );
$$;

create or replace function public.is_party_member(p_party uuid, p_user uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_party is not null and exists (
    select 1 from public.parties pa
    where pa.id = p_party
      and (pa.host_id = p_user
           or exists (select 1 from public.party_members pm
                      where pm.party_id = p_party and pm.user_id = p_user and pm.status = 'accepted'))
  );
$$;

create or replace function public.can_view_meal(p_meal uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.meals m
    where m.id = p_meal
      and (
        m.user_id = (select auth.uid())
        or public.is_party_member(m.party_id, (select auth.uid()))
        or (m.status = 'posted' and m.visibility = 'followers' and public.can_view_user_content(m.user_id))
      )
  );
$$;

create or replace function public.is_crew_member(p_crew uuid, p_user uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.crews c where c.id = p_crew and c.owner_id = p_user
  ) or exists (
    select 1 from public.crew_members cm where cm.crew_id = p_crew and cm.user_id = p_user
  );
$$;

create or replace function public.can_view_plan(p_plan uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.plans p
    where p.id = p_plan
      and (
        p.host_id = (select auth.uid())
        or exists (select 1 from public.plan_guests g where g.plan_id = p.id and g.user_id = (select auth.uid()))
        or (p.crew_id is not null and public.is_crew_member(p.crew_id, (select auth.uid())))
      )
  );
$$;

create or replace function public.is_decide_participant(p_session uuid, p_user uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.decide_sessions s where s.id = p_session and s.host_id = p_user)
      or exists (select 1 from public.decide_participants dp where dp.session_id = p_session and dp.user_id = p_user);
$$;

-- ---------------------------------------------------------------------------
-- Enable RLS everywhere
-- ---------------------------------------------------------------------------
alter table public.schools             enable row level security;
alter table public.profiles            enable row level security;
alter table public.follows             enable row level security;
alter table public.blocks              enable row level security;
alter table public.crews               enable row level security;
alter table public.crew_members        enable row level security;
alter table public.places              enable row level security;
alter table public.place_hours         enable row level security;
alter table public.place_import        enable row level security;
alter table public.place_edits         enable row level security;
alter table public.place_stats         enable row level security;
alter table public.saves               enable row level security;
alter table public.parties             enable row level security;
alter table public.party_members       enable row level security;
alter table public.meals               enable row level security;
alter table public.meal_media          enable row level security;
alter table public.quick_takes         enable row level security;
alter table public.dishes              enable row level security;
alter table public.dish_ratings        enable row level security;
alter table public.rankings            enable row level security;
alter table public.comparisons         enable row level security;
alter table public.user_similarity     enable row level security;
alter table public.reactions           enable row level security;
alter table public.comments            enable row level security;
alter table public.reports             enable row level security;
alter table public.decide_sessions     enable row level security;
alter table public.decide_participants enable row level security;
alter table public.decide_candidates   enable row level security;
alter table public.decide_votes        enable row level security;
alter table public.plans               enable row level security;
alter table public.plan_guests         enable row level security;
alter table public.notifications       enable row level security;
alter table public.device_tokens       enable row level security;
alter table public.ai_requests         enable row level security;
alter table public.app_config          enable row level security;
alter table public.seasons             enable row level security;
alter table public.badges              enable row level security;
alter table public.user_badges         enable row level security;
alter table public.food_fights         enable row level security;
alter table public.fight_matchups      enable row level security;
alter table public.fight_votes         enable row level security;

-- ---------------------------------------------------------------------------
-- Reference data: readable by everyone signed in (schools also by the auth hook)
-- ---------------------------------------------------------------------------
create policy "schools are readable" on public.schools
  for select to anon, authenticated, supabase_auth_admin using (true);
create policy "places are readable" on public.places
  for select to authenticated using (true);
create policy "place hours are readable" on public.place_hours
  for select to authenticated using (true);
create policy "place stats are readable" on public.place_stats
  for select to authenticated using (true);
create policy "dishes are readable" on public.dishes
  for select to authenticated using (true);
create policy "signed-in users can add dishes" on public.dishes
  for insert to authenticated with check (created_by = (select auth.uid()));
create policy "app config is readable" on public.app_config
  for select to anon, authenticated using (true);
create policy "seasons are readable" on public.seasons
  for select to authenticated using (true);
create policy "badges are readable" on public.badges
  for select to authenticated using (true);
create policy "food fights are readable" on public.food_fights
  for select to authenticated using (true);
create policy "fight matchups are readable" on public.fight_matchups
  for select to authenticated using (true);
-- place_import, ai_requests: no client policies (service role only).

-- ---------------------------------------------------------------------------
-- Profiles, follows, blocks
-- ---------------------------------------------------------------------------
create policy "profiles are readable unless blocked" on public.profiles
  for select to authenticated
  using (id = (select auth.uid()) or not public.is_blocked_between((select auth.uid()), id));
create policy "users update their own profile" on public.profiles
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy "follows visible to the two people or when the followee is visible" on public.follows
  for select to authenticated
  using (
    follower_id = (select auth.uid()) or followee_id = (select auth.uid())
    or (status = 'accepted' and public.can_view_user_content(followee_id) and public.can_view_user_content(follower_id))
  );
create policy "users follow as themselves" on public.follows
  for insert to authenticated
  with check (follower_id = (select auth.uid()) and not public.is_blocked_between(follower_id, followee_id));
create policy "followee accepts requests" on public.follows
  for update to authenticated
  using (followee_id = (select auth.uid())) with check (followee_id = (select auth.uid()));
create policy "either side can remove a follow" on public.follows
  for delete to authenticated
  using (follower_id = (select auth.uid()) or followee_id = (select auth.uid()));

create policy "users see their own blocks" on public.blocks
  for select to authenticated using (blocker_id = (select auth.uid()));
create policy "users block as themselves" on public.blocks
  for insert to authenticated with check (blocker_id = (select auth.uid()));
create policy "users unblock their own blocks" on public.blocks
  for delete to authenticated using (blocker_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Crews
-- ---------------------------------------------------------------------------
create policy "crew members see the crew" on public.crews
  for select to authenticated using (public.is_crew_member(id));
create policy "users create crews they own" on public.crews
  for insert to authenticated with check (owner_id = (select auth.uid()));
create policy "owners edit crews" on public.crews
  for update to authenticated using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy "owners delete crews" on public.crews
  for delete to authenticated using (owner_id = (select auth.uid()));

create policy "crew members see members" on public.crew_members
  for select to authenticated using (public.is_crew_member(crew_id));
create policy "owners add members" on public.crew_members
  for insert to authenticated
  with check (exists (select 1 from public.crews c where c.id = crew_id and c.owner_id = (select auth.uid())));
create policy "owners remove members, members leave" on public.crew_members
  for delete to authenticated
  using (user_id = (select auth.uid())
         or exists (select 1 from public.crews c where c.id = crew_id and c.owner_id = (select auth.uid())));

-- ---------------------------------------------------------------------------
-- Places: user edits, saves
-- ---------------------------------------------------------------------------
create policy "users see their own place edits" on public.place_edits
  for select to authenticated using (user_id = (select auth.uid()));
create policy "users suggest place edits" on public.place_edits
  for insert to authenticated with check (user_id = (select auth.uid()) and status = 'pending');

create policy "saves visible like the saver's content" on public.saves
  for select to authenticated using (public.can_view_user_content(user_id));
create policy "users save for themselves" on public.saves
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy "users edit their saves" on public.saves
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "users unsave" on public.saves
  for delete to authenticated using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Meals & capture
-- ---------------------------------------------------------------------------
create policy "party members see the party" on public.parties
  for select to authenticated
  using (host_id = (select auth.uid()) or public.is_party_member(id)
         or exists (select 1 from public.party_members pm where pm.party_id = id and pm.user_id = (select auth.uid())));
create policy "hosts create parties" on public.parties
  for insert to authenticated with check (host_id = (select auth.uid()));
create policy "hosts end parties" on public.parties
  for update to authenticated using (host_id = (select auth.uid())) with check (host_id = (select auth.uid()));

create policy "party members see members" on public.party_members
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_party_member(party_id));
create policy "invitee responds" on public.party_members
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "member leaves" on public.party_members
  for delete to authenticated using (user_id = (select auth.uid()));
-- inserts go through tag_friends() / join_party()

create policy "meals visible per visibility model" on public.meals
  for select to authenticated using (public.can_view_meal(id));
create policy "users start their own meals" on public.meals
  for insert to authenticated
  with check (user_id = (select auth.uid()) and status in ('live', 'unrated')
              and (party_id is null or public.is_party_member(party_id)));
create policy "users edit their own meals" on public.meals
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "users delete their own meals" on public.meals
  for delete to authenticated using (user_id = (select auth.uid()));

create policy "media visible with its meal" on public.meal_media
  for select to authenticated using (public.can_view_meal(meal_id));
create policy "users add media to their own meals" on public.meal_media
  for insert to authenticated
  with check (user_id = (select auth.uid())
              and exists (select 1 from public.meals m where m.id = meal_id and m.user_id = (select auth.uid())));
create policy "users edit their own media" on public.meal_media
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "users delete their own media" on public.meal_media
  for delete to authenticated using (user_id = (select auth.uid()));

create policy "quick takes are private to the author" on public.quick_takes
  for select to authenticated using (user_id = (select auth.uid()));
create policy "users add quick takes to their meals" on public.quick_takes
  for insert to authenticated
  with check (user_id = (select auth.uid())
              and exists (select 1 from public.meals m where m.id = meal_id and m.user_id = (select auth.uid())));
create policy "users delete their quick takes" on public.quick_takes
  for delete to authenticated using (user_id = (select auth.uid()));

create policy "dish ratings visible with the meal" on public.dish_ratings
  for select to authenticated using (public.can_view_meal(meal_id));
create policy "users rate dishes on their meals" on public.dish_ratings
  for insert to authenticated
  with check (user_id = (select auth.uid())
              and exists (select 1 from public.meals m where m.id = meal_id and m.user_id = (select auth.uid())));
create policy "users change their dish ratings" on public.dish_ratings
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "users remove their dish ratings" on public.dish_ratings
  for delete to authenticated using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Rankings (writes only via SECURITY DEFINER functions)
-- ---------------------------------------------------------------------------
create policy "rankings visible like the ranker's content" on public.rankings
  for select to authenticated using (public.can_view_user_content(user_id));
create policy "users see their own comparisons" on public.comparisons
  for select to authenticated using (user_id = (select auth.uid()));
create policy "users see their own similarity rows" on public.user_similarity
  for select to authenticated using (user_a = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Reactions, comments, reports
-- ---------------------------------------------------------------------------
create policy "reactions visible with the meal" on public.reactions
  for select to authenticated using (public.can_view_meal(meal_id));
create policy "users react to meals they can see" on public.reactions
  for insert to authenticated with check (user_id = (select auth.uid()) and public.can_view_meal(meal_id));
create policy "users change their reaction" on public.reactions
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "users remove their reaction" on public.reactions
  for delete to authenticated using (user_id = (select auth.uid()));

create policy "comments visible with the meal" on public.comments
  for select to authenticated
  using (public.can_view_meal(meal_id) and not public.is_blocked_between((select auth.uid()), user_id));
create policy "users comment on meals they can see" on public.comments
  for insert to authenticated with check (user_id = (select auth.uid()) and public.can_view_meal(meal_id));
create policy "users edit their comments" on public.comments
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "authors or meal owners delete comments" on public.comments
  for delete to authenticated
  using (user_id = (select auth.uid())
         or exists (select 1 from public.meals m where m.id = meal_id and m.user_id = (select auth.uid())));

create policy "users file reports" on public.reports
  for insert to authenticated with check (reporter_id = (select auth.uid()));
create policy "users see their own reports" on public.reports
  for select to authenticated using (reporter_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Plans & deciding (guests on the web go through Edge Functions with the service role)
-- ---------------------------------------------------------------------------
create policy "plan visible to host, guests, crew" on public.plans
  for select to authenticated using (public.can_view_plan(id));
create policy "hosts create plans" on public.plans
  for insert to authenticated with check (host_id = (select auth.uid()));
create policy "hosts edit plans" on public.plans
  for update to authenticated using (host_id = (select auth.uid())) with check (host_id = (select auth.uid()));
create policy "hosts delete plans" on public.plans
  for delete to authenticated using (host_id = (select auth.uid()));

create policy "guest list visible with the plan" on public.plan_guests
  for select to authenticated using (public.can_view_plan(plan_id));
create policy "hosts invite guests" on public.plan_guests
  for insert to authenticated
  with check (exists (select 1 from public.plans p where p.id = plan_id and p.host_id = (select auth.uid())));
create policy "guests rsvp for themselves" on public.plan_guests
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "hosts remove guests, guests leave" on public.plan_guests
  for delete to authenticated
  using (user_id = (select auth.uid())
         or exists (select 1 from public.plans p where p.id = plan_id and p.host_id = (select auth.uid())));

create policy "participants see the session" on public.decide_sessions
  for select to authenticated using (public.is_decide_participant(id));
create policy "hosts update the session" on public.decide_sessions
  for update to authenticated using (host_id = (select auth.uid())) with check (host_id = (select auth.uid()));
create policy "participants see participants" on public.decide_participants
  for select to authenticated using (public.is_decide_participant(session_id));
create policy "participants see candidates" on public.decide_candidates
  for select to authenticated using (public.is_decide_participant(session_id));
create policy "participants see votes" on public.decide_votes
  for select to authenticated using (public.is_decide_participant(session_id));
-- session creation, joining and voting go through create_decide_session() / decide_vote()

-- ---------------------------------------------------------------------------
-- Notifications, devices, badges, fights
-- ---------------------------------------------------------------------------
create policy "users read their notifications" on public.notifications
  for select to authenticated using (user_id = (select auth.uid()));
create policy "users mark notifications read" on public.notifications
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "users clear notifications" on public.notifications
  for delete to authenticated using (user_id = (select auth.uid()));

create policy "users manage their device tokens" on public.device_tokens
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy "badges visible like the user's content" on public.user_badges
  for select to authenticated using (public.can_view_user_content(user_id));
create policy "users see their own fight votes" on public.fight_votes
  for select to authenticated using (user_id = (select auth.uid()));
-- votes go through fight_vote()

-- Column-level guards (system-owned columns) are BEFORE UPDATE triggers in 0006,
-- because table-level UPDATE grants make column REVOKEs ineffective.
