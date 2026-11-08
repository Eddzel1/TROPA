-- Form Tracking cards show how many days a submission has been in Pending or In Progress, counted
-- from when it entered that status. Run this BEFORE deploying the app build that writes the column:
-- devices upload it with their changes, and Supabase rejects a change to a column it doesn't have.

-- 1. When the row entered its current status.
alter table public.form_tracking add column if not exists status_changed_at timestamptz;

-- 2. Backfill existing rows from the activity log. A Pending row that was never moved counts from
--    when it was logged. Otherwise it counts from the first edit that set its current status after
--    the last edit that set a different one (rows with no such log fall back to when they were
--    logged). activity_logs.details may hold the JSON as an object or as a JSON string.
with logs as (
  select
    l.entity_id,
    l.created_at::timestamptz as at,
    (case when jsonb_typeof(l.details::jsonb) = 'string' then (l.details::jsonb #>> '{}')::jsonb
          else l.details::jsonb end) ->> 'status' as status
  from public.activity_logs l
  where l.entity_type = 'FormTracking' and l.action = 'UPDATE' and l.details is not null
),
last_other as (
  select f.id, max(g.at) as at
  from public.form_tracking f
  join logs g on g.entity_id = f.id::text and g.status <> f.status
  group by f.id
),
stamps as (
  select f.id, case
    when f.status = 'Pending' and o.at is null then f.created_at::timestamptz
    else coalesce(
      (select min(g.at) from logs g
       where g.entity_id = f.id::text and g.status = f.status and g.at > coalesce(o.at, '-infinity'::timestamptz)),
      f.created_at::timestamptz)
    end as at
  from public.form_tracking f
  left join last_other o on o.id = f.id
)
update public.form_tracking f
set status_changed_at = s.at
from stamps s
where s.id = f.id and f.status_changed_at is null;

-- 3. Safety net for app builds that don't send the column yet: stamp new rows, and restart the
--    count when the status changes without the column being set.
create or replace function public.form_tracking_stamp_status_changed_at()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    new.status_changed_at := coalesce(new.status_changed_at, new.created_at::timestamptz, now());
  elsif new.status is distinct from old.status
        and new.status_changed_at is not distinct from old.status_changed_at then
    new.status_changed_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists form_tracking_status_changed_at on public.form_tracking;
create trigger form_tracking_status_changed_at
  before insert or update on public.form_tracking
  for each row execute function public.form_tracking_stamp_status_changed_at();
