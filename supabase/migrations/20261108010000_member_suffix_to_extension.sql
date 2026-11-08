-- Name suffixes (JR., SR., II, III, IV) go in family_members.extension. The member form had no
-- field for it, so encoders typed the suffix at the end of the first name ("ARMANDO JR.") or the
-- last name ("DELA CRUZ JR."). This moves it out of the name and into extension, and tidies
-- existing extension values to the same spelling (jr -> JR.). Voter matching compares extension,
-- so these members match their voter records again.
--
-- Run in the Supabase SQL editor. Run the PREVIEW first (select it alone) and look the list over.
--
-- A suffix is only split off when it is the last word of a name with at least two words, so a
-- first name that is just "II" stays as it is. "V" is never split (too often a stray initial);
-- pick it from the form instead. Rows are left alone and listed as conflicts when
--   - extension already holds a different suffix, or
--   - the first and last names end in different suffixes.
-- updated_date is bumped so devices on the fallback sync pull the change.

-- ---------------------------------------------------------------------------------------------
-- PREVIEW (read only): every row this would change, and the conflicts it leaves alone.
-- ---------------------------------------------------------------------------------------------
-- with parsed as (
--   select
--     m.id, m.firstname, m.lastname, m.extension,
--     regexp_match(trim(m.firstname), '^(.*[^\s,])[\s,]+(JR|SR|II|III|IV)\.?,?$', 'i') as f,
--     regexp_match(trim(m.lastname),  '^(.*[^\s,])[\s,]+(JR|SR|II|III|IV)\.?,?$', 'i') as l,
--     nullif(upper(regexp_replace(coalesce(m.extension, ''), '[\s.,]', '', 'g')), '') as e
--   from public.family_members m
-- ),
-- canon as (
--   select p.*,
--     case upper(p.f[2]) when 'JR' then 'JR.' when 'SR' then 'SR.' else upper(p.f[2]) end as f_suffix,
--     case upper(p.l[2]) when 'JR' then 'JR.' when 'SR' then 'SR.' else upper(p.l[2]) end as l_suffix,
--     case p.e when 'JR' then 'JR.' when 'SR' then 'SR.' else nullif(upper(trim(p.extension)), '') end as e_suffix
--   from parsed p
-- ),
-- plan as (
--   select c.*,
--     coalesce(c.f_suffix, c.l_suffix) as found,
--     (c.f_suffix is not null and c.l_suffix is not null and c.f_suffix <> c.l_suffix)
--       or (c.e_suffix is not null and coalesce(c.f_suffix, c.l_suffix) is not null
--           and c.e_suffix <> coalesce(c.f_suffix, c.l_suffix)) as conflict
--   from canon c
-- )
-- select
--   case when conflict then 'CONFLICT (left alone)' else 'will change' end as action,
--   firstname as old_firstname,
--   lastname as old_lastname,
--   extension as old_extension,
--   case when not conflict and f_suffix is not null then trim(f[1]) else firstname end as new_firstname,
--   case when not conflict and l_suffix is not null then trim(l[1]) else lastname end as new_lastname,
--   case when conflict then extension else coalesce(found, e_suffix) end as new_extension
-- from plan
-- where conflict
--    or found is not null
--    or (e_suffix is not null and e_suffix is distinct from extension)
-- order by conflict desc, lastname, firstname;

-- ---------------------------------------------------------------------------------------------
-- UPDATE
-- ---------------------------------------------------------------------------------------------
with parsed as (
  select
    m.id, m.firstname, m.lastname, m.extension,
    regexp_match(trim(m.firstname), '^(.*[^\s,])[\s,]+(JR|SR|II|III|IV)\.?,?$', 'i') as f,
    regexp_match(trim(m.lastname),  '^(.*[^\s,])[\s,]+(JR|SR|II|III|IV)\.?,?$', 'i') as l,
    nullif(upper(regexp_replace(coalesce(m.extension, ''), '[\s.,]', '', 'g')), '') as e
  from public.family_members m
),
canon as (
  select p.*,
    case upper(p.f[2]) when 'JR' then 'JR.' when 'SR' then 'SR.' else upper(p.f[2]) end as f_suffix,
    case upper(p.l[2]) when 'JR' then 'JR.' when 'SR' then 'SR.' else upper(p.l[2]) end as l_suffix,
    case p.e when 'JR' then 'JR.' when 'SR' then 'SR.' else nullif(upper(trim(p.extension)), '') end as e_suffix
  from parsed p
),
plan as (
  select c.*,
    coalesce(c.f_suffix, c.l_suffix) as found,
    (c.f_suffix is not null and c.l_suffix is not null and c.f_suffix <> c.l_suffix)
      or (c.e_suffix is not null and coalesce(c.f_suffix, c.l_suffix) is not null
          and c.e_suffix <> coalesce(c.f_suffix, c.l_suffix)) as conflict
  from canon c
)
update public.family_members m
set
  firstname = case when p.f_suffix is not null then trim(p.f[1]) else m.firstname end,
  lastname = case when p.l_suffix is not null then trim(p.l[1]) else m.lastname end,
  extension = coalesce(p.found, p.e_suffix),
  updated_date = now()
from plan p
where p.id = m.id
  and not p.conflict
  and (p.found is not null or (p.e_suffix is not null and p.e_suffix is distinct from m.extension));

-- ---------------------------------------------------------------------------------------------
-- CHECKS after running
-- ---------------------------------------------------------------------------------------------
-- Names still ending in a suffix (should only be the conflicts from the preview):
--   select firstname, lastname, extension from public.family_members
--   where trim(firstname) ~* '^.*\S[\s,]+(JR|SR|II|III|IV)\.?,?$'
--      or trim(lastname)  ~* '^.*\S[\s,]+(JR|SR|II|III|IV)\.?,?$';
--
-- Spot check:
--   select extension, count(*) from public.family_members group by 1 order by 2 desc;
--   select firstname, lastname, extension from public.family_members where extension <> '' limit 20;
