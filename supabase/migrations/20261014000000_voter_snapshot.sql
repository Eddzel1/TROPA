-- Offline voter registry: devices install a compressed snapshot of the target LGUs from Storage
-- (lib/services/voter_snapshot.dart), and voter flags sync through PowerSync in their own table.
-- Run once in the Supabase SQL editor.

-- 1. Voter flags: the only edits made to voters. Synced through PowerSync.
create table if not exists public.voter_flags (
  id uuid primary key default gen_random_uuid(),
  voter_id bigint not null references public.voters (id) on delete cascade,
  reason text,
  flagged_by text,
  created_at timestamptz not null default now()
);
create index if not exists voter_flags_voter_id_idx on public.voter_flags (voter_id);

alter table public.voter_flags enable row level security;
create policy "Authenticated users can read voter flags" on public.voter_flags
  for select to authenticated using (true);
create policy "Authenticated users can flag voters" on public.voter_flags
  for insert to authenticated with check (true);

-- Carry over flags already set on voters.
insert into public.voter_flags (voter_id, reason)
select v.id, v.flag_reason
from public.voters v
where v.is_flagged
  and not exists (select 1 from public.voter_flags f where f.voter_id = v.id);

-- Keep voters.is_flagged / flag_reason in step, for online searches of other LGUs.
create or replace function public.apply_voter_flag() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update public.voters set is_flagged = true, flag_reason = new.reason where id = new.voter_id;
  return new;
end;
$$;
drop trigger if exists voter_flags_apply on public.voter_flags;
create trigger voter_flags_apply after insert on public.voter_flags
  for each row execute function public.apply_voter_flag();

alter publication powersync add table public.voter_flags;
grant select on public.voter_flags to powersync_role;

-- 2. Private Storage bucket for the snapshot file and its manifest.
insert into storage.buckets (id, name, public)
values ('voter-snapshots', 'voter-snapshots', false)
on conflict (id) do nothing;

-- Admin check: an active profile granting 'system_admin' or 'user_management' (same as 20261015000000_admin_settings.sql).
create or replace function public.is_tropa_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.users u
    where u.id = auth.uid()
      and coalesce(u.status, 'active') = 'active'
      and (to_jsonb(u.permissions) ? 'system_admin' or to_jsonb(u.permissions) ? 'user_management')
  );
$$;

create policy "Authenticated users can download voter snapshots" on storage.objects
  for select to authenticated using (bucket_id = 'voter-snapshots');
create policy "Admins can upload voter snapshots" on storage.objects
  for insert to authenticated with check (bucket_id = 'voter-snapshots' and public.is_tropa_admin());
create policy "Admins can replace voter snapshots" on storage.objects
  for update to authenticated using (bucket_id = 'voter-snapshots' and public.is_tropa_admin());
create policy "Admins can delete old voter snapshots" on storage.objects
  for delete to authenticated using (bucket_id = 'voter-snapshots' and public.is_tropa_admin());
