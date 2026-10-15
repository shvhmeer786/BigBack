# Night shift: apply, test and harden the BigBack database

You're continuing work started in another session. The owner has gone to sleep and has
**explicitly authorised autonomous database changes** on the Supabase project below, including
applying migrations, running SQL, fixing issues and pushing to this branch, with no check-ins.
This repo's `.claude/settings.json` pre-approves the Supabase MCP tools for that reason.

- Supabase project: **big-back**, project_id / ref `iefchnylrxolydtulmgt` (us-east-1). It is pre-launch:
  there is **no real user data**.
- Repo / branch: `shvhmeer786/BigBack` @ `claude/ios-app-architecture-vks1tg`. Commit and push to
  this branch only. **No PRs.** Run `git pull --rebase origin claude/ios-app-architecture-vks1tg` before
  every push, because another session is editing `docs/` at the same time.
- Product context: `docs/VISION.md`, `docs/design/01-core-experiences.md` (ranking model, Tonight,
  Let's eat), `docs/design/02-ai-features.md`.

## Already applied (do not re-apply)
| Local file | Applied migration name |
|---|---|
| `supabase/migrations/0001_extensions_types_utils.sql` | `extensions_types_utils` |
| `supabase/migrations/0002_identity_social.sql` | `identity_social` |
| `supabase/migrations/0003_places.sql` | `places` |
| `supabase/migrations/0004_core_tables.sql` | `core_tables` |
| `supabase/migrations/0005_access_rls.sql` | `access_rls` (RLS is on for all 41 public tables) |

## Your tasks, in order

1. **Apply `0006_logic.sql`** with `apply_migration` (name `logic`), passing the file contents exactly.
   - If it fails, the whole migration rolls back. Read the error, fix the SQL **in the file**, and
     re-apply. Repeat until it succeeds.
   - Keep fixes minimal and keep the design intent (see the comments in the file and
     `docs/design/01-core-experiences.md` §C for the scoring model).
2. **Apply `0007_storage_realtime_cron_seed.sql`** (name `storage_realtime_cron_seed`) the same way.
3. **Run the smoke test**: execute `supabase/tests/smoke_test.sql` with `execute_sql`.
   - It always ends in an exception so nothing persists. **Success = an error message starting
     `SMOKE_TEST_PASSED`.** Any other error is a real bug.
   - Fix bugs with a *new* migration file (`0008_fixes.sql`, `0009_...`), never by editing an
     already-applied file. Edit the test only if the test itself is wrong, and say why in the commit.
   - Loop until the test passes.
4. **Run advisors**: `get_advisors` for `security`, then `performance`.
   - Fix every ERROR and WARN that makes sense (e.g. `function_search_path_mutable`, security-definer
     functions callable by anon, missing FK indexes, `auth_rls_initplan`, multiple permissive policies)
     in a new migration (`00NN_advisor_fixes.sql`).
   - Expected/acceptable leftovers: extensions installed in `public`? (they should be in `extensions`;
     fix if not); "leaked password protection" (Auth setting, dashboard only: note it, don't
     change it).
   - Note: trigger functions and `_`-prefixed internal functions should not be executable by
     `anon`/`authenticated`. Revoke where the advisor flags them, but keep EXECUTE for
     `authenticated` on the helpers used inside RLS policies (`can_view_meal`, `can_view_user_content`,
     `is_party_member`, `is_crew_member`, `can_view_plan`, `is_decide_participant`,
     `is_blocked_between`, `is_following`, `try_uuid`, `search_key`, `tier_score`, `tier_band`).
   - Re-run the smoke test after advisor fixes.
5. **Rename local migration files to match the applied versions** so `supabase db push` works later:
   - Call `list_migrations` and rename each `supabase/migrations/NNNN_name.sql` to
     `<version>_<name>.sql`, using the exact version string returned for that name.
   - Keep the contents identical to what was applied.
6. **Generate TypeScript types**: `generate_typescript_types` → save to
   `supabase/types/database.types.ts`.
7. **Write `supabase/README.md`** covering:
   - how migrations are organised, and how to run the smoke test;
   - the list of RPCs with one line each;
   - the storage path conventions;
   - the cron jobs;
   - the manual dashboard steps still needed: enable the **Before User Created** auth hook →
     `public.hook_before_user_created`; email OTP template; leaked-password protection; the APNs/Anthropic
     secrets for Edge Functions later.
8. **Status file**: keep `docs/handoff/db-status.md` updated after each step with what is done, what
   failed and how it was fixed, the advisor results, and anything left for the owner. Commit and push
   after every completed step.

## Rules
- Do **not** touch `docs/architecture/*` or `docs/VISION.md`: the other session owns them. Put
  anything you think the design doc should change into `db-status.md` under "Doc follow-ups".
- Do not delete or recreate the project, pause it, create branches, or change Auth/billing settings.
- Do not add real people's data. Test data only inside the rolled-back smoke test.
- Do not include model identifiers in commits. End commit messages with:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  ```
- If you get permanently blocked (e.g. a tool is denied), write it in `db-status.md`, push, and stop.
