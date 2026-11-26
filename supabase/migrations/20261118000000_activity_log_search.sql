-- Audit Logs search looks inside each entry's details, so a deleted household or member can be
-- found by name ("DELA CRUZ", "JUAN"). search_text is the user, action, record type, record ID and
-- the details JSON in lower case, kept up to date by Postgres. details may be jsonb or a JSON
-- string; either way its text holds the names.
-- Run once in the Supabase SQL editor (or `supabase db push`). Until it is run, the app falls back
-- to searching without details.

alter table public.activity_logs
  add column if not exists search_text text generated always as (
    lower(
      coalesce(user_name, '') || ' ' ||
      coalesce(action, '') || ' ' ||
      coalesce(entity_type, '') || ' ' ||
      coalesce(entity_id::text, '') || ' ' ||
      coalesce(details::text, '')
    )
  ) stored;

-- Substring search (ilike '%dela cruz%') over every log stays fast with a trigram index.
create extension if not exists pg_trgm;
create index if not exists activity_logs_search_text_trgm
  on public.activity_logs using gin (search_text gin_trgm_ops);
