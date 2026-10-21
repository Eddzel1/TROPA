-- 1. Setting a barangay's membership month on the server (one request, nothing queued on devices).
-- 2. Own-barangay sync: users with "Sync only assigned barangays" get only their barangays'
--    households, members and dues payments.
--
-- Run once in the Supabase SQL editor (or `supabase db push`), then deploy
-- powersync/sync-rules.yaml from the PowerSync dashboard (validate it there first).
--
-- Checks after running (SQL editor runs as postgres, so the RPC check needs a signed-in user):
--   select count(*) filter (where sync_key is null) from family_members;   -- expect 0
--   select * from user_sync_scopes order by email;                        -- one row per user/barangay
--   (from the app) Set month for barangay -> returns the member count, queue stays empty.

-- ---------------------------------------------------------------------------------------------
-- A. Who may collect dues in a barangay: same rule as can_collect_dues_for, by lgu + barangay.
-- ---------------------------------------------------------------------------------------------
create or replace function public.can_collect_dues_in(p_lgu text, p_barangay text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users u
    where (u.id::text = auth.uid()::text or lower(u.email) = lower(auth.jwt() ->> 'email'))
      and coalesce(u.status, 'active') = 'active'
      and (
        to_jsonb(u.permissions) ? 'system_admin'
        or (
          to_jsonb(u.permissions) ? 'dues_collection'
          and (
            (coalesce(cardinality(u.dues_barangays), 0) = 0 and to_jsonb(u.permissions) ? 'manage_users')
            or exists (
              select 1 from public.locations l
              where l.id::text = any (u.dues_barangays)
                and upper(trim(coalesce(l.lgu, ''))) = upper(trim(coalesce(p_lgu, '')))
                and upper(trim(coalesce(l.barangay, ''))) = upper(trim(coalesce(p_barangay, '')))
            )
          )
        )
      )
  );
$$;

-- Sets every member registered in the barangay to the 1st of p_month (YYYY-MM), replacing their
-- current membership date. Returns how many members changed. Changed rows reach devices by sync.
create or replace function public.set_barangay_membership_month(p_lgu text, p_barangay text, p_month text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
begin
  if p_month !~ '^\d{4}-(0[1-9]|1[0-2])$' then
    raise exception 'Month must look like 2026-02' using errcode = '22023';
  end if;
  if not public.can_collect_dues_in(p_lgu, p_barangay) then
    raise exception 'Not allowed to set membership months in %', p_barangay using errcode = '42501';
  end if;

  update public.family_members
     set membership_date = (p_month || '-01')::date
   where upper(trim(coalesce(lgu, ''))) = upper(trim(coalesce(p_lgu, '')))
     and upper(trim(coalesce(barangay, ''))) = upper(trim(coalesce(p_barangay, '')))
     and membership_date::text is distinct from p_month || '-01';
  get diagnostics changed = row_count;

  if changed > 0 then
    insert into public.activity_logs (id, user_id, user_name, action, entity_type, entity_id, details, created_at)
    values (
      gen_random_uuid(), auth.uid(), coalesce(auth.jwt() ->> 'email', 'System'), 'UPDATE_MEMBERSHIP_DATE', 'Barangay', null,
      jsonb_build_object('lgu', upper(trim(p_lgu)), 'barangay', upper(trim(p_barangay)), 'to', p_month || '-01', 'members', changed),
      now()
    );
  end if;
  return changed;
end;
$$;

revoke all on function public.set_barangay_membership_month(text, text, text) from public, anon;
grant execute on function public.set_barangay_membership_month(text, text, text) to authenticated;

-- ---------------------------------------------------------------------------------------------
-- B. Own-barangay sync.
-- ---------------------------------------------------------------------------------------------
alter table public.users add column if not exists sync_assigned_only boolean not null default false;

-- B1. sync_key = 'LGU|BARANGAY' (upper-cased, trimmed) on the three per-barangay tables, so sync
--     rules can match with a plain `sync_key = bucket.barangay_key`. Kept by triggers; whatever a
--     device uploads for it is overwritten.
alter table public.households add column if not exists sync_key text;
alter table public.family_members add column if not exists sync_key text;
alter table public.dues_payments add column if not exists sync_key text;

create or replace function public.set_area_sync_key() returns trigger
language plpgsql as $$
begin
  new.sync_key := upper(trim(coalesce(new.lgu, ''))) || '|' || upper(trim(coalesce(new.barangay, '')));
  return new;
end;
$$;

drop trigger if exists set_sync_key on public.households;
create trigger set_sync_key before insert or update on public.households
  for each row execute function public.set_area_sync_key();
drop trigger if exists set_sync_key on public.family_members;
create trigger set_sync_key before insert or update on public.family_members
  for each row execute function public.set_area_sync_key();

-- A payment follows its member's barangay.
create or replace function public.set_payment_sync_key() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  select m.sync_key into new.sync_key from public.family_members m where m.id::text = new.member_id::text;
  return new;
end;
$$;

drop trigger if exists set_sync_key on public.dues_payments;
create trigger set_sync_key before insert or update of member_id on public.dues_payments
  for each row execute function public.set_payment_sync_key();

-- When a member moves to another barangay, their payments move with them.
create or replace function public.move_member_payments_sync_key() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.sync_key is distinct from old.sync_key then
    update public.dues_payments set sync_key = new.sync_key where member_id::text = new.id::text;
  end if;
  return null;
end;
$$;

drop trigger if exists move_payments_sync_key on public.family_members;
create trigger move_payments_sync_key after update of lgu, barangay on public.family_members
  for each row execute function public.move_member_payments_sync_key();

-- Backfill (rows already matching are left alone to avoid needless sync traffic).
update public.households
   set sync_key = upper(trim(coalesce(lgu, ''))) || '|' || upper(trim(coalesce(barangay, '')))
 where sync_key is distinct from upper(trim(coalesce(lgu, ''))) || '|' || upper(trim(coalesce(barangay, '')));
update public.family_members
   set sync_key = upper(trim(coalesce(lgu, ''))) || '|' || upper(trim(coalesce(barangay, '')))
 where sync_key is distinct from upper(trim(coalesce(lgu, ''))) || '|' || upper(trim(coalesce(barangay, '')));
update public.dues_payments d
   set sync_key = m.sync_key
  from public.family_members m
 where m.id::text = d.member_id::text and d.sync_key is distinct from m.sync_key;

create index if not exists households_sync_key_idx on public.households (sync_key);
create index if not exists family_members_sync_key_idx on public.family_members (sync_key);
create index if not exists dues_payments_sync_key_idx on public.dues_payments (sync_key);

-- B2. What each user syncs, by sign-in email (profile ids don't always equal the Auth id):
--     full_access = true  -> every barangay (bucket all_records)
--     full_access = false -> one row per assigned barangay (bucket by_barangay)
--     Rebuilt by triggers; only PowerSync reads it.
create table if not exists public.user_sync_scopes (
  id text primary key,
  email text not null,
  full_access boolean not null,
  barangay_key text
);
alter table public.user_sync_scopes enable row level security;

create or replace view public.user_sync_scopes_wanted as
  select lower(u.email) || '|*' as id, lower(u.email) as email, true as full_access, null::text as barangay_key
    from public.users u
   where coalesce(u.status, 'active') = 'active' and u.email is not null and not u.sync_assigned_only
  union all
  select lower(u.email) || '|' || k.key, lower(u.email), false, k.key
    from public.users u
    join public.locations l on l.id::text = any (u.dues_barangays)
    cross join lateral (
      select upper(trim(coalesce(l.lgu, ''))) || '|' || upper(trim(coalesce(l.barangay, ''))) as key
    ) k
   where coalesce(u.status, 'active') = 'active' and u.email is not null and u.sync_assigned_only;

create or replace function public.refresh_user_sync_scopes() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  delete from public.user_sync_scopes s
   where not exists (select 1 from public.user_sync_scopes_wanted w where w.id = s.id);
  insert into public.user_sync_scopes (id, email, full_access, barangay_key)
  select id, email, full_access, barangay_key from public.user_sync_scopes_wanted
  on conflict (id) do nothing;
  return null;
end;
$$;

drop trigger if exists refresh_user_sync_scopes on public.users;
create trigger refresh_user_sync_scopes after insert or update or delete on public.users
  for each statement execute function public.refresh_user_sync_scopes();
drop trigger if exists refresh_user_sync_scopes on public.locations;
create trigger refresh_user_sync_scopes after update or delete on public.locations
  for each statement execute function public.refresh_user_sync_scopes();

-- Fill it now.
delete from public.user_sync_scopes s
 where not exists (select 1 from public.user_sync_scopes_wanted w where w.id = s.id);
insert into public.user_sync_scopes (id, email, full_access, barangay_key)
select id, email, full_access, barangay_key from public.user_sync_scopes_wanted
on conflict (id) do nothing;

-- Only PowerSync (replication) reads these; keep them out of the API. The view runs with its
-- owner's rights, so without this it would expose users' emails.
revoke all on public.user_sync_scopes from anon, authenticated;
revoke all on public.user_sync_scopes_wanted from anon, authenticated;

alter publication powersync add table user_sync_scopes;
