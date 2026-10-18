-- TROPA member ID card number, e.g. 'TRP-2600001' (TRP- + two-digit year assigned + 5-digit sequence).
-- The server owns it: a trigger assigns it on insert, so members added offline get theirs once they
-- sync, and devices can never change or clear it. Existing members are numbered in creation order.
-- Run once in the Supabase SQL editor (or `supabase db push`) before shipping the build that reads it.
-- sync-rules.yaml and the fallback sync use SELECT *, so no redeploy is needed there.

alter table family_members add column if not exists id_number text;

create sequence if not exists family_members_id_number_seq;

-- security definer so devices uploading with their own JWT can still draw from the sequence.
create or replace function public.next_member_id_number()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  n bigint := nextval('family_members_id_number_seq');
begin
  -- lpad would truncate past 99999, so longer numbers are written out in full.
  return 'TRP-' || to_char(now() at time zone 'Asia/Manila', 'YY')
    || case when n < 100000 then lpad(n::text, 5, '0') else n::text end;
end;
$$;

create or replace function public.family_members_assign_id_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and old.id_number is not null then
    new.id_number := old.id_number;
  elsif new.id_number is null then
    new.id_number := public.next_member_id_number();
  end if;
  return new;
end;
$$;

-- Backfill before the trigger exists: the members listed here get the first numbers in this order,
-- then everyone else, oldest first. Names are 'Lastname, Firstname Middlename', matched ignoring
-- case and extra spaces, however the first and middle names are split.
do $$
declare
  first_members text[] := array[
    'Roque, Rogelio Neil Pepito',
    'Roque, Laarni Lavin',
    'Pepito, Teodoro Roteo Tasani',
    'Pepito, Zichri Keren Perocho'
  ];
  r record;
  matches int;
begin
  for i in 1 .. array_length(first_members, 1) loop
    select count(*) into matches from family_members fm
    where lower(regexp_replace(trim(fm.lastname || ', ' || fm.firstname || ' ' || coalesce(fm.middlename, '')), '\s+', ' ', 'g'))
        = lower(first_members[i]);
    if matches <> 1 then
      raise exception 'Expected exactly one member named "%", found %', first_members[i], matches;
    end if;
  end loop;

  for r in
    select fm.id from family_members fm
    left join lateral (
      select array_position(first_members, x) as pos
      from unnest(first_members) x
      where lower(x) = lower(regexp_replace(trim(fm.lastname || ', ' || fm.firstname || ' ' || coalesce(fm.middlename, '')), '\s+', ' ', 'g'))
    ) p on true
    where fm.id_number is null
    order by p.pos nulls last, fm.created_date, fm.id
  loop
    update family_members set id_number = public.next_member_id_number(), updated_date = now() where id = r.id;
  end loop;
end;
$$;

drop trigger if exists family_members_id_number on family_members;
create trigger family_members_id_number
  before insert or update on family_members
  for each row execute function public.family_members_assign_id_number();

create unique index if not exists family_members_id_number_key on family_members (id_number);
