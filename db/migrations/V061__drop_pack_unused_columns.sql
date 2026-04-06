-- V061: Drop unused columns from contest_pack
-- Packs are just an ID that groups contests; no name/description/updated_at needed.
ALTER TABLE app.contest_pack DROP COLUMN IF EXISTS pack_name;
ALTER TABLE app.contest_pack DROP COLUMN IF EXISTS pack_description;
ALTER TABLE app.contest_pack DROP COLUMN IF EXISTS updated_at;
