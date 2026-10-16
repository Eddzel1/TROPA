-- Settings & Administration: officers sync and admin write access.
-- Run once in the Supabase SQL editor (or `supabase db push`), then redeploy
-- powersync/sync-rules.yaml from the PowerSync dashboard.
--
-- Devices upload queued changes with the signed-in user's JWT; a change rejected by RLS is
-- discarded by the app (see lib/data/supabase_connector.dart), so admins need these policies.
-- Check existing policies first (select * from pg_policies where tablename in
-- ('locations','puroks','officers','users')); if a broader policy already covers a case,
-- the matching block below is harmless but can be skipped.

-- 1. Stream officers to devices.
alter publication powersync add table officers;

-- 2. True when the signed-in user's profile grants 'all' or 'user_management'.
--    security definer so it can read users regardless of users' own RLS.
--    users.permissions may be text[] or jsonb; to_jsonb handles both.
create or replace function public.is_tropa_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users u
    where u.id = auth.uid()
      and coalesce(u.status, 'active') = 'active'
      and (to_jsonb(u.permissions) ? 'all' or to_jsonb(u.permissions) ? 'user_management')
  );
$$;

-- 3. RLS policies.
alter table officers enable row level security;

do $$
declare
  t text;
begin
  foreach t in array array['locations', 'puroks', 'officers'] loop
    if not exists (select 1 from pg_policies where tablename = t and policyname = 'tropa_admin_insert') then
      execute format('create policy tropa_admin_insert on public.%I for insert to authenticated with check (public.is_tropa_admin())', t);
    end if;
    if not exists (select 1 from pg_policies where tablename = t and policyname = 'tropa_admin_update') then
      execute format('create policy tropa_admin_update on public.%I for update to authenticated using (public.is_tropa_admin()) with check (public.is_tropa_admin())', t);
    end if;
    if not exists (select 1 from pg_policies where tablename = t and policyname = 'tropa_admin_delete') then
      execute format('create policy tropa_admin_delete on public.%I for delete to authenticated using (public.is_tropa_admin())', t);
    end if;
  end loop;

  if not exists (select 1 from pg_policies where tablename = 'officers' and policyname = 'officers_select_authenticated') then
    create policy officers_select_authenticated on public.officers for select to authenticated using (true);
  end if;

  if not exists (select 1 from pg_policies where tablename = 'users' and policyname = 'tropa_admin_update') then
    create policy tropa_admin_update on public.users for update to authenticated
      using (public.is_tropa_admin()) with check (public.is_tropa_admin());
  end if;
end $$;

-- 4. Keep officers.updated_at current on server-side edits.
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists officers_touch_updated_at on officers;
create trigger officers_touch_updated_at before update on officers
  for each row execute function public.touch_updated_at();
