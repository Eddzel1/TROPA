-- Some users rows don't share the Supabase Auth id (they were created outside Supabase Auth).
-- The app already matches those by email; do the same on the server.

-- 1. Permission checks: match the signed-in user by Auth id, or else by the email in their token.
create or replace function public.has_tropa_permission(perm text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users u
    where (u.id = auth.uid() or lower(u.email) = lower(auth.jwt() ->> 'email'))
      and coalesce(u.status, 'active') = 'active'
      and (to_jsonb(u.permissions) ? 'system_admin' or to_jsonb(u.permissions) ? perm)
  );
$$;

-- 2. Auth id for an email, for the admin-users Edge Function (service role only).
create or replace function public.tropa_auth_user_id(p_email text)
returns uuid
language sql
stable
security definer
set search_path = public, auth
as $$
  select id from auth.users where lower(email) = lower(p_email) limit 1;
$$;

revoke all on function public.tropa_auth_user_id(text) from public, anon, authenticated;
grant execute on function public.tropa_auth_user_id(text) to service_role;
