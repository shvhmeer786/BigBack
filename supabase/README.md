# supabase/

The BigBack database: Postgres 17 on Supabase project `big-back` (`iefchnylrxolydtulmgt`, us-east-1).

| Path | What |
|---|---|
| `migrations/` | Every schema change, named `<version>_<name>.sql` to match the applied versions (`supabase migration list`). Applied in order; never edit an applied file, add a new one. |
| `tests/smoke_test.sql` | End-to-end test. Runs as three fake UW students and always rolls back. Success is the error `SMOKE_TEST_PASSED: …`; any other error is a real failure. |
| `types/database.types.ts` | Generated types (`supabase gen types typescript`), for Edge Functions. The iOS app uses its own Swift models. |

## Rules
- **RLS on every table.** A new table ships in the same migration as its policies.
- **System-owned columns** (scores, tiers, school, counts) are protected by guard triggers, not column grants.
- **SECURITY DEFINER functions** use `set search_path = ''`, check `auth.uid()` themselves, and get
  `revoke execute … from public, anon` plus an explicit grant to `authenticated` when the app calls them.
- **Secrets** (service-role key, APNs key, Anthropic API key) live in Supabase secrets, never in this repo.

## Running the smoke test
Paste `tests/smoke_test.sql` into the dashboard SQL editor (or run it with `psql` as `postgres`) and check for
`SMOKE_TEST_PASSED`. It creates and removes its own users and places, and nothing persists.

Design: [docs/architecture/02-database-design.md](../docs/architecture/02-database-design.md) ·
Status and manual steps: [docs/handoff/db-status.md](../docs/handoff/db-status.md)
