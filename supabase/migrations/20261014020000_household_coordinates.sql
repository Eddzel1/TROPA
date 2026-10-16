-- Approximate household coordinates: a random point within 500 m of the barangay center
-- (from 20261014010000_barangay_coordinates.sql), not an exact address. Members share
-- their household's point; family_members.latitude/longitude are no longer written by the app.
-- Run once in the Supabase SQL editor (or `supabase db push`).

-- 1. Coordinate columns (no-op if they already exist). family_members' are only read
--    below, to keep points placed by an earlier per-member backfill.
alter table households
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

alter table family_members
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

-- 2. Backfill households without coordinates: reuse a member's existing point,
--    otherwise pick one uniformly within a 500 m disc around the barangay center.
with picks as (
  select h.id,
         m.latitude as member_lat,
         m.longitude as member_lng,
         l.latitude as lat,
         l.longitude as lng,
         500 * sqrt(random()) as r,
         2 * pi() * random() as t
  from households h
  left join lateral (
    select fm.latitude, fm.longitude
    from family_members fm
    where fm.household_id = h.id
      and fm.latitude is not null
      and fm.longitude is not null
    limit 1
  ) m on true
  left join locations l
    on upper(trim(l.lgu)) = upper(trim(h.lgu))
   and upper(trim(l.barangay)) = upper(trim(h.barangay))
   and l.latitude is not null
   and l.longitude is not null
  where h.latitude is null
)
update households h
set latitude = coalesce(p.member_lat, p.lat + (p.r * cos(p.t)) / 111320),
    longitude = coalesce(p.member_lng, p.lng + (p.r * sin(p.t)) / (111320 * cos(radians(p.lat)))),
    updated_date = now()
from picks p
where h.id = p.id
  and (p.member_lat is not null or p.lat is not null);

-- 3. Check: households still without coordinates (barangay missing from locations or its center).
-- select id, household_name, lgu, barangay from households where latitude is null;
