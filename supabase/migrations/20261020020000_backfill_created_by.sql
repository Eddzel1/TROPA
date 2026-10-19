-- Households and members created from the Add Member form were saved with created_by = 'Admin'
-- instead of the encoder. The activity log recorded who actually created them, so copy that back.
-- Only rows still marked 'Admin' are touched, and only when the log names a real user.
-- Run once in the Supabase SQL editor (or `supabase db push`).

-- Households: their CREATE log entry carries the household id.
update households h
set created_by = l.user_name
from (
  select distinct on (entity_id) entity_id, user_name
  from activity_logs
  where entity_type = 'Household' and action = 'CREATE'
    and user_name is not null and user_name <> 'System Admin'
  order by entity_id, created_at
) l
where l.entity_id = h.id::text
  and h.created_by = 'Admin';

-- Members added one at a time: CREATE log entry carries the member id.
update family_members m
set created_by = l.user_name
from (
  select distinct on (entity_id) entity_id, user_name
  from activity_logs
  where entity_type = 'FamilyMember' and action = 'CREATE'
    and user_name is not null and user_name <> 'System Admin'
  order by entity_id, created_at
) l
where l.entity_id = m.id::text
  and m.created_by = 'Admin';

-- Household members added in bulk: CREATE_BULK log entry carries the household id in its details.
update family_members m
set created_by = l.user_name
from (
  select distinct on (details::jsonb ->> 'household_id') details::jsonb ->> 'household_id' as household_id, user_name
  from activity_logs
  where entity_type = 'FamilyMember' and action = 'CREATE_BULK'
    and user_name is not null and user_name <> 'System Admin'
  order by details::jsonb ->> 'household_id', created_at
) l
where l.household_id = m.household_id::text
  and m.created_by = 'Admin';
