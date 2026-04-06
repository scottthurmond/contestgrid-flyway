-- V007__create_contest_structure_tables.sql
-- Description: Create contest structure tables (season, level, league)

CREATE TABLE contest_season (
  contest_season_id BIGSERIAL PRIMARY KEY,
  tenant_id BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  contest_season_name VARCHAR(45) NOT NULL,
  contest_season_start_date DATE NOT NULL,
  contest_season_end_date DATE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_contest_season_tenant_id ON contest_season(tenant_id);
CREATE INDEX idx_contest_season_dates ON contest_season(contest_season_start_date, contest_season_end_date);

COMMENT ON TABLE contest_season IS 'Contest seasons (Spring 2026, Fall 2026, etc.)';

CREATE TABLE contest_level (
  CONTEST_LEVEL_ID BIGSERIAL PRIMARY KEY,
  tenant_id BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  OFFICIALS_ASSOCIATION_ID BIGINT NOT NULL REFERENCES officials_association(OFFICIALS_ASSOCIATION_ID) ON DELETE RESTRICT,
  CONTEST_LEVEL_NAME VARCHAR(45),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_contest_level_tenant_id ON contest_level(tenant_id);
CREATE INDEX idx_contest_level_association_id ON contest_level(OFFICIALS_ASSOCIATION_ID);

COMMENT ON TABLE contest_level IS 'Contest levels (Rec, Travel, Tournament, U10, U12, etc.)';

CREATE TABLE contest_league (
  CONTEST_LEAGUE_ID BIGSERIAL PRIMARY KEY,
  tenant_id BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  OFFICIALS_ASSOCIATION_ID BIGINT NOT NULL REFERENCES officials_association(OFFICIALS_ASSOCIATION_ID) ON DELETE RESTRICT,
  contest_level_id BIGINT NOT NULL REFERENCES contest_level(CONTEST_LEVEL_ID) ON DELETE RESTRICT,
  CONTEST_LEAGUE_NAME VARCHAR(100) NOT NULL UNIQUE,
  DEFAULT_TIME_LIMIT INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_contest_league_tenant_id ON contest_league(tenant_id);
CREATE INDEX idx_contest_league_level_id ON contest_league(contest_level_id);
CREATE INDEX idx_contest_league_association_id ON contest_league(OFFICIALS_ASSOCIATION_ID);

COMMENT ON TABLE contest_league IS 'Contest leagues (divisions within levels)';
COMMENT ON COLUMN contest_league.DEFAULT_TIME_LIMIT IS 'Default time limit for contests in this league (minutes; 0 = no limit)';
