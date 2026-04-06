-- V057: Add default_officials_required to contest_league
ALTER TABLE app.contest_league
  ADD COLUMN default_officials_required SMALLINT NOT NULL DEFAULT 2;

COMMENT ON COLUMN app.contest_league.default_officials_required
  IS 'Default number of officials required for contests in this league';
