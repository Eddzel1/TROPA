-- Fix: can_collect_dues_for only matched the signed-in user by Auth id, so users whose profile
-- row has a different id (matched by email, see 20261018030000_match_profile_by_email.sql) had
-- every dues payment rejected on upload (42501), and the device then dropped it.
-- Match by Auth id, or else by the email in the token, like has_tropa_permission.

create or replace function public.can_collect_dues_for(member text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users u
    where (u.id = auth.uid() or lower(u.email) = lower(auth.jwt() ->> 'email'))
      and coalesce(u.status, 'active') = 'active'
      and (
        to_jsonb(u.permissions) ? 'system_admin'
        or (
          to_jsonb(u.permissions) ? 'dues_collection'
          and (
            (coalesce(cardinality(u.dues_barangays), 0) = 0 and to_jsonb(u.permissions) ? 'manage_users')
            or exists (
              select 1
              from public.family_members m
              join public.locations l
                on upper(trim(coalesce(l.lgu, ''))) = upper(trim(coalesce(m.lgu, '')))
               and upper(trim(coalesce(l.barangay, ''))) = upper(trim(coalesce(m.barangay, '')))
              where m.id::text = member
                and l.id::text = any (u.dues_barangays)
            )
          )
        )
      )
  );
$$;
