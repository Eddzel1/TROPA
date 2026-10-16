-- Barangay center coordinates for Kalilangan.
-- Run once in the Supabase SQL editor (or `supabase db push`), then re-run step 2 of
-- 20261014020000_household_coordinates.sql to place Kalilangan households near these centers.

update locations l
set latitude = v.lat,
    longitude = v.lng
from (values
  ('BANGBANG',           7.801812,    124.76734),
  ('BARORAWON',          7.831937,    124.733195),
  ('CANITOAN',           7.775465,    124.728947),
  ('CENTRAL POBLACION',  7.748864,    124.749147),
  ('KIBANING',           7.796839051, 124.7332694),
  ('KINURA',             7.777613,    124.753943),
  ('LAMPANUSAN',         7.654679,    124.767342),
  ('MACA-OPAO',          7.708117,    124.743399),
  ('MALINAO',            7.794347,    124.702232),
  ('NINOY AQUINO',       7.742207108, 124.7712486),
  ('PAMOTOLON',          7.745107,    124.737351),
  ('PUBLIC',             7.683759,    124.778142),
  ('SAN VICENTE FERRER', 7.893685,    124.680369),
  ('WEST POBLACION',     7.742865939, 124.7501331)
) as v(barangay, lat, lng)
where upper(trim(l.barangay)) = v.barangay
  and upper(trim(l.lgu)) = 'KALILANGAN';

-- Check: Kalilangan barangays still without coordinates (spelling mismatch with the list above).
-- select id, lgu, barangay from locations
-- where upper(trim(lgu)) = 'KALILANGAN' and (latitude is null or longitude is null);
