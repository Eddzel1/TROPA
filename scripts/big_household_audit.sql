-- Audit of households with 10 or more active members, looking for other families that were saved
-- into them instead of getting a household of their own (e.g. an encoder kept pressing
-- "Save & Add Another" from inside one household, where the Household Leader box is disabled).
-- Q1-Q3 are read-only. Q4 is a backfill (writes data), run only when wanted.
-- Run each query separately in the Supabase SQL editor.
--
-- Who leads a household: the household name. Households are named "LAST, FIRST MIDDLE FAMILY", so
-- the leader is the active member whose "LAST, FIRST" begins the name, ending at a word boundary
-- ("MARIA" does not match "…, MARIA LUISA FAMILY"). When several members match (e.g. a daughter
-- with her mother's name), the one whose full "LAST, FIRST MIDDLE FAMILY" equals the name wins,
-- then the one flagged is_household_leader; still tied = ambiguous, no leader.
-- leader_source in Q1/Q2 says how each leader was found:
--   leader_id   households.household_leader_id, when it points to an active member of the household
--   name_match  else the member matched by the household name (rule above)
--   flag        else the single active member flagged is_household_leader
--   name_only   else no member; the surname is read from the household name (text before the comma)
--
-- Signals used:
--   * surname groups: 2+ members sharing a surname that is neither the leader's surname nor the
--     leader's middle name (Filipino middle name = mother's maiden surname, so siblings and the
--     leader's mother's side are not flagged);
--   * save batches: one form save writes the leader first, then its member cards ~1 s later, all
--     with the same created_by. Members saved minutes or days apart came from separate saves;
--   * leader flags: is_household_leader on more than one member, or none.

-- ---------------------------------------------------------------------------------------------
-- Q1. Overview: one row per household with 10+ active members, most suspicious first.
-- ---------------------------------------------------------------------------------------------
with m as (
  select fm.*, upper(trim(fm.lastname)) as ln
  from family_members fm
  where coalesce(fm.is_archived, false) = false
),
big as (
  select household_id::text as hid, count(*) as members
  from m group by 1 having count(*) >= 10
),
name_cand as (
  select h.id::text as hid, n.id::text as mid, n.is_household_leader,
         upper(trim(h.household_name)) = upper(trim(n.lastname) || ', ' || trim(n.firstname)
           || coalesce(' ' || nullif(trim(n.middlename), ''), '') || ' FAMILY') as exact
  from households h
  join big b on b.hid = h.id::text
  join m n on n.household_id::text = h.id::text
  where upper(trim(h.household_name)) like upper(trim(n.lastname) || ', ' || trim(n.firstname)) || ' %'
     or upper(trim(h.household_name)) = upper(trim(n.lastname) || ', ' || trim(n.firstname))
),
name_leader as (
  select hid, min(mid) as mid
  from (select *, rank() over (partition by hid order by exact desc, is_household_leader desc) as rk
        from name_cand) r
  where rk = 1
  group by hid
  having count(*) = 1
),
one_flag as (
  select m.household_id::text as hid, min(m.id::text) as mid
  from m join big b on b.hid = m.household_id::text
  where m.is_household_leader
  group by 1 having count(*) = 1
),
leader as (
  select h.id::text as hid,
         case when lm.id is not null then 'leader_id'
              when nm.id is not null then 'name_match'
              when fm.id is not null then 'flag'
              else 'name_only' end as leader_source,
         coalesce(lm.firstname || ' ' || lm.lastname, nm.firstname || ' ' || nm.lastname,
                  fm.firstname || ' ' || fm.lastname) as leader_name,
         coalesce(lm.ln, nm.ln, fm.ln, nullif(upper(trim(split_part(h.household_name, ',', 1))), '')) as ln,
         upper(trim(coalesce(lm.middlename, nm.middlename, fm.middlename, ''))) as mn
  from households h
  join big b on b.hid = h.id::text
  left join m lm on lm.id::text = h.household_leader_id::text and lm.household_id::text = h.id::text
  left join name_leader nl on nl.hid = h.id::text
  left join m nm on nm.id::text = nl.mid
  left join one_flag ofl on ofl.hid = h.id::text
  left join m fm on fm.id::text = ofl.mid
),
batches as (
  -- saves more than 10 s apart, by encoder, count as separate form saves
  select hid, count(*) as saves
  from (
    select m.household_id::text as hid,
           m.created_date - lag(m.created_date) over (partition by m.household_id, m.created_by order by m.created_date) as gap
    from m join big b on b.hid = m.household_id::text
  ) x
  where gap is null or gap > interval '10 seconds'
  group by hid
),
surnames as (
  select m.household_id::text as hid, m.ln, count(*) as n
  from m join big b on b.hid = m.household_id::text
  group by 1, 2
)
select h.household_name,
       b.members,
       l.leader_name,
       l.leader_source,
       (select count(*) from m where m.household_id::text = b.hid and m.is_household_leader) as leader_flags,
       (select count(*) from surnames s where s.hid = b.hid) as distinct_surnames,
       (select count(*) from surnames s where s.hid = b.hid and s.n >= 2
          and s.ln is distinct from l.ln and s.ln is distinct from nullif(l.mn, '')) as foreign_surname_groups,
       ba.saves as form_saves,
       (select string_agg(s.ln || ' ×' || s.n, ', ' order by s.n desc) from surnames s where s.hid = b.hid) as surnames,
       (select string_agg(distinct m.created_by, ', ') from m where m.household_id::text = b.hid) as encoders,
       h.lgu, h.barangay, h.purok, b.hid as household_id
from big b
join households h on h.id::text = b.hid
left join leader l on l.hid = b.hid
left join batches ba on ba.hid = b.hid
order by foreign_surname_groups desc, leader_flags desc, form_saves desc, b.members desc;

-- ---------------------------------------------------------------------------------------------
-- Q2. Candidate families to split out: inside 10+ households, each group of 2+ members sharing a
--     surname unrelated to the leader's. suggested_leader = the group's member flagged as leader,
--     else its oldest member.
-- ---------------------------------------------------------------------------------------------
with m as (
  select fm.*, upper(trim(fm.lastname)) as ln,
         coalesce(extract(year from age(current_date, fm.birth_date::date))::int, fm.age) as yrs
  from family_members fm
  where coalesce(fm.is_archived, false) = false
),
big as (
  select household_id::text as hid from m group by 1 having count(*) >= 10
),
name_cand as (
  select h.id::text as hid, n.id::text as mid, n.is_household_leader,
         upper(trim(h.household_name)) = upper(trim(n.lastname) || ', ' || trim(n.firstname)
           || coalesce(' ' || nullif(trim(n.middlename), ''), '') || ' FAMILY') as exact
  from households h
  join big b on b.hid = h.id::text
  join m n on n.household_id::text = h.id::text
  where upper(trim(h.household_name)) like upper(trim(n.lastname) || ', ' || trim(n.firstname)) || ' %'
     or upper(trim(h.household_name)) = upper(trim(n.lastname) || ', ' || trim(n.firstname))
),
name_leader as (
  select hid, min(mid) as mid
  from (select *, rank() over (partition by hid order by exact desc, is_household_leader desc) as rk
        from name_cand) r
  where rk = 1
  group by hid
  having count(*) = 1
),
one_flag as (
  select m.household_id::text as hid, min(m.id::text) as mid
  from m join big b on b.hid = m.household_id::text
  where m.is_household_leader
  group by 1 having count(*) = 1
),
leader as (
  select h.id::text as hid,
         case when lm.id is not null then 'leader_id'
              when nm.id is not null then 'name_match'
              when fm.id is not null then 'flag'
              else 'name_only' end as leader_source,
         coalesce(lm.firstname || ' ' || lm.lastname, nm.firstname || ' ' || nm.lastname,
                  fm.firstname || ' ' || fm.lastname) as leader_name,
         coalesce(lm.ln, nm.ln, fm.ln, nullif(upper(trim(split_part(h.household_name, ',', 1))), '')) as ln,
         upper(trim(coalesce(lm.middlename, nm.middlename, fm.middlename, ''))) as mn
  from households h
  join big b on b.hid = h.id::text
  left join m lm on lm.id::text = h.household_leader_id::text and lm.household_id::text = h.id::text
  left join name_leader nl on nl.hid = h.id::text
  left join m nm on nm.id::text = nl.mid
  left join one_flag ofl on ofl.hid = h.id::text
  left join m fm on fm.id::text = ofl.mid
),
grp as (
  select m.household_id::text as hid, m.ln,
         count(*) as n,
         bool_or(m.is_household_leader) as has_flagged_leader,
         min(m.created_date) as first_saved,
         max(m.created_date) as last_saved,
         string_agg(m.firstname || coalesce(' ' || nullif(m.middlename, ''), '') || ' (' || coalesce(m.yrs::text, '?') || ')'
                    || case when m.is_household_leader then ' [HHL]' else '' end,
                    ', ' order by m.yrs desc nulls last) as members,
         (array_agg(m.id::text order by m.is_household_leader desc, m.yrs desc nulls last))[1] as suggested_leader_id,
         (array_agg(m.firstname || ' ' || m.lastname order by m.is_household_leader desc, m.yrs desc nulls last))[1]
           as suggested_leader
  from m join big b on b.hid = m.household_id::text
  group by 1, 2
  having count(*) >= 2
)
select h.household_name, l.leader_name, l.leader_source,
       g.ln as surname, g.n, g.has_flagged_leader, g.suggested_leader, g.members,
       g.first_saved, g.last_saved, h.lgu, h.barangay, h.purok,
       g.hid as household_id, g.suggested_leader_id
from grp g
join households h on h.id::text = g.hid
left join leader l on l.hid = g.hid
where g.ln is distinct from l.ln and g.ln is distinct from nullif(l.mn, '')
order by g.has_flagged_leader desc, h.household_name, g.n desc;

-- ---------------------------------------------------------------------------------------------
-- Q3. Leader problems in any active household. An empty household_leader_id is normal (old
--     system) and is not flagged. Listed:
--       no_name_leader      no member (or no single member) matches the household name
--       name_leader_unflagged  the member named in the household name isn't flagged HHL in the app
--       several_flags       2+ members flagged HHL: often a second family merged into the household
--       leader_id_mismatch  household_leader_id is set but isn't the member named in the household name
-- ---------------------------------------------------------------------------------------------
with m as (
  select fm.* from family_members fm where coalesce(fm.is_archived, false) = false
),
hh as (
  select * from households where coalesce(is_archived, false) = false
),
name_cand as (
  select h.id::text as hid, n.id::text as mid, n.is_household_leader,
         upper(trim(h.household_name)) = upper(trim(n.lastname) || ', ' || trim(n.firstname)
           || coalesce(' ' || nullif(trim(n.middlename), ''), '') || ' FAMILY') as exact
  from hh h
  join m n on n.household_id::text = h.id::text
  where upper(trim(h.household_name)) like upper(trim(n.lastname) || ', ' || trim(n.firstname)) || ' %'
     or upper(trim(h.household_name)) = upper(trim(n.lastname) || ', ' || trim(n.firstname))
),
name_leader as (
  select hid, min(mid) as mid
  from (select *, rank() over (partition by hid order by exact desc, is_household_leader desc) as rk
        from name_cand) r
  where rk = 1
  group by hid
  having count(*) = 1
),
summary as (
  select h.id::text as hid, h.household_name, h.household_leader_id::text as leader_id, h.lgu, h.barangay, h.purok,
         nl.mid as name_leader_id,
         count(m.id) as members,
         count(m.id) filter (where m.is_household_leader) as leader_flags,
         bool_or(m.id::text = nl.mid and m.is_household_leader) as name_leader_flagged,
         string_agg(m.firstname || ' ' || m.lastname, ', ') filter (where m.is_household_leader) as flagged_leaders
  from hh h
  join m on m.household_id::text = h.id::text
  left join name_leader nl on nl.hid = h.id::text
  group by h.id, h.household_name, h.household_leader_id, h.lgu, h.barangay, h.purok, nl.mid
)
select s.household_name, s.members, s.leader_flags, s.flagged_leaders,
       s.name_leader_id is null as no_name_leader,
       s.name_leader_id is not null and not coalesce(s.name_leader_flagged, false) as name_leader_unflagged,
       s.leader_flags >= 2 as several_flags,
       s.leader_id is not null and s.leader_id is distinct from s.name_leader_id as leader_id_mismatch,
       s.lgu, s.barangay, s.purok, s.hid as household_id
from summary s
where s.name_leader_id is null
   or not coalesce(s.name_leader_flagged, false)
   or s.leader_flags >= 2
   or (s.leader_id is not null and s.leader_id is distinct from s.name_leader_id)
order by (s.leader_flags >= 2) desc, s.members desc;

-- =============================================================================================
-- Q4. BACKFILL household_leader_id from the household name (writes data; run only when wanted)
--
-- Sets households.household_leader_id to the member named in the household name (rule at the
-- top), only where the column is empty, the household is active and exactly one member is picked.
-- Households with no or an ambiguous match are left alone: review them with Q3. updated_date is
-- set by the touch_updated trigger. Member HHL flags (is_household_leader) are not changed.
--
-- Already ran the earlier flag-based backfill (table household_leader_backfill)? Undo it first:
--   update households h set household_leader_id = null
--   from household_leader_backfill b
--   where b.household_id = h.id::text and h.household_leader_id::text = b.leader_id;
--   drop table household_leader_backfill;
--
-- Every updated household syncs to every device once (PowerSync), so run it outside busy
-- encoding hours.
-- =============================================================================================

-- Q4a. Record exactly which households will be filled, and with whom (also the preview: review
--      it with  select * from household_leader_backfill_by_name;  before running Q4b).
create table if not exists household_leader_backfill_by_name as
with m as (
  select fm.* from family_members fm where coalesce(fm.is_archived, false) = false
),
name_cand as (
  select h.id::text as hid, n.id::text as mid, n.is_household_leader,
         upper(trim(h.household_name)) = upper(trim(n.lastname) || ', ' || trim(n.firstname)
           || coalesce(' ' || nullif(trim(n.middlename), ''), '') || ' FAMILY') as exact
  from households h
  join m n on n.household_id::text = h.id::text
  where h.household_leader_id is null
    and coalesce(h.is_archived, false) = false
    and (upper(trim(h.household_name)) like upper(trim(n.lastname) || ', ' || trim(n.firstname)) || ' %'
         or upper(trim(h.household_name)) = upper(trim(n.lastname) || ', ' || trim(n.firstname)))
)
select r.hid as household_id, min(r.mid) as leader_id, now() as filled_at
from (select *, rank() over (partition by hid order by exact desc, is_household_leader desc) as rk
      from name_cand) r
where r.rk = 1
group by r.hid
having count(*) = 1;
-- Keep the record away from the public API (new public tables are readable by default).
alter table household_leader_backfill_by_name enable row level security;

-- Q4b. Backfill from that record. "Rows affected" should equal the Q4a row count.
update households h
set household_leader_id = b.leader_id::uuid  -- also stores fine if the column is text
from household_leader_backfill_by_name b
where b.household_id = h.id::text
  and h.household_leader_id is null;

-- Undo, if ever needed (only touches rows still holding the backfilled value):
--   update households h set household_leader_id = null
--   from household_leader_backfill_by_name b
--   where b.household_id = h.id::text and h.household_leader_id::text = b.leader_id;
-- When satisfied: drop table household_leader_backfill_by_name;
