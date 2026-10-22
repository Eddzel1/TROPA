-- Dues starting month per barangay, set in Settings > Locations & Barangays.
-- New members encoded in a barangay that has one get it as their membership date (the 1st of
-- that month), whichever device or app version adds them. Later edits are left alone, so a single
-- member can still be corrected from the Dues page.
-- Run once in the Supabase SQL editor. Locations already sync to every device; no sync rule change.

alter table public.locations add column if not exists dues_start_month text;
alter table public.locations drop constraint if exists locations_dues_start_month_check;
alter table public.locations add constraint locations_dues_start_month_check
  check (dues_start_month is null or dues_start_month ~ '^\d{4}-(0[1-9]|1[0-2])$');

-- New members adopt their barangay's starting month.
create or replace function public.apply_barangay_start_month() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  start_month text;
begin
  select l.dues_start_month into start_month
    from public.locations l
   where upper(trim(coalesce(l.lgu, ''))) = upper(trim(coalesce(new.lgu, '')))
     and upper(trim(coalesce(l.barangay, ''))) = upper(trim(coalesce(new.barangay, '')))
     and l.dues_start_month is not null
   limit 1;
  if start_month is not null then
    new.membership_date := (start_month || '-01')::date;
  end if;
  return new;
end;
$$;

drop trigger if exists apply_barangay_start_month on public.family_members;
create trigger apply_barangay_start_month before insert on public.family_members
  for each row execute function public.apply_barangay_start_month();

-- Admins who manage locations may also apply a barangay's month to its existing members.
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
  if not (public.can_collect_dues_in(p_lgu, p_barangay) or public.has_tropa_permission('manage_locations')) then
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
