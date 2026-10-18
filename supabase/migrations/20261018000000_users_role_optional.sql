-- users.role is no longer read or written by the app or the admin-users function; access comes
-- only from users.permissions. Keep the column for now so devices still on an older build can
-- upload user edits that include it, but stop requiring it for new rows.
-- Once every device runs the new build: alter table public.users drop column role;
alter table public.users alter column role drop not null;
