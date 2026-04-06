-- V031__add_sport_fk_and_unique_constraints.sql
-- Description: Add sport_id FK to contest_season and contest_level,
--   fix unique constraints to match domain model:
--   - Seasons per sport per tenant
--   - Levels per sport per tenant
--   - Leagues per level per tenant (not globally unique)
--   - Teams unique per tenant + level + league + name

-- ═══════════════════════════════════════════════════════════════
-- 1. Add sport_id to contest_season
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE contest_season
  ADD COLUMN sport_id INTEGER REFERENCES sport(sport_id) ON DELETE RESTRICT;

CREATE INDEX idx_contest_season_sport_id ON contest_season(sport_id);

COMMENT ON COLUMN contest_season.sport_id IS 'Sport this season belongs to (Baseball spring, Baseball summer, etc.)';

-- ═══════════════════════════════════════════════════════════════
-- 2. Add sport_id to contest_level
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE contest_level
  ADD COLUMN sport_id INTEGER REFERENCES sport(sport_id) ON DELETE RESTRICT;

CREATE INDEX idx_contest_level_sport_id ON contest_level(sport_id);

COMMENT ON COLUMN contest_level.sport_id IS 'Sport this level belongs to (Baseball Rec, Baseball Travel, etc.)';

-- ═══════════════════════════════════════════════════════════════
-- 3. Fix contest_league unique constraint
--    Was: UNIQUE(contest_league_name) globally
--    Now: UNIQUE(tenant_id, contest_level_id, contest_league_name)
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE contest_league
  DROP CONSTRAINT contest_league_contest_league_name_key;

ALTER TABLE contest_league
  ADD CONSTRAINT uq_contest_league_tenant_level_name
  UNIQUE (tenant_id, contest_level_id, contest_league_name);

-- ═══════════════════════════════════════════════════════════════
-- 4. Add unique constraints
-- ═══════════════════════════════════════════════════════════════

-- Season name unique per tenant + sport
ALTER TABLE contest_season
  ADD CONSTRAINT uq_contest_season_tenant_sport_name
  UNIQUE (tenant_id, sport_id, contest_season_name);

-- Level name unique per tenant + sport
ALTER TABLE contest_level
  ADD CONSTRAINT uq_contest_level_tenant_sport_name
  UNIQUE (tenant_id, sport_id, contest_level_name);

-- Team name unique per tenant + level + league
ALTER TABLE team
  ADD CONSTRAINT uq_team_tenant_level_league_name
  UNIQUE (tenant_id, contest_level_id, contest_league_id, team_name);
