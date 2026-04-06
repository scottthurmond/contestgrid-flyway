-- V008__create_team_and_mapping_tables.sql
-- Description: Create team, officials_tenant_map tables

CREATE TABLE team (
  TEAM_ID BIGSERIAL PRIMARY KEY,
  tenant_id BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  CONTEST_LEAGUE_ID BIGINT NOT NULL REFERENCES contest_league(CONTEST_LEAGUE_ID) ON DELETE RESTRICT,
  contest_level_id BIGINT NOT NULL REFERENCES contest_level(CONTEST_LEVEL_ID) ON DELETE RESTRICT,
  TEAM_NAME VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_team_tenant_id ON team(tenant_id);
CREATE INDEX idx_team_league_id ON team(CONTEST_LEAGUE_ID);
CREATE INDEX idx_team_level_id ON team(contest_level_id);

COMMENT ON TABLE team IS 'Teams participating in contests';

-- Officials to Tenant mapping (which officials associations work with which tenants/sports)
CREATE TABLE officials_tenant_map (
  OFFICIALS_ASSOCIATION_ID BIGINT NOT NULL REFERENCES officials_association(OFFICIALS_ASSOCIATION_ID) ON DELETE CASCADE,
  tenant_id BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  SPORT_ID INT NOT NULL REFERENCES sport(sport_id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (OFFICIALS_ASSOCIATION_ID, tenant_id, SPORT_ID)
);

CREATE INDEX idx_officials_tenant_map_tenant ON officials_tenant_map(tenant_id);
CREATE INDEX idx_officials_tenant_map_sport ON officials_tenant_map(SPORT_ID);

COMMENT ON TABLE officials_tenant_map IS 'Maps which officials associations work with which tenants for specific sports';
