-- Fixes "new row violates row-level security policy" on member photo uploads.
-- 20261021010000_profile_pictures_bucket.sql matched the signed-in user by Auth id only, which
-- rejects users rows matched by email (see 20261018030000_match_profile_by_email.sql). Use the
-- shared has_tropa_permission() check instead.
-- Run once in the Supabase SQL editor (or `supabase db push`).

drop policy if exists "Member managers can upload profile pictures" on storage.objects;
drop policy if exists "Member managers can replace profile pictures" on storage.objects;
drop policy if exists "Member managers can delete profile pictures" on storage.objects;
create policy "Member managers can upload profile pictures" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'profile-pictures' and public.has_tropa_permission('manage_members'));
create policy "Member managers can replace profile pictures" on storage.objects
  for update to authenticated
  using (bucket_id = 'profile-pictures' and public.has_tropa_permission('manage_members'));
create policy "Member managers can delete profile pictures" on storage.objects
  for delete to authenticated
  using (bucket_id = 'profile-pictures' and public.has_tropa_permission('manage_members'));

drop function if exists public.can_manage_members();
