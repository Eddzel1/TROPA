-- Dues & Ledger: barangay-scoped collectors, receipts, void instead of delete, and the monthly rate.
-- Run once in the Supabase SQL editor (or `supabase db push`), then redeploy
-- powersync/sync-rules.yaml from the PowerSync dashboard.

-- 1. Which barangays (locations.id) a user collects dues for. Empty means none, except for
--    System Admins and users with manage_users, who may collect anywhere.
alter table public.users add column if not exists dues_barangays text[] not null default '{}';

-- 2. A household payment writes one row per member, all sharing receipt_id. Voided rows stay for
--    the audit trail and no longer count toward a member's paid months.
alter table public.dues_payments add column if not exists receipt_id text;
alter table public.dues_payments add column if not exists void_reason text;
create index if not exists dues_payments_member_status_idx on public.dues_payments (member_id, status);
create index if not exists dues_payments_receipt_idx on public.dues_payments (receipt_id);

-- 3. One rate for everyone: the rate for a month is the row with the latest effective_month on or
--    before it. The earliest row also covers months before it.
create table if not exists public.dues_rates (
  id uuid primary key default gen_random_uuid(),
  amount numeric(10, 2) not null check (amount >= 0),
  effective_month text not null unique check (effective_month ~ '^\d{4}-(0[1-9]|1[0-2])$'),
  created_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter publication powersync add table dues_rates;

drop trigger if exists touch_updated on public.dues_rates;
create trigger touch_updated before insert or update on public.dues_rates
  for each row execute function public.touch_updated('updated_at');
drop trigger if exists log_deleted_record on public.dues_rates;
create trigger log_deleted_record after delete on public.dues_rates
  for each row execute function public.log_deleted_record();
create index if not exists dues_rates_updated_at_idx on public.dues_rates (updated_at);

alter table public.dues_rates enable row level security;
drop policy if exists dues_rates_select on public.dues_rates;
create policy dues_rates_select on public.dues_rates for select to authenticated using (true);
drop policy if exists dues_rates_insert on public.dues_rates;
create policy dues_rates_insert on public.dues_rates for insert to authenticated
  with check (public.has_tropa_permission('manage_users'));
drop policy if exists dues_rates_update on public.dues_rates;
create policy dues_rates_update on public.dues_rates for update to authenticated
  using (public.has_tropa_permission('manage_users')) with check (public.has_tropa_permission('manage_users'));
drop policy if exists dues_rates_delete on public.dues_rates;
create policy dues_rates_delete on public.dues_rates for delete to authenticated
  using (public.has_tropa_permission('manage_users'));

-- 4. True when the signed-in user may record dues for [member]: they hold dues_collection and the
--    member's barangay is one of theirs (or they are a System Admin, or a manage_users admin with
--    no barangays set). security definer so it can read users and locations regardless of RLS.
create or replace function public.can_collect_dues_for(member text)
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
      and (
        to_jsonb(u.permissions) ? 'system_admin'
        or (
          to_jsonb(u.permissions) ? 'dues_collection'
          and (
            (coalesce(cardinality(u.dues_barangays), 0) = 0 and to_jsonb(u.permissions) ? 'manage_users')
            or exists (
              select 1
              from public.family_members m
              join public.locations l
                on upper(trim(coalesce(l.lgu, ''))) = upper(trim(coalesce(m.lgu, '')))
               and upper(trim(coalesce(l.barangay, ''))) = upper(trim(coalesce(m.barangay, '')))
              where m.id::text = member
                and l.id::text = any (u.dues_barangays)
            )
          )
        )
      )
  );
$$;

-- 5. Recording dues: a restrictive policy is ANDed with the existing permissive ones, so it only
--    narrows who can insert. A refused upload is discarded and the device drops the row.
drop policy if exists tropa_dues_insert on public.dues_payments;
create policy tropa_dues_insert on public.dues_payments as restrictive for insert to authenticated
  with check (public.can_collect_dues_for(member_id::text));

-- 6. Changing what a payment covers (or voiding it) needs the same check. A trigger rather than an
--    update policy, because moving a member to another household rewrites household_id on their
--    payments and must keep working for encoders without dues_collection.
create or replace function public.check_dues_payment_update() returns trigger
language plpgsql as $$
begin
  if auth.uid() is not null
     and (new.member_id, new.amount, new.payment_month, new.months_covered, new.status, new.void_reason)
         is distinct from
         (old.member_id, old.amount, old.payment_month, old.months_covered, old.status, old.void_reason)
     and not public.can_collect_dues_for(old.member_id::text) then
    raise exception 'Not allowed to change dues for this member' using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists check_dues_payment_update on public.dues_payments;
create trigger check_dues_payment_update before update on public.dues_payments
  for each row execute function public.check_dues_payment_update();
