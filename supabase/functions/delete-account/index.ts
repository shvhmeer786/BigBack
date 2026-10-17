// BigBack · delete-account
// Settings → Delete account (App Review guideline 5.1.1(v)). Deletes the caller's files from every Storage
// bucket, then the auth user. Every table references the user with ON DELETE CASCADE or SET NULL, so all of
// their meals, rankings, follows, comments and notifications go with it.
//
// POST /functions/v1/delete-account
//   Authorization: Bearer <the user's access token>
//   Body: {"confirm": "DELETE"}
// The function checks the token itself (so the gateway's verify_jwt is off).
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

// Every bucket keeps a user's files under "<user id>/…".
const BUCKETS = ["meal-media", "reactions", "audio", "avatars"];

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

function adminKey(): string {
  const keys = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (keys) {
    const key = JSON.parse(keys)["default"];
    if (key) return key;
  }
  const legacy = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!legacy) throw new Error("no secret key available");
  return legacy;
}

// Storage lists one folder level at a time; folders come back with id === null.
async function listAll(admin: SupabaseClient, bucket: string, prefix: string): Promise<string[]> {
  const paths: string[] = [];
  const pageSize = 1000;
  for (let offset = 0; ; offset += pageSize) {
    const { data, error } = await admin.storage.from(bucket).list(prefix, { limit: pageSize, offset });
    if (error) throw error;
    for (const item of data ?? []) {
      const path = `${prefix}/${item.name}`;
      if (item.id === null) paths.push(...(await listAll(admin, bucket, path)));
      else paths.push(path);
    }
    if (!data || data.length < pageSize) break;
  }
  return paths;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return json(401, { error: "not_authenticated" });

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, adminKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: userData, error: userError } = await admin.auth.getUser(token);
  const user = userData?.user;
  if (userError || !user) return json(401, { error: "not_authenticated" });

  let body: { confirm?: string } = {};
  try {
    body = await req.json();
  } catch {
    // no body
  }
  if (body.confirm !== "DELETE") return json(400, { error: "confirmation_required" });

  try {
    for (const bucket of BUCKETS) {
      const paths = await listAll(admin, bucket, user.id);
      for (let i = 0; i < paths.length; i += 100) {
        const { error } = await admin.storage.from(bucket).remove(paths.slice(i, i + 100));
        if (error) throw error;
      }
    }
    const { error } = await admin.auth.admin.deleteUser(user.id);
    if (error) throw error;
  } catch (e) {
    console.error("delete-account failed", user.id, e instanceof Error ? e.message : String(e));
    return json(500, { error: "delete_failed" });
  }

  console.log("account deleted", user.id);
  return json(200, { deleted: true });
});
