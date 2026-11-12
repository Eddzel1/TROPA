-- How collected dues are split into funds, set in Settings > Dues Rate & Funds.
-- Like dues_rates, a split applies from its effective month onward: each payment is divided with
-- the split in force on its payment date, so changing the split never rewrites past reports. The
-- earliest row also covers payments before it.
-- Run once in the Supabase SQL editor, then add dues_allocations to the global bucket of the sync
-- rules (powersync/sync-rules.yaml) and redeploy them.

create table if not exists public.dues_allocations (
  id uuid primary key default gen_random_uuid(),
  effective_month text not null unique check (effective_month ~ '^\d{4}-(0[1-9]|1[0-2])$'),
  mortuary numeric(5, 2) not null check (mortuary >= 0),
  livelihood numeric(5, 2) not null check (livelihood >= 0),
  purok_operations numeric(5, 2) not null check (purok_operations >= 0),
  federation_operations numeric(5, 2) not null check (federation_operations >= 0),
  created_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint dues_allocations_total_check
    check (mortuary + livelihood + purok_operations + federation_operations = 100)
);

alter publication powersync add table dues_allocations;

drop trigger if exists touch_updated on public.dues_allocations;
create trigger touch_updated before insert or update on public.dues_allocations
  for each row execute function public.touch_updated('updated_at');
drop trigger if exists log_deleted_record on public.dues_allocations;
create trigger log_deleted_record after delete on public.dues_allocations
  for each row execute function public.log_deleted_record();
create index if not exists dues_allocations_updated_at_idx on public.dues_allocations (updated_at);

-- Everyone signed in reads the split (dues collectors and treasurers need it for the ledger); only
-- admins who manage users change it, as with dues_rates.
alter table public.dues_allocations enable row level security;
drop policy if exists dues_allocations_select on public.dues_allocations;
create policy dues_allocations_select on public.dues_allocations for select to authenticated using (true);
drop policy if exists dues_allocations_insert on public.dues_allocations;
create policy dues_allocations_insert on public.dues_allocations for insert to authenticated
  with check (public.has_tropa_permission('manage_users'));
drop policy if exists dues_allocations_update on public.dues_allocations;
create policy dues_allocations_update on public.dues_allocations for update to authenticated
  using (public.has_tropa_permission('manage_users')) with check (public.has_tropa_permission('manage_users'));
drop policy if exists dues_allocations_delete on public.dues_allocations;
create policy dues_allocations_delete on public.dues_allocations for delete to authenticated
  using (public.has_tropa_permission('manage_users'));

-- The agreed split: 60% Mortuary, 30% Livelihood, 7% Purok Operations, 3% TROPA Federation
-- Operations, covering every payment so far.
insert into public.dues_allocations (effective_month, mortuary, livelihood, purok_operations, federation_operations, created_by)
values ('2000-01', 60, 30, 7, 3, 'System')
on conflict (effective_month) do nothing;
