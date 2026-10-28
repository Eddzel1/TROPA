-- "View" permissions are read-only: adding or editing households and members needs a permission
-- whose screens write to that table. Run after 20261018030000_match_profile_by_email.sql.

-- 1. True when the signed-in user's active profile grants 'system_admin' or any of [perms].
create or replace function public.has_any_tropa_permission(perms text[])
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
      and (to_jsonb(u.permissions) ? 'system_admin' or to_jsonb(u.permissions) ?| perms)
  );
$$;

-- 2. Restrictive insert/update policies. Each list holds every permission whose screens write to
--    the table:
--    households:     manage_households (edit), manage_members (member form creates households;
--                    transfers update totals and leader), manage_locations (purok rename).
--    family_members: manage_members (add/edit/transfer), manage_households (household edits update
--                    members), manage_locations (purok rename), dues_collection (membership dates).
--    A refused change is undone on the device at its next sync.
do $$
declare
  t text;
  perms text;
begin
  foreach t in array array['households', 'family_members'] loop
    perms := case t
      when 'households' then '{manage_households,manage_members,manage_locations}'
      else '{manage_members,manage_households,manage_locations,dues_collection}'
    end;

    if not exists (select 1 from pg_policies where tablename = t and policyname = 'tropa_write_records_insert') then
      execute format(
        'create policy tropa_write_records_insert on public.%I as restrictive for insert to authenticated '
        'with check (public.has_any_tropa_permission(%L::text[]))', t, perms);
    end if;
    if not exists (select 1 from pg_policies where tablename = t and policyname = 'tropa_write_records_update') then
      execute format(
        'create policy tropa_write_records_update on public.%I as restrictive for update to authenticated '
        'using (public.has_any_tropa_permission(%L::text[])) with check (public.has_any_tropa_permission(%L::text[]))',
        t, perms, perms);
    end if;
    if not (select relrowsecurity from pg_class where oid = format('public.%I', t)::regclass) then
      raise warning 'Row level security is off on %, so these write policies have no effect there.', t;
    end if;
  end loop;
end $$;
