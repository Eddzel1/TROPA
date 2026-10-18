-- Split 'user_management' into manage_users, manage_locations, publish_offline_data,
-- view_audit_logs and form_tracking. Run after 20261018010000_system_admin_and_delete.sql
-- (which defines public.has_tropa_permission) and after the matching app build is installed.

-- 1. Everyone who had user_management gets all five new permissions.
do $$
declare
  col_type text;
  new_keys text[] := array['manage_users', 'manage_locations', 'publish_offline_data', 'view_audit_logs', 'form_tracking'];
begin
  select data_type into col_type from information_schema.columns
  where table_schema = 'public' and table_name = 'users' and column_name = 'permissions';

  if col_type = 'jsonb' then
    update public.users
      set permissions = (permissions - 'user_management') || to_jsonb(new_keys)
      where permissions ? 'user_management';
  elsif col_type = 'ARRAY' then
    update public.users
      set permissions = array_remove(permissions, 'user_management') || new_keys
      where 'user_management' = any(permissions);
  else
    raise exception 'users.permissions has unexpected type %; update this migration first.', col_type;
  end if;
end $$;

-- 2. Locations, puroks and officers: manage_locations.
do $$
declare
  t text;
begin
  foreach t in array array['locations', 'puroks', 'officers'] loop
    execute format('drop policy if exists tropa_admin_insert on public.%I', t);
    execute format('drop policy if exists tropa_admin_update on public.%I', t);
    execute format('drop policy if exists tropa_admin_delete on public.%I', t);
    execute format('create policy tropa_admin_insert on public.%I for insert to authenticated '
      'with check (public.has_tropa_permission(''manage_locations''))', t);
    execute format('create policy tropa_admin_update on public.%I for update to authenticated '
      'using (public.has_tropa_permission(''manage_locations'')) with check (public.has_tropa_permission(''manage_locations''))', t);
    execute format('create policy tropa_admin_delete on public.%I for delete to authenticated '
      'using (public.has_tropa_permission(''manage_locations''))', t);
  end loop;
end $$;

-- 3. Editing users: manage_users.
drop policy if exists tropa_admin_update on public.users;
create policy tropa_admin_update on public.users for update to authenticated
  using (public.has_tropa_permission('manage_users')) with check (public.has_tropa_permission('manage_users'));

-- 4. Publishing starter databases and voter snapshots: publish_offline_data.
drop policy if exists "Admins can upload starter databases" on storage.objects;
drop policy if exists "Admins can replace starter databases" on storage.objects;
drop policy if exists "Admins can delete old starter databases" on storage.objects;
drop policy if exists "Admins can upload voter snapshots" on storage.objects;
drop policy if exists "Admins can replace voter snapshots" on storage.objects;
drop policy if exists "Admins can delete old voter snapshots" on storage.objects;

create policy "Admins can upload starter databases" on storage.objects
  for insert to authenticated with check (bucket_id = 'device-seeds' and public.has_tropa_permission('publish_offline_data'));
create policy "Admins can replace starter databases" on storage.objects
  for update to authenticated using (bucket_id = 'device-seeds' and public.has_tropa_permission('publish_offline_data'));
create policy "Admins can delete old starter databases" on storage.objects
  for delete to authenticated using (bucket_id = 'device-seeds' and public.has_tropa_permission('publish_offline_data'));
create policy "Admins can upload voter snapshots" on storage.objects
  for insert to authenticated with check (bucket_id = 'voter-snapshots' and public.has_tropa_permission('publish_offline_data'));
create policy "Admins can replace voter snapshots" on storage.objects
  for update to authenticated using (bucket_id = 'voter-snapshots' and public.has_tropa_permission('publish_offline_data'));
create policy "Admins can delete old voter snapshots" on storage.objects
  for delete to authenticated using (bucket_id = 'voter-snapshots' and public.has_tropa_permission('publish_offline_data'));

-- 5. Nothing uses is_tropa_admin() any more. Without cascade, this fails if some policy still does,
--    which is the signal to move that policy to has_tropa_permission first.
drop function if exists public.is_tropa_admin();
