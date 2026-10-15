-- BigBack · 0004 · core tables: meals & capture, dishes, rankings, social, plans & deciding,
-- notifications & ops, gamification. Access rules live in 0005, logic in 0006.

-- ===========================================================================
-- MEALS & CAPTURE
-- ===========================================================================

-- A party groups the Meals of people eating together (tags, QR join, plans).
-- Table Verdict + shared album = all meals with the same party_id.
create table public.parties (
  id         uuid primary key default gen_random_uuid(),
  place_id   uuid not null references public.places (id) on delete cascade,
  host_id    uuid not null references public.profiles (id) on delete cascade,
  plan_id    uuid,  -- FK below, once plans exists
  join_code  text not null unique default substr(replace(gen_random_uuid()::text, '-', ''), 1, 10),
  created_at timestamptz not null default now(),
  ended_at   timestamptz
);
create index parties_host_idx on public.parties (host_id);
create index parties_place_idx on public.parties (place_id);

-- One person's meal at a place: live (capturing) -> unrated (waiting in To-rate) -> posted.
-- ids may be generated on device (offline-first, idempotent upserts).
create table public.meals (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles (id) on delete cascade,
  place_id         uuid not null references public.places (id) on delete restrict,
  party_id         uuid references public.parties (id) on delete set null,
  plan_id          uuid,  -- FK below
  status           public.meal_status not null default 'live',
  visibility       public.meal_visibility not null default 'followers',
  started_at       timestamptz not null default now(),
  ended_at         timestamptz,
  posted_at        timestamptz,
  tier             public.tier,
  vibe             public.vibe,
  score_at_post    numeric(3, 1),
  visit_delta      text check (visit_delta in ('better', 'same', 'worse')),  -- repeat visits
  note             text check (char_length(note) <= 2000),
  price_per_person numeric(7, 2) check (price_per_person >= 0),
  currency         char(3) not null default 'CAD',
  cover_media_id   uuid,  -- FK below
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint meals_posted_has_rating
    check (status <> 'posted' or (tier is not null and vibe is not null and posted_at is not null))
);
comment on table public.meals is 'A Meal: one person eating at a place. Becomes the feed post once rated.';
create index meals_user_posted_idx on public.meals (user_id, posted_at desc) where status = 'posted';
create index meals_place_posted_idx on public.meals (place_id, posted_at desc) where status = 'posted';
create index meals_party_idx on public.meals (party_id) where party_id is not null;
create index meals_plan_idx on public.meals (plan_id) where plan_id is not null;
create index meals_live_idx on public.meals (started_at) where status = 'live';
create index meals_user_status_idx on public.meals (user_id, status);
create unique index meals_one_live_per_user on public.meals (user_id) where status = 'live';
create trigger meals_updated_at before update on public.meals
  for each row execute function public.set_updated_at();

create table public.party_members (
  party_id     uuid not null references public.parties (id) on delete cascade,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  status       public.member_status not null default 'pending',
  invited_by   uuid references public.profiles (id) on delete set null,
  meal_id      uuid references public.meals (id) on delete set null,
  created_at   timestamptz not null default now(),
  responded_at timestamptz,
  primary key (party_id, user_id)
);
create index party_members_user_idx on public.party_members (user_id, status);

create table public.dishes (
  id         uuid primary key default gen_random_uuid(),
  place_id   uuid not null references public.places (id) on delete cascade,
  name       text not null check (char_length(name) between 1 and 80),
  name_key   text generated always as (public.search_key(name)) stored,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (place_id, name_key)
);
create index dishes_name_trgm_idx on public.dishes using gin (name_key extensions.gin_trgm_ops);

-- A capture: front + back camera (BeReal-style), or one image, or a 3s clip.
create table public.meal_media (
  id          uuid primary key default gen_random_uuid(),
  meal_id     uuid not null references public.meals (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  kind        public.media_kind not null default 'dual',
  back_path   text,   -- storage path in bucket meal-media
  front_path  text,
  thumb_path  text,
  video_path  text,
  moment      public.moment not null default 'food',
  dish_id     uuid references public.dishes (id) on delete set null,
  caption     text check (char_length(caption) <= 280),
  is_live     boolean not null default false,  -- captured in-app at the place
  width       int,
  height      int,
  sort_order  int not null default 0,
  taken_at    timestamptz not null default now(),
  created_at  timestamptz not null default now(),
  check (back_path is not null or video_path is not null)
);
create index meal_media_meal_idx on public.meal_media (meal_id, sort_order, taken_at);
create index meal_media_user_idx on public.meal_media (user_id);
create index meal_media_dish_idx on public.meal_media (dish_id) where dish_id is not null;

alter table public.meals
  add constraint meals_cover_media_fk foreign key (cover_media_id)
  references public.meal_media (id) on delete set null deferrable initially deferred;
alter table public.saves
  add constraint saves_source_meal_fk foreign key (source_meal_id)
  references public.meals (id) on delete set null;

-- Quick takes: one-liners / voice notes captured during the meal, used in the recap.
create table public.quick_takes (
  id         uuid primary key default gen_random_uuid(),
  meal_id    uuid not null references public.meals (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  body       text check (char_length(body) <= 280),
  audio_path text,
  transcript text check (char_length(transcript) <= 1000),
  created_at timestamptz not null default now(),
  check (body is not null or audio_path is not null)
);
create index quick_takes_meal_idx on public.quick_takes (meal_id);

create table public.dish_ratings (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  meal_id    uuid not null references public.meals (id) on delete cascade,
  dish_id    uuid not null references public.dishes (id) on delete cascade,
  thumb      smallint not null check (thumb in (-1, 1)),
  is_best    boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (user_id, meal_id, dish_id)
);
create index dish_ratings_dish_idx on public.dish_ratings (dish_id);
create unique index dish_ratings_one_best_per_meal on public.dish_ratings (meal_id) where is_best;

-- ===========================================================================
-- RANKINGS
-- ===========================================================================

-- One row per (user, place). position is 0-based inside the user's tier list
-- (one list per tier, across vibes). score is derived: public.tier_score(tier, position, n).
create table public.rankings (
  user_id      uuid not null references public.profiles (id) on delete cascade,
  place_id     uuid not null references public.places (id) on delete cascade,
  tier         public.tier not null,
  vibe         public.vibe not null,
  position     int not null check (position >= 0),
  score        numeric(3, 1) not null default 0,
  settled      boolean not null default true,  -- false = comparison cap hit, refine later
  visits       int not null default 1,
  last_meal_id uuid references public.meals (id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  primary key (user_id, place_id),
  constraint rankings_unique_position unique (user_id, tier, position) deferrable initially deferred
);
comment on table public.rankings is 'Personal ranked lists. Writes go through submit_rating / move_ranking / rerate_visit.';
create index rankings_place_idx on public.rankings (place_id);
create index rankings_user_vibe_idx on public.rankings (user_id, vibe, score desc);

create table public.comparisons (
  id              bigint generated always as identity primary key,
  user_id         uuid not null references public.profiles (id) on delete cascade,
  winner_place_id uuid not null references public.places (id) on delete cascade,
  loser_place_id  uuid not null references public.places (id) on delete cascade,
  is_tie          boolean not null default false,
  source          public.comparison_source not null,
  meal_id         uuid references public.meals (id) on delete set null,
  created_at      timestamptz not null default now(),
  check (winner_place_id <> loser_place_id)
);
create index comparisons_user_idx on public.comparisons (user_id, created_at desc);
create index comparisons_pair_idx on public.comparisons (winner_place_id, loser_place_id);

-- Taste similarity between two users (Pearson r over shared rankings, n >= 5). Nightly job.
create table public.user_similarity (
  user_a     uuid not null references public.profiles (id) on delete cascade,
  user_b     uuid not null references public.profiles (id) on delete cascade,
  n_shared   int not null,
  corr       numeric(4, 3) not null,
  updated_at timestamptz not null default now(),
  primary key (user_a, user_b)
);
create index user_similarity_b_idx on public.user_similarity (user_b);

-- ===========================================================================
-- SOCIAL INTERACTIONS & SAFETY
-- ===========================================================================

create table public.reactions (
  meal_id     uuid not null references public.meals (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  kind        text not null check (kind in ('drool', 'fire', 'want', 'lol', 'mid', 'selfie')),
  selfie_path text,  -- selfie reaction image (kind = 'selfie')
  created_at  timestamptz not null default now(),
  primary key (meal_id, user_id)
);
create index reactions_user_idx on public.reactions (user_id);

create table public.comments (
  id         uuid primary key default gen_random_uuid(),
  meal_id    uuid not null references public.meals (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  parent_id  uuid references public.comments (id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now(),
  edited_at  timestamptz,
  deleted_at timestamptz
);
create index comments_meal_idx on public.comments (meal_id, created_at);
create index comments_user_idx on public.comments (user_id);
create index comments_parent_idx on public.comments (parent_id) where parent_id is not null;

-- App Store guideline 1.2: users can report objectionable content and abusive users.
create table public.reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  target_type text not null check (target_type in ('meal', 'media', 'comment', 'profile', 'place', 'plan')),
  target_id   uuid not null,
  reason      text not null check (reason in ('spam', 'harassment', 'hate', 'nudity', 'violence', 'self_harm', 'misinformation', 'impersonation', 'other')),
  details     text check (char_length(details) <= 1000),
  status      public.report_status not null default 'open',
  created_at  timestamptz not null default now(),
  resolved_at timestamptz
);
create index reports_open_idx on public.reports (created_at) where status = 'open';
create index reports_reporter_idx on public.reports (reporter_id);

-- ===========================================================================
-- PLANS (Partiful-style invites) & LET'S EAT (group swipe)
-- ===========================================================================

create table public.decide_sessions (
  id               uuid primary key default gen_random_uuid(),
  host_id          uuid not null references public.profiles (id) on delete cascade,
  crew_id          uuid references public.crews (id) on delete set null,
  status           public.decide_status not null default 'open',
  constraints      jsonb not null default '{}'::jsonb,  -- {budget, craving, vibe, starts_at, radius_m}
  center           extensions.geography(point, 4326),
  matched_place_id uuid references public.places (id) on delete set null,
  invite_code      text not null unique default substr(replace(gen_random_uuid()::text, '-', ''), 1, 10),
  expires_at       timestamptz not null default now() + interval '3 hours',
  created_at       timestamptz not null default now(),
  decided_at       timestamptz
);
create index decide_sessions_host_idx on public.decide_sessions (host_id);

-- Participants: app users (user_id) or web guests (guest_token, no account).
create table public.decide_participants (
  id          uuid primary key default gen_random_uuid(),
  session_id  uuid not null references public.decide_sessions (id) on delete cascade,
  user_id     uuid references public.profiles (id) on delete cascade,
  guest_token uuid unique,
  guest_name  text check (char_length(guest_name) <= 40),
  joined_at   timestamptz not null default now(),
  check (user_id is not null or guest_token is not null),
  unique (session_id, user_id)
);
create index decide_participants_user_idx on public.decide_participants (user_id);

create table public.decide_candidates (
  session_id  uuid not null references public.decide_sessions (id) on delete cascade,
  place_id    uuid not null references public.places (id) on delete cascade,
  position    int not null,
  group_score numeric(3, 1),
  reason      text,
  primary key (session_id, place_id)
);

create table public.decide_votes (
  session_id     uuid not null references public.decide_sessions (id) on delete cascade,
  place_id       uuid not null references public.places (id) on delete cascade,
  participant_id uuid not null references public.decide_participants (id) on delete cascade,
  liked          boolean not null,
  created_at     timestamptz not null default now(),
  primary key (session_id, place_id, participant_id)
);
create index decide_votes_participant_idx on public.decide_votes (participant_id);

create table public.plans (
  id                  uuid primary key default gen_random_uuid(),
  host_id             uuid not null references public.profiles (id) on delete cascade,
  place_id            uuid not null references public.places (id) on delete restrict,
  crew_id             uuid references public.crews (id) on delete set null,
  decide_session_id   uuid references public.decide_sessions (id) on delete set null,
  starts_at           timestamptz not null,
  title               text check (char_length(title) <= 80),
  note                text check (char_length(note) <= 500),
  status              public.plan_status not null default 'planned',
  invite_code         text not null unique default substr(replace(gen_random_uuid()::text, '-', ''), 1, 10),
  reservation_status  public.reservation_status not null default 'none',
  reservation_ref     text,
  party_size          int check (party_size between 1 and 50),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create index plans_host_idx on public.plans (host_id, starts_at desc);
create index plans_upcoming_idx on public.plans (starts_at) where status = 'planned';
create index plans_place_idx on public.plans (place_id);
create trigger plans_updated_at before update on public.plans
  for each row execute function public.set_updated_at();

create table public.plan_guests (
  id           uuid primary key default gen_random_uuid(),
  plan_id      uuid not null references public.plans (id) on delete cascade,
  user_id      uuid references public.profiles (id) on delete cascade,
  guest_token  uuid unique,
  guest_name   text check (char_length(guest_name) <= 40),
  rsvp         public.rsvp not null default 'invited',
  invited_by   uuid references public.profiles (id) on delete set null,
  responded_at timestamptz,
  created_at   timestamptz not null default now(),
  check (user_id is not null or guest_token is not null),
  unique (plan_id, user_id)
);
create index plan_guests_user_idx on public.plan_guests (user_id);

alter table public.parties
  add constraint parties_plan_fk foreign key (plan_id) references public.plans (id) on delete set null;
alter table public.meals
  add constraint meals_plan_fk foreign key (plan_id) references public.plans (id) on delete set null;
create index parties_plan_idx on public.parties (plan_id) where plan_id is not null;

-- ===========================================================================
-- NOTIFICATIONS, DEVICES, AI, CONFIG
-- ===========================================================================

create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  kind       text not null,  -- follow, follow_request, follow_accepted, reaction, comment, meal_tag,
                             -- plan_invite, plan_rsvp, friend_went, table_verdict, decide_match, challenge
  actor_id   uuid references public.profiles (id) on delete cascade,
  meal_id    uuid references public.meals (id) on delete cascade,
  plan_id    uuid references public.plans (id) on delete cascade,
  place_id   uuid references public.places (id) on delete cascade,
  payload    jsonb not null default '{}'::jsonb,
  read_at    timestamptz,
  pushed_at  timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);
create index notifications_unpushed_idx on public.notifications (created_at) where pushed_at is null;

create table public.device_tokens (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  token       text not null unique,
  kind        text not null check (kind in ('apns', 'apns_sandbox', 'live_activity')),
  app_version text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index device_tokens_user_idx on public.device_tokens (user_id);
create trigger device_tokens_updated_at before update on public.device_tokens
  for each row execute function public.set_updated_at();

-- Written only by Edge Functions (service role): rate limits + cost tracking.
create table public.ai_requests (
  id            bigint generated always as identity primary key,
  user_id       uuid references public.profiles (id) on delete set null,
  kind          text not null,
  model         text not null,
  input_tokens  int,
  output_tokens int,
  latency_ms    int,
  ok            boolean not null default true,
  created_at    timestamptz not null default now()
);
create index ai_requests_user_day_idx on public.ai_requests (user_id, created_at desc);

-- Remote config / feature flags, readable by the app.
create table public.app_config (
  key        text primary key,
  value      jsonb not null,
  updated_at timestamptz not null default now()
);

-- ===========================================================================
-- GAMIFICATION (fast-follow features; tables exist now so the model is complete)
-- ===========================================================================

-- Waterloo terms as seasons: leaderboards reset, Term Wrapped is generated per season.
create table public.seasons (
  id        uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  name      text not null,       -- e.g. "Fall 2026"
  starts_on date not null,
  ends_on   date not null,
  check (ends_on > starts_on),
  unique (school_id, name)
);

create table public.badges (
  key         text primary key,
  name        text not null,
  description text not null,
  icon        text not null default 'badge'
);

create table public.user_badges (
  user_id   uuid not null references public.profiles (id) on delete cascade,
  badge_key text not null references public.badges (key) on delete cascade,
  earned_at timestamptz not null default now(),
  primary key (user_id, badge_key)
);

-- Food Fights: weekly campus brackets ("Best shawarma at UW").
create table public.food_fights (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null references public.schools (id) on delete cascade,
  title      text not null,
  vibe       public.vibe,
  cuisine    text,
  starts_at  timestamptz not null,
  ends_at    timestamptz not null,
  status     text not null default 'scheduled' check (status in ('scheduled', 'live', 'done')),
  winner_place_id uuid references public.places (id) on delete set null,
  created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);
create index food_fights_school_idx on public.food_fights (school_id, starts_at desc);

create table public.fight_matchups (
  id              uuid primary key default gen_random_uuid(),
  fight_id        uuid not null references public.food_fights (id) on delete cascade,
  round           int not null check (round >= 1),
  slot            int not null,
  place_a         uuid not null references public.places (id) on delete cascade,
  place_b         uuid not null references public.places (id) on delete cascade,
  winner_place_id uuid references public.places (id) on delete set null,
  opens_at        timestamptz not null,
  closes_at       timestamptz not null,
  unique (fight_id, round, slot),
  check (place_a <> place_b)
);

-- Only people with a posted meal at BOTH places may vote (enforced in fight_vote()).
create table public.fight_votes (
  matchup_id      uuid not null references public.fight_matchups (id) on delete cascade,
  user_id         uuid not null references public.profiles (id) on delete cascade,
  winner_place_id uuid not null references public.places (id) on delete cascade,
  created_at      timestamptz not null default now(),
  primary key (matchup_id, user_id)
);
create index fight_votes_user_idx on public.fight_votes (user_id);
