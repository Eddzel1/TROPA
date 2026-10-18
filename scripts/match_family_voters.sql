-- Finds family members not tagged as voters (is_voter = false) who are in the COMELEC voters
-- registry, and optionally tags them. Run in the Supabase SQL editor, one step at a time
-- (select a step and run it; the editor only shows the last result of a run).
--
-- A member matches a voter when, after normalizing (upper case, no dots/commas, single spaces):
--   - last name and first name are equal;
--   - the voter is in the member's LGU (or the voter row has no LGU);
--   - middle names are equal, or one is the other's initial, or either is blank;
--   - extensions (JR, SR, III) are equal, or either is blank.
-- The voter's barangay may differ: people often vote where they used to live.
--
-- Voters imports vary in column names (`ext` vs `ext.`, `brgy` vs `barangay`, `PC` vs `pc`), so voter
-- columns are read case-insensitively from the row as JSON, like Voter.fromJson in lib/models/models.dart.
--
-- Everything lives in a `tools` schema that the API does not expose. Step 4 removes it.

-- ============================================================
-- Step 1: build the matches (re-run this step to refresh them)
-- ============================================================
create schema if not exists tools;

create or replace function tools.norm_name(t text) returns text
language sql immutable as $$
  select nullif(btrim(regexp_replace(regexp_replace(upper(coalesce(t, '')), '[.,]', '', 'g'), '\s+', ' ', 'g')), '')
$$;

drop materialized view if exists tools.member_voter_matches;
create materialized view tools.member_voter_matches as
with v as (
  select
    r.id as voter_id,
    tools.norm_name(j ->> 'lastname') as lastname,
    tools.norm_name(j ->> 'firstname') as firstname,
    tools.norm_name(j ->> 'middlename') as middlename,
    tools.norm_name(coalesce(j ->> 'ext', j ->> 'ext.', j ->> 'extension', j ->> 'suffix')) as ext,
    tools.norm_name(j ->> 'lgu') as lgu,
    tools.norm_name(coalesce(j ->> 'brgy', j ->> 'barangay')) as brgy,
    coalesce(j ->> 'precinct', j ->> 'precinct_no') as precinct
  from public.voters r
  cross join lateral (select jsonb_object_agg(lower(key), value) as j from jsonb_each(to_jsonb(r))) k
),
m as (
  select
    f.id as member_id,
    tools.norm_name(f.lastname) as lastname,
    tools.norm_name(f.firstname) as firstname,
    tools.norm_name(f.middlename) as middlename,
    tools.norm_name(f.extension) as ext,
    tools.norm_name(f.lgu) as lgu,
    tools.norm_name(f.barangay) as barangay
  from public.family_members f
  where not coalesce(f.is_voter, false)
),
pairs as (
  select
    m.member_id,
    v.voter_id,
    m.lastname, m.firstname, m.middlename as member_middlename, m.ext as member_ext,
    m.lgu, m.barangay as member_barangay,
    v.middlename as voter_middlename, v.ext as voter_ext, v.brgy as voter_brgy, v.precinct,
    case
      when m.middlename is null or v.middlename is null then 'no_middle'
      when m.middlename = v.middlename and length(m.middlename) > 1 then 'exact'
      else 'initial'
    end as match_quality
  from m
  join v on v.lastname = m.lastname and v.firstname = m.firstname
  where (v.lgu is null or v.lgu = m.lgu)
    and (m.middlename is null or v.middlename is null
         or m.middlename = v.middlename
         or (length(m.middlename) = 1 and m.middlename = left(v.middlename, 1))
         or (length(v.middlename) = 1 and v.middlename = left(m.middlename, 1)))
    and (m.ext is null or v.ext is null or m.ext = v.ext)
)
select
  p.*,
  count(*) over (partition by p.member_id) as voter_candidates,
  count(*) over (partition by p.voter_id) as member_candidates,
  exists (select 1 from public.family_members f where f.voter_id = p.voter_id) as voter_already_linked
from pairs p;

-- ============================================================
-- Step 2: review (read-only)
-- ============================================================

-- 2a. Summary
select
  (select count(*) from public.family_members where not coalesce(is_voter, false)) as untagged_members,
  count(distinct member_id) as members_with_a_match,
  count(*) filter (where unambiguous and match_quality = 'exact') as unambiguous_exact,
  count(*) filter (where unambiguous and match_quality = 'initial') as unambiguous_initial,
  count(*) filter (where unambiguous and match_quality = 'no_middle') as unambiguous_no_middle,
  count(distinct member_id) filter (where not unambiguous) as ambiguous_members
from (
  select *, voter_candidates = 1 and member_candidates = 1 and not voter_already_linked as unambiguous
  from tools.member_voter_matches
) x;

-- 2b. Every match (export as CSV from the results panel to review)
select
  voter_candidates = 1 and member_candidates = 1 and not voter_already_linked as will_tag,
  match_quality,
  member_id, lastname, firstname, member_middlename, member_ext, lgu, member_barangay,
  voter_id, voter_middlename, voter_ext, voter_brgy, precinct,
  voter_candidates, member_candidates, voter_already_linked
from tools.member_voter_matches
order by lgu, lastname, firstname, member_id;

-- ============================================================
-- Step 3: tag the unambiguous matches (writes; run after reviewing Step 2)
-- ============================================================
-- Only members with exactly one candidate voter, whose voter matches no other untagged member and is
-- not already linked to a member. To skip matches with no middle name to compare, add:
--   and match_quality in ('exact', 'initial')
-- The touch_updated trigger bumps updated_date, and PowerSync carries the change to devices.
--
-- begin;
-- update public.family_members f
-- set is_voter = true, voter_id = x.voter_id, voter_barangay = x.voter_brgy
-- from tools.member_voter_matches x
-- where f.id = x.member_id
--   and x.voter_candidates = 1
--   and x.member_candidates = 1
--   and not x.voter_already_linked;
-- commit;

-- ============================================================
-- Step 4: clean up
-- ============================================================
-- drop schema tools cascade;
