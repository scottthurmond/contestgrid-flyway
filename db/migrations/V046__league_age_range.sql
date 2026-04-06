-- V046: Add age range columns to contest_league
-- Allows specifying min/max player age for a league (e.g. TeeBall = 5-6, Coach Pitch = 4)

ALTER TABLE app.contest_league
  ADD COLUMN min_age smallint,
  ADD COLUMN max_age smallint;

COMMENT ON COLUMN app.contest_league.min_age IS 'Minimum player age allowed in this league';
COMMENT ON COLUMN app.contest_league.max_age IS 'Maximum player age allowed in this league';

-- Ensure min_age <= max_age when both are set
ALTER TABLE app.contest_league
  ADD CONSTRAINT chk_league_age_range CHECK (min_age IS NULL OR max_age IS NULL OR min_age <= max_age);
