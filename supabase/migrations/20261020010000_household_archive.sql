-- Archiving a household also archives every member in it; restoring it restores them.
-- Archiving uses the same 'delete_records' permission as deleting.
-- Run once in the Supabase SQL editor (or `supabase db push`) before shipping the build that sends it.
alter table households add column if not exists is_archived boolean not null default false;
