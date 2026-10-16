-- Stream puroks to devices so the Add Member purok dropdown works offline.
-- Run once in the Supabase SQL editor (or `supabase db push`), then redeploy
-- powersync/sync-rules.yaml from the PowerSync dashboard.
alter publication powersync add table puroks;
