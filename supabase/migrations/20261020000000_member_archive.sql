-- Archived members are hidden from the Members page but kept, with their dues and history.
-- Archiving uses the same 'delete_records' permission as deleting.
-- Run once in the Supabase SQL editor (or `supabase db push`) before shipping the build that sends it.
alter table family_members add column if not exists is_archived boolean not null default false;
