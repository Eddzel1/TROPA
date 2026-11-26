-- The member form now records religion (optional). The app model and PowerSync schema already
-- carry `religion`; this makes sure the server column exists. No-op when it is already there.
alter table public.family_members add column if not exists religion text;
