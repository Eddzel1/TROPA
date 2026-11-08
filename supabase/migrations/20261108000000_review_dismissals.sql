-- For Review page (lib/views/review_view.dart): problems found in households and members are
-- computed on each device; a reviewer clearing one stores a row here, one per (record, problem),
-- so every device hides it. Deleting the row (Restore) shows it again. Synced through PowerSync
-- (global bucket in powersync/sync-rules.yaml).
-- Run once in the Supabase SQL editor (or `supabase db push`), then redeploy the sync rules.

create table if not exists public.review_dismissals (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null check (entity_type in ('household', 'member')),
  entity_id text not null,
  flag text not null,
  note text,
  dismissed_by text,
  created_at timestamptz not null default now()
);
create index if not exists review_dismissals_entity_idx on public.review_dismissals (entity_type, entity_id);
-- Cursor column of the backup sync (lib/services/fallback_sync.dart).
create index if not exists review_dismissals_created_at_idx on public.review_dismissals (created_at);

alter table public.review_dismissals enable row level security;
drop policy if exists "Authenticated users can read review dismissals" on public.review_dismissals;
create policy "Authenticated users can read review dismissals" on public.review_dismissals
  for select to authenticated using (true);
drop policy if exists "Authenticated users can clear reviews" on public.review_dismissals;
create policy "Authenticated users can clear reviews" on public.review_dismissals
  for insert to authenticated with check (true);
drop policy if exists "Authenticated users can restore reviews" on public.review_dismissals;
create policy "Authenticated users can restore reviews" on public.review_dismissals
  for delete to authenticated using (true);

-- Restores (deletes) reach devices during backup sync too.
drop trigger if exists log_deleted_record on public.review_dismissals;
create trigger log_deleted_record after delete on public.review_dismissals
  for each row execute function public.log_deleted_record();

alter publication powersync add table public.review_dismissals;
grant select on public.review_dismissals to powersync_role;
