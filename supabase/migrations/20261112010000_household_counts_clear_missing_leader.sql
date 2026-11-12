-- Deleting several members of a household in one request failed with 23503
-- (`insert or update on table "households" violates foreign key constraint "fk_household_leader"`)
-- whenever the leader was not the first row processed, and the app silently dropped the change.
--
-- Why: the per-row AFTER DELETE trigger `update_household_counts` rewrites the household row for
-- every deleted member. The first rewrite still carries the old leader id (the leader's own
-- ON DELETE SET NULL has not run yet), and the next rewrite of that same row re-checks the foreign
-- key, because the row was changed in this transaction, while the leader is already gone.
--
-- Fix: the recount also clears a leader id that no longer points at a member, so every rewrite is
-- valid whatever order the rows are deleted in. Counts behave exactly as before.

create or replace function public.update_household_member_counts()
returns trigger
language plpgsql
as $$
begin
  -- Update counts for the affected household(s)
  if tg_op = 'DELETE' then
    update households h
    set
      total_members = (select count(*) from family_members where household_id = old.household_id),
      active_members = (select count(*) from family_members
                        where household_id = old.household_id and is_cooperative_member = true),
      household_leader_id = case
        when h.household_leader_id is not null
             and not exists (select 1 from family_members m where m.id = h.household_leader_id)
          then null
        else h.household_leader_id
      end
    where h.id = old.household_id;
    return old;
  else
    update households
    set
      total_members = (select count(*) from family_members where household_id = new.household_id),
      active_members = (select count(*) from family_members
                        where household_id = new.household_id and is_cooperative_member = true)
    where id = new.household_id;

    -- If household_id changed, update the old household too
    if tg_op = 'UPDATE' and old.household_id is distinct from new.household_id then
      update households h
      set
        total_members = (select count(*) from family_members where household_id = old.household_id),
        active_members = (select count(*) from family_members
                          where household_id = old.household_id and is_cooperative_member = true),
        household_leader_id = case
          when h.household_leader_id is not null
               and not exists (select 1 from family_members m where m.id = h.household_leader_id)
            then null
          else h.household_leader_id
        end
      where h.id = old.household_id;
    end if;

    return new;
  end if;
end;
$$;
