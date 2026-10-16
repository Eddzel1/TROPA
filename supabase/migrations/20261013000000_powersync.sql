-- PowerSync reads changes through Postgres logical replication.
-- Run once in the Supabase SQL editor (or `supabase db push`).

-- 1. Publish the tables PowerSync streams to devices.
--    activity_logs is upload-only, so it is not published. voters is published but not
--    synced (see powersync/sync-rules.yaml); Tropa Finder queries it online.
create publication powersync for table
  households,
  family_members,
  dues_payments,
  form_tracking,
  voters,
  locations,
  users;

-- 2. Devices upload queued changes with the signed-in user's JWT, so RLS must let
--    authenticated users insert/update/delete the tables they edit offline, and
--    insert into activity_logs. Check the existing policies cover:
--      households, family_members, dues_payments, form_tracking  -> insert, update, delete
--      voters, users                                             -> update
--      activity_logs                                             -> insert
