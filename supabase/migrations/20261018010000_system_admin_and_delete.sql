-- System admin rename and the 'delete_records' permission.
-- Run in the Supabase SQL editor after the matching app build is installed.

-- 1. Rename the full-access key 'all' to 'system_admin' and make edzzel@gmail.com the system admin.
--    users.permissions may be text[] or jsonb; branch on the actual type.
do $$
declare
  col_type text;
begin
  select data_type into col_type from information_schema.columns
  where table_schema = 'public' and table_name = 'users' and column_name = 'permissions';

  if col_type = 'jsonb' then
    update public.users
      set permissions = (permissions - 'all') || '["system_admin"]'::jsonb
      where permissions ? 'all';
    update public.users
      set permissions = '["system_admin"]'::jsonb, status = 'active'
      where lower(email) = 'edzzel@gmail.com';
  elsif col_type = 'ARRAY' then
    update public.users
      set permissions = array_replace(permissions, 'all', 'system_admin')
      where 'all' = any(permissions);
    update public.users
      set permissions = '{system_admin}', status = 'active'
      where lower(email) = 'edzzel@gmail.com';
  else
    raise exception 'users.permissions has unexpected type %; update this migration first.', col_type;
  end if;

  if not exists (select 1 from public.users where lower(email) = 'edzzel@gmail.com') then
    raise warning 'No users row for edzzel@gmail.com, so no system admin was set.';
  end if;
end $$;

-- 2. True when the signed-in user's active profile grants 'system_admin' or [perm].
--    security definer so it can read users regardless of users' own RLS.
create or replace function public.has_tropa_permission(perm text)
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
      and (to_jsonb(u.permissions) ? 'system_admin' or to_jsonb(u.permissions) ? perm)
  );
$$;

create or replace function public.is_tropa_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_tropa_permission('user_management');
$$;

-- 3. Deleting records needs 'delete_records'. Restrictive policies are ANDed with the existing
--    permissive ones, so this only narrows who can delete. A refused delete removes no rows, and
--    the device gets the row back on its next sync.
do $$
declare
  t text;
begin
  foreach t in array array['households', 'family_members', 'dues_payments', 'form_tracking'] loop
    if not exists (select 1 from pg_policies where tablename = t and policyname = 'tropa_delete_records') then
      execute format(
        'create policy tropa_delete_records on public.%I as restrictive for delete to authenticated '
        'using (public.has_tropa_permission(''delete_records''))', t);
    end if;
    if not (select relrowsecurity from pg_class where oid = format('public.%I', t)::regclass) then
      raise warning 'Row level security is off on %, so the delete policy has no effect there.', t;
    end if;
  end loop;
end $$;
