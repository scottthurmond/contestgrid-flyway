-- V009__create_contest_rates_and_schedule_tables.sql
-- Description: Create contest_rates and contest_schedule tables

CREATE TABLE contest_rates (
  OFFICIALS_ASSOCIATION_ID BIGINT NOT NULL REFERENCES officials_association(OFFICIALS_ASSOCIATION_ID) ON DELETE CASCADE,
  tenant_id BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  SPORT_ID INT NOT NULL REFERENCES sport(sport_id) ON DELETE CASCADE,
  contest_level_id BIGINT NOT NULL REFERENCES contest_level(CONTEST_LEVEL_ID) ON DELETE RESTRICT,
  CONTEST_LEAGUE_ID BIGINT REFERENCES contest_league(CONTEST_LEAGUE_ID) ON DELETE SET NULL,
  contest_num_officials_contracted INT NOT NULL DEFAULT 1,
  contest_bill_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  contest_umpire_rate DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (OFFICIALS_ASSOCIATION_ID, tenant_id, SPORT_ID, contest_level_id)
);

CREATE INDEX idx_contest_rates_tenant ON contest_rates(tenant_id);
CREATE INDEX idx_contest_rates_association ON contest_rates(OFFICIALS_ASSOCIATION_ID);

COMMENT ON TABLE contest_rates IS 'Pay rates and contracted official counts per organization/sport/level';
COMMENT ON COLUMN contest_rates.contest_num_officials_contracted IS 'Number of officials contracted for this league';
COMMENT ON COLUMN contest_rates.contest_bill_amount IS 'Amount to bill the tenant per game';
COMMENT ON COLUMN contest_rates.contest_umpire_rate IS 'Amount to pay each official per game';

-- Contest Schedule  - the actual games/contests
CREATE TABLE contest_schedule (
  contest_schedule_id BIGSERIAL PRIMARY KEY,
  tenant_id BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  OFFICIALS_ASSOCIATION_ID BIGINT NOT NULL REFERENCES officials_association(OFFICIALS_ASSOCIATION_ID) ON DELETE RESTRICT,
  SPORT_ID INT NOT NULL REFERENCES sport(sport_id) ON DELETE RESTRICT,
  CONTEST_STATUS_ID INT NOT NULL REFERENCES contest_status(CONTEST_STATUS_ID) ON DELETE RESTRICT,
  CONTEST_TYPE_ID INT NOT NULL REFERENCES contest_type(contest_type_id) ON DELETE RESTRICT,
  contest_level_id BIGINT NOT NULL REFERENCES contest_level(CONTEST_LEVEL_ID) ON DELETE RESTRICT,
  CONTEST_LEAGUE_ID BIGINT NOT NULL REFERENCES contest_league(CONTEST_LEAGUE_ID) ON DELETE RESTRICT,
  VENUE_ID BIGINT NOT NULL REFERENCES venue(VENUE_ID) ON DELETE RESTRICT,
  SUB_VENUE_ID BIGINT NOT NULL REFERENCES venue_sub(sub_venue_id) ON DELETE RESTRICT,
  CONTEST_START_DATE DATE NOT NULL,
  CONTEST_START_TIME TIME NOT NULL,
  HOME_TEAM_ID BIGINT NOT NULL REFERENCES team(TEAM_ID) ON DELETE RESTRICT,
  VISITING_TEAM_ID BIGINT NOT NULL REFERENCES team(TEAM_ID) ON DELETE RESTRICT,
  NUMBER_OFFICIALS_REQUIRED INT NOT NULL DEFAULT 1,
  home_score SMALLINT,
  visitor_score SMALLINT,
  verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_contest_schedule_tenant_id ON contest_schedule(tenant_id);
CREATE INDEX idx_contest_schedule_start_date ON contest_schedule(CONTEST_START_DATE);
CREATE INDEX idx_contest_schedule_status ON contest_schedule(CONTEST_STATUS_ID);
CREATE INDEX idx_contest_schedule_venue_id ON contest_schedule(VENUE_ID);
CREATE INDEX idx_contest_schedule_home_team ON contest_schedule(HOME_TEAM_ID);
CREATE INDEX idx_contest_schedule_visiting_team ON contest_schedule(VISITING_TEAM_ID);
CREATE INDEX idx_contest_schedule_association ON contest_schedule(OFFICIALS_ASSOCIATION_ID);

COMMENT ON TABLE contest_schedule IS 'Individual contest events/games scheduled';
COMMENT ON COLUMN contest_schedule.visitor_score IS 'Visiting team score';
