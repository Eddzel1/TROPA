-- Public search page: tapping HOUSEHOLD LEADER on a result lists everyone in that household.
-- public_member_search now also returns household_id (adding a column needs a drop and re-create),
-- and public_household_members returns the same safe fields for one household's members.
-- Run once in the Supabase SQL editor (or `supabase db push`) before shipping the build that calls it.
--
-- Checks after running:
--   select household_id from public_member_search('cruz', '', '', '', '');   -- ids filled in
--   select * from public_household_members('<one of those ids>');           -- that household

drop function if exists public.public_member_search(text, text, text, text, text);

create function public.public_member_search(
  p_last text,
  p_first text,
  p_middle text,
  p_lgu text,
  p_barangay text
)
returns table (
  lastname text,
  firstname text,
  middlename text,
  extension text,
  lgu text,
  barangay text,
  purok text,
  is_household_leader boolean,
  is_cooperative_member boolean,
  household_id text,
  household_name text,
  leader_name text
)
language sql
stable
security definer
set search_path = public
as $$
  with q as (
    -- Typed text with LIKE wildcards escaped, so '%' or '_' can't match everyone.
    select
      replace(replace(replace(trim(coalesce(p_last, '')), '\', '\\'), '%', '\%'), '_', '\_') as last,
      replace(replace(replace(trim(coalesce(p_first, '')), '\', '\\'), '%', '\%'), '_', '\_') as first,
      replace(replace(replace(trim(coalesce(p_middle, '')), '\', '\\'), '%', '\%'), '_', '\_') as middle,
      upper(trim(coalesce(p_lgu, ''))) as lgu,
      upper(trim(coalesce(p_barangay, ''))) as barangay
  )
  select
    fm.lastname::text,
    fm.firstname::text,
    fm.middlename::text,
    fm.extension::text,
    fm.lgu::text,
    fm.barangay::text,
    fm.purok::text,
    coalesce(fm.is_household_leader, false),
    coalesce(fm.is_cooperative_member, false),
    h.id::text,
    h.household_name::text,
    nullif(concat_ws(' ', l.firstname, l.lastname), '')
  from q
  join public.family_members fm on true
  left join public.households h on h.id = fm.household_id
  left join public.family_members l on l.id::text = h.household_leader_id::text
  where length(q.last) + length(q.first) + length(q.middle) >= 3
    and not coalesce(fm.is_archived, false)
    and not coalesce(h.is_archived, false)
    and (q.last = '' or coalesce(fm.lastname, '') ilike '%' || q.last || '%')
    and (q.first = '' or coalesce(fm.firstname, '') ilike '%' || q.first || '%')
    and (q.middle = '' or coalesce(fm.middlename, '') ilike '%' || q.middle || '%')
    and (q.lgu = '' or upper(trim(coalesce(fm.lgu, ''))) = q.lgu)
    and (q.barangay = '' or upper(trim(coalesce(fm.barangay, ''))) = q.barangay)
  order by fm.lastname, fm.firstname
  limit 20;
$$;

revoke all on function public.public_member_search(text, text, text, text, text) from public;
grant execute on function public.public_member_search(text, text, text, text, text) to anon, authenticated;

-- Everyone in one household, leader first. Only reachable with an id from a search result.
create or replace function public.public_household_members(p_household_id text)
returns table (
  lastname text,
  firstname text,
  middlename text,
  extension text,
  is_household_leader boolean,
  is_cooperative_member boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    fm.lastname::text,
    fm.firstname::text,
    fm.middlename::text,
    fm.extension::text,
    coalesce(fm.is_household_leader, false),
    coalesce(fm.is_cooperative_member, false)
  from public.family_members fm
  join public.households h on h.id = fm.household_id
  where h.id::text = p_household_id
    and not coalesce(h.is_archived, false)
    and not coalesce(fm.is_archived, false)
  order by coalesce(fm.is_household_leader, false) desc, fm.lastname, fm.firstname
  limit 100;
$$;

revoke all on function public.public_household_members(text) from public;
grant execute on function public.public_household_members(text) to anon, authenticated;
