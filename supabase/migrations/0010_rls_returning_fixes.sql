-- BigBack · 0010 · NOT YET APPLIED (approval was declined on 2026-10-15; apply next).
-- SELECT policies must not look a row up by its own id: during INSERT ... RETURNING the new row is
-- not yet visible to that lookup, so the client's insert().select() fails with
-- "new row violates row-level security policy". Found by supabase/tests/smoke_test.sql.
-- Uses ALTER POLICY (the Supabase MCP holds DROP statements for a confirmation that never shows).

alter policy "meals visible per visibility model" on public.meals
  using (
    user_id = (select auth.uid())
    or public.is_party_member(party_id, (select auth.uid()))
    or (status = 'posted' and visibility = 'followers' and public.can_view_user_content(user_id))
  );

alter policy "plan visible to host, guests, crew" on public.plans
  using (
    host_id = (select auth.uid())
    or exists (select 1 from public.plan_guests g where g.plan_id = id and g.user_id = (select auth.uid()))
    or (crew_id is not null and public.is_crew_member(crew_id, (select auth.uid())))
  );

alter policy "crew members see the crew" on public.crews
  using (owner_id = (select auth.uid()) or public.is_crew_member(id));

alter policy "participants see the session" on public.decide_sessions
  using (host_id = (select auth.uid()) or public.is_decide_participant(id));
