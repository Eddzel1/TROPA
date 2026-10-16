-- Barangay center coordinates for Valencia City.
-- Run once in the Supabase SQL editor (or `supabase db push`).
-- Households are placed near these centers by 20261014020000_household_coordinates.sql.

-- 1. Coordinate columns (no-op if they already exist).
alter table locations
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

-- 2. Barangay centers.
update locations l
set latitude = v.lat,
    longitude = v.lng
from (values
  ('BAGONTAAS',     7.946606,    125.102951),
  ('BANLAG',        7.833139,    125.169772),
  ('BAROBO',        7.904737264, 125.0333678),
  ('BATANGAN',      7.901937,    125.119796),
  ('CATUMBALON',    7.848452,    125.102454),
  ('COLONIA',       7.986235,    125.134702),
  ('CONCEPCION',    7.882749,    125.22155),
  ('DAGAT KIDAVAO', 7.825683,    125.132255),
  ('GUINOYURAN',    7.895594039, 125.0038377),
  ('KAHAPUNAN',     7.940233,    125.157906),
  ('LALIGAN',       7.885742,    125.182461),
  ('LILINGAYON',    7.99307,     124.970564),
  ('LOURDES',       7.895535866, 124.951521),
  ('LUMBAYAO',      7.94637,     125.245292),
  ('LUMBO',         7.894063,    125.075828),
  ('LUROGAN',       7.971926,    125.048401),
  ('MAAPAG',        7.860766582, 125.1102748),
  ('MABUHAY',       7.852667517, 125.1352922),
  ('MAILAG',        7.970326,    125.138433),
  ('MT. NEBO',      7.971911053, 124.9874708),
  ('NABAG-O',       7.963563,    125.15757),
  ('PINATILAN',     7.886861,    125.106045),
  ('POBLACION',     7.906821,    125.088944),
  ('SAN CARLOS',    7.960569,    125.073785),
  ('SAN ISIDRO',    7.964265,    125.189824),
  ('SINABUAGAN',    7.943481,    125.217618),
  ('SINAYAWAN',     7.869474,    125.145463),
  ('SUGOD',         7.942894,    125.120715),
  ('TONGANTONGAN',  7.9087,      125.165278),
  ('TUGAYA',        7.914583299, 125.0173436),
  ('VINTAR',        7.945301,    125.176359)
) as v(barangay, lat, lng)
where upper(trim(l.barangay)) = v.barangay
  and upper(trim(l.lgu)) = 'VALENCIA CITY';

-- 3. Check: Valencia City barangays still without coordinates (spelling mismatch, e.g. MT. NEBO vs MOUNT NEBO).
--    Expect no rows; otherwise fix the name in the list above and re-run step 2.
-- select id, lgu, barangay from locations
-- where upper(trim(lgu)) = 'VALENCIA CITY' and (latitude is null or longitude is null);
