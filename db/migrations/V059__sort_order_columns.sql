-- V059: Add sort_order column to sport, contest_season, contest_level, contest_league
--
-- Allows users to control display ordering of these entities
-- rather than relying purely on alphabetical sort.

ALTER TABLE app.sport
  ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0;

ALTER TABLE app.contest_season
  ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0;

ALTER TABLE app.contest_level
  ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0;

ALTER TABLE app.contest_league
  ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0;
