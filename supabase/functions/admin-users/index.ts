// Admin user management for Settings & Administration.
// Creating Auth accounts needs the service-role key, which must never ship in the app.
// Deploy: supabase functions deploy admin-users
//
// Body: { action: 'create', email, password, firstname, lastname, role, permissions }
//     | { action: 'set_password', user_id, password }
//     | { action: 'set_status', user_id, status: 'active' | 'inactive' }

import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

function permissionList(value: unknown): string[] {
  if (Array.isArray(value)) return value.map(String);
  if (typeof value === "string") {
    try {
      const parsed = JSON.parse(value);
      if (Array.isArray(parsed)) return parsed.map(String);
    } catch (_) {
      // Postgres array literal, e.g. {all,view_reports}
      return value.replace(/^{|}$/g, "").split(",").filter(Boolean);
    }
  }
  return [];
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );

  // 1. Identify the caller and require an active profile with 'all' or 'user_management'.
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const { data: caller, error: callerError } = await admin.auth.getUser(token);
  if (callerError || !caller.user) return json({ error: "Not signed in." }, 401);

  const { data: profile } = await admin
    .from("users")
    .select("permissions, status")
    .eq("id", caller.user.id)
    .maybeSingle();
  const perms = permissionList(profile?.permissions);
  if (!profile || (profile.status ?? "active") !== "active" ||
      !(perms.includes("all") || perms.includes("user_management"))) {
    return json({ error: "You do not have permission to manage users." }, 403);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: "Invalid JSON body." }, 400);
  }

  switch (body.action) {
    case "create": {
      const email = String(body.email ?? "").trim().toLowerCase();
      const password = String(body.password ?? "");
      if (!email || password.length < 8) {
        return json({ error: "Email and a password of at least 8 characters are required." }, 400);
      }

      const { data: created, error } = await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      });
      if (error || !created.user) return json({ error: error?.message ?? "Could not create account." }, 400);

      const now = new Date().toISOString();
      const row = {
        id: created.user.id,
        email,
        firstname: String(body.firstname ?? "").trim(),
        lastname: String(body.lastname ?? "").trim(),
        role: String(body.role ?? "user"),
        status: "active",
        permissions: permissionList(body.permissions),
        created_date: now,
        updated_date: now,
      };
      const { data: inserted, error: insertError } = await admin.from("users").insert(row).select().single();
      if (insertError) {
        // Don't leave an Auth account without a profile.
        await admin.auth.admin.deleteUser(created.user.id);
        return json({ error: insertError.message }, 400);
      }
      return json({ user: inserted });
    }

    case "set_password": {
      const userId = String(body.user_id ?? "");
      const password = String(body.password ?? "");
      if (!userId || password.length < 8) {
        return json({ error: "A password of at least 8 characters is required." }, 400);
      }
      const { error } = await admin.auth.admin.updateUserById(userId, { password });
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true });
    }

    case "set_status": {
      const userId = String(body.user_id ?? "");
      const status = body.status === "inactive" ? "inactive" : "active";
      if (!userId) return json({ error: "user_id is required." }, 400);
      if (userId === caller.user.id && status === "inactive") {
        return json({ error: "You cannot deactivate your own account." }, 400);
      }
      const { error } = await admin.auth.admin.updateUserById(userId, {
        ban_duration: status === "inactive" ? "876000h" : "none",
      });
      if (error) return json({ error: error.message }, 400);
      const { error: updateError } = await admin
        .from("users")
        .update({ status, updated_date: new Date().toISOString() })
        .eq("id", userId);
      if (updateError) return json({ error: updateError.message }, 400);
      return json({ ok: true });
    }

    default:
      return json({ error: "Unknown action." }, 400);
  }
});
