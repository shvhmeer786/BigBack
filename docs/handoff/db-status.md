# Database status: `big-back` (iefchnylrxolydtulmgt)

_Updated 2026-10-15. Everything in `supabase/migrations/` is applied; file names match the applied versions._

## Applied (in order)
| Version · name | What it does |
|---|---|
| `20261015061936_extensions_types_utils` | Extensions (PostGIS, pg_trgm, citext, unaccent, pg_net, pg_cron), enums, helpers |
| `20261015062150_identity_social` | Schools, profiles, follows, blocks, crews |
| `20261015062253_places` | Places, hours, open-data staging, edits, stats, saves |
| `20261015062610_core_tables` | Meals, media, parties, rankings, comparisons, plans, Let's eat, notifications, moderation |
| `20261015063101_access_rls` | RLS on all 41 tables, plus the visibility helpers |
| `20261015070311_logic_core` | Guard triggers, ranking engine, feed, place scores, Tonight, search, streak, leaderboard |
| `20261015071735_logic_plan_by_code` | Invite lookup by code |
| `20261015071854_logic_social_actions` | Tagging, plans, RSVP, Let's eat, Food Fights |
| `20261015072016_logic_notifications` | Notification triggers |
| `20261015072048_logic_jobs_privileges` | Jobs and function privileges |
| `20261015072126_storage_realtime_cron_seed` | 4 Storage buckets, realtime, 5 cron jobs, UW + seasons + badges + config |
| `20261015072145_resolve_place` | MapKit result → our place |
| `20261015072220_app_review_access` | Sign-up allowlist + `profiles.is_demo` for the App Review demo account |
| `20261015150709_rls_returning_fixes` | Lets the app read back a meal, plan, crew or Let's eat session right after creating it |
| `20261015154339_places_anywhere` | Places store their own country and time zone, so students can rank anywhere and "open now" is right outside Ontario |
| `20261015155311_advisor_fixes` | Follow/block helpers answer only about the caller; nothing privileged is callable signed-out; every foreign key indexed |
| `20261015173756_ai_model_haiku_5_5` | `app_config.ai.model` = `claude-haiku-5-5` |

## Smoke test: passing
`supabase/tests/smoke_test.sql` runs as three fake UW students and always rolls back. Last run (2026-10-15) passed
all 20 checks:

`profiles+school, first-rating=9.0, binary-insert+rescore, tier-bands, meal-guard, rankings-rls, move_ranking,
feed+friend_went, private-profiles, party+tagging, lets-eat, plans+rsvp, reads, resolve_place, rank-anywhere,
blocks, privacy-helpers, jobs, local-hours, signup-uw-only`

## Advisors (2026-10-15, after `advisor_fixes`)
- **Fixed:**
  - follow/block helpers could be used to probe other people;
  - signed-out access to privileged functions;
  - 29 unindexed foreign keys.
- **Expected and left as is:**
  - `ai_requests` and `place_import` have RLS with no policies. They are server-only, so clients get nothing.
  - "Signed-in users can execute SECURITY DEFINER function" lists the app's own RPCs (`submit_rating`, `get_feed`, …). Each one checks `auth.uid()` itself.
  - "Unused index" findings appear because there's no traffic yet.

## Clean-up for later (SQL editor)
- `drop function public._resolve_place_v1(text, text, double precision, double precision, text, text);`. It's the
  pre-`places_anywhere` version, renamed and locked; no role can call it. The Supabase MCP holds DROP statements,
  so run this from the dashboard.

## Lessons for running migrations through the Supabase MCP
- Statements the MCP considers destructive (`delete from auth.users`, `delete ... where true`, `drop policy`) are
  held for a confirmation that never appears, and the call times out after 60 s. Use `ALTER`, upserts or renames,
  or run them from the Supabase SQL editor.
- In cloud sessions, every MCP call asks for approval even with `.claude/settings.json` allow rules.

## Manual dashboard steps (owner)
- **Auth → Hooks:** enable **Before User Created** → `public.hook_before_user_created`. This is what limits sign-up to
  `@uwaterloo.ca` (the smoke test checks the function; the hook itself must be switched on in the dashboard).
- **Auth → Email:** a 6-digit OTP email template with the BigBack name.
- **Auth:** turn on leaked-password protection, which applies to the App Review demo account's password.
- **App Review demo account:**
  - add the reviewer email to `signup_allowlist` (school = UW);
  - create the user in Auth with a password;
  - put the credentials in App Store Connect review notes.
