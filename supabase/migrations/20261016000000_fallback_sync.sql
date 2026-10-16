-- Backup sync (lib/services/fallback_sync.dart): when PowerSync is unreachable but Supabase works,
-- devices poll Supabase for rows changed or deleted since their last sync. Run once in the
-- Supabase SQL editor.

-- 1. Server-set "last updated" timestamps, so polling never depends on a device's clock.
create or replace function public.touch_updated() returns trigger
language plpgsql as $$
begin
  -- The column name is passed as the trigger argument (updated_date or updated_at).
  new := jsonb_populate_record(new, jsonb_build_object(tg_argv[0], now()));
  return new;
end;
$$;

drop trigger if exists touch_updated on public.households;
create trigger touch_updated before insert or update on public.households
  for each row execute function public.touch_updated('updated_date');
drop trigger if exists touch_updated on public.family_members;
create trigger touch_updated before insert or update on public.family_members
  for each row execute function public.touch_updated('updated_date');
drop trigger if exists touch_updated on public.dues_payments;
create trigger touch_updated before insert or update on public.dues_payments
  for each row execute function public.touch_updated('updated_date');
drop trigger if exists touch_updated on public.users;
create trigger touch_updated before insert or update on public.users
  for each row execute function public.touch_updated('updated_date');
drop trigger if exists touch_updated on public.form_tracking;
create trigger touch_updated before insert or update on public.form_tracking
  for each row execute function public.touch_updated('updated_at');
drop trigger if exists touch_updated on public.officers;
create trigger touch_updated before insert or update on public.officers
  for each row execute function public.touch_updated('updated_at');

create index if not exists households_updated_date_idx on public.households (updated_date);
create index if not exists family_members_updated_date_idx on public.family_members (updated_date);
create index if not exists dues_payments_updated_date_idx on public.dues_payments (updated_date);
create index if not exists users_updated_date_idx on public.users (updated_date);
create index if not exists form_tracking_updated_at_idx on public.form_tracking (updated_at);
create index if not exists officers_updated_at_idx on public.officers (updated_at);
create index if not exists voter_flags_created_at_idx on public.voter_flags (created_at);

-- 2. Deletion log: deleted rows can't be found by "updated since", so record them here.
create table if not exists public.deleted_records (
  id bigserial primary key,
  table_name text not null,
  record_id text not null,
  deleted_at timestamptz not null default now()
);
create index if not exists deleted_records_deleted_at_idx on public.deleted_records (deleted_at);

alter table public.deleted_records enable row level security;
create policy "Authenticated users can read the deletion log" on public.deleted_records
  for select to authenticated using (true);

create or replace function public.log_deleted_record() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.deleted_records (table_name, record_id) values (tg_table_name, old.id::text);
  return old;
end;
$$;

drop trigger if exists log_deleted_record on public.households;
create trigger log_deleted_record after delete on public.households
  for each row execute function public.log_deleted_record();
drop trigger if exists log_deleted_record on public.family_members;
create trigger log_deleted_record after delete on public.family_members
  for each row execute function public.log_deleted_record();
drop trigger if exists log_deleted_record on public.dues_payments;
create trigger log_deleted_record after delete on public.dues_payments
  for each row execute function public.log_deleted_record();
drop trigger if exists log_deleted_record on public.form_tracking;
create trigger log_deleted_record after delete on public.form_tracking
  for each row execute function public.log_deleted_record();
drop trigger if exists log_deleted_record on public.officers;
create trigger log_deleted_record after delete on public.officers
  for each row execute function public.log_deleted_record();
drop trigger if exists log_deleted_record on public.users;
create trigger log_deleted_record after delete on public.users
  for each row execute function public.log_deleted_record();
drop trigger if exists log_deleted_record on public.voter_flags;
create trigger log_deleted_record after delete on public.voter_flags
  for each row execute function public.log_deleted_record();
drop trigger if exists log_deleted_record on public.locations;
create trigger log_deleted_record after delete on public.locations
  for each row execute function public.log_deleted_record();
drop trigger if exists log_deleted_record on public.puroks;
create trigger log_deleted_record after delete on public.puroks
  for each row execute function public.log_deleted_record();

-- Optional, run occasionally: the log only needs to cover the longest expected PowerSync outage.
-- delete from public.deleted_records where deleted_at < now() - interval '30 days';
