-- Public member search (/search in the app): anyone, signed in or not, can look up a person by
-- last, first and middle name, optionally narrowed to an LGU and barangay.
-- Tables stay closed to anon; these functions are the only way in. Results carry just name,
-- location, household and TROPA status (no contact number, birth date, photo or ID number).
-- At least 3 letters across the name fields, at most 20 rows, archived members and households left out.
-- Run once in the Supabase SQL editor (or `supabase db push`) before shipping the build that calls it.
--
-- Checks after running:
--   select * from public_member_search('cruz', '', '', '', '');   -- up to 20 rows
--   select * from public_member_search('ab', '', '', '', '');     -- no rows
--   select * from public_search_locations();                      -- LGU/barangay pairs

-- Earlier one-box draft of this function, if it was run.
drop function if exists public.public_member_search(text);

create or replace function public.public_member_search(
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

-- LGU and barangay names for the search page's dropdowns.
create or replace function public.public_search_locations()
returns table (lgu text, barangay text)
language sql
stable
security definer
set search_path = public
as $$
  select distinct trim(l.lgu)::text, trim(l.barangay)::text
  from public.locations l
  where trim(coalesce(l.lgu, '')) <> '' and trim(coalesce(l.barangay, '')) <> ''
  order by 1, 2;
$$;

revoke all on function public.public_search_locations() from public;
grant execute on function public.public_search_locations() to anon, authenticated;
