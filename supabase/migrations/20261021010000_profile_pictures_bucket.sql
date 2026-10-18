-- Member photos (lib/services/supabase_service.dart uploadProfilePicture). The bucket was never
-- created, so every upload failed and the photo was silently dropped on save.
-- Public, because the app stores and shows the object's public URL; file names are the member's
-- UUID plus a timestamp. Only users who can manage members (or System Admins) can write.
-- Run once in the Supabase SQL editor (or `supabase db push`).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-pictures', 'profile-pictures', true, 2097152, array['image/jpeg', 'image/png'])
on conflict (id) do update set
  public = true,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- security definer so it can read users regardless of users' own RLS.
create or replace function public.can_manage_members()
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
      and (to_jsonb(u.permissions) ? 'system_admin' or to_jsonb(u.permissions) ? 'manage_members')
  );
$$;

drop policy if exists "Member managers can upload profile pictures" on storage.objects;
drop policy if exists "Member managers can replace profile pictures" on storage.objects;
drop policy if exists "Member managers can delete profile pictures" on storage.objects;
create policy "Member managers can upload profile pictures" on storage.objects
  for insert to authenticated with check (bucket_id = 'profile-pictures' and public.can_manage_members());
create policy "Member managers can replace profile pictures" on storage.objects
  for update to authenticated using (bucket_id = 'profile-pictures' and public.can_manage_members());
create policy "Member managers can delete profile pictures" on storage.objects
  for delete to authenticated using (bucket_id = 'profile-pictures' and public.can_manage_members());
