-- Starter databases for new devices (lib/services/device_seed_io.dart): an admin's synced desktop
-- publishes a compressed copy of its local database here, and new devices download it on first
-- sign-in instead of a full PowerSync sync. Run once in the Supabase SQL editor, after
-- 20261014000000_voter_snapshot.sql (which defines public.is_tropa_admin()).

insert into storage.buckets (id, name, public)
values ('device-seeds', 'device-seeds', false)
on conflict (id) do nothing;

create policy "Authenticated users can download starter databases" on storage.objects
  for select to authenticated using (bucket_id = 'device-seeds');
create policy "Admins can upload starter databases" on storage.objects
  for insert to authenticated with check (bucket_id = 'device-seeds' and public.is_tropa_admin());
create policy "Admins can replace starter databases" on storage.objects
  for update to authenticated using (bucket_id = 'device-seeds' and public.is_tropa_admin());
create policy "Admins can delete old starter databases" on storage.objects
  for delete to authenticated using (bucket_id = 'device-seeds' and public.is_tropa_admin());
