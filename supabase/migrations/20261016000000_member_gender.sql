-- Member gender (Male / Female), set from the Add Member form.
-- Existing rows stay NULL until the member is next edited.
-- Run once in the Supabase SQL editor (or `supabase db push`) before shipping the build that sends it.
alter table family_members add column if not exists gender text
  check (gender in ('Male', 'Female'));
