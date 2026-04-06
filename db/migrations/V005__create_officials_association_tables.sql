-- V005__create_officials_association_tables.sql
-- Description: Create officials association and related tables (config, slots, etc.)

CREATE TABLE officials_association (
  OFFICIALS_ASSOCIATION_ID BIGSERIAL PRIMARY KEY,
  OFFICIALS_ASSOCIATION_NAME VARCHAR(100) NOT NULL UNIQUE,
  OFFICIALS_ASSOCIATION_ABBREVIATION VARCHAR(10) NOT NULL,
  ADDRESS_ID BIGINT NOT NULL REFERENCES address(address_id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_officials_association_address ON officials_association(ADDRESS_ID);

COMMENT ON TABLE officials_association IS 'Officials associations (umpire associations, etc.)';

CREATE TABLE official_config (
  OFFICIAL_CONFIG_ID BIGSERIAL PRIMARY KEY,
  UNIFORM_NUMBER VARCHAR(45),
  ASSOCIATION_JOINED_DATE DATE NOT NULL,
  contest_schedule_joined_ts TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE official_config IS 'Official-specific configuration (uniform number, join dates)';

CREATE TABLE official (
  OFFICIAL_ID BIGSERIAL PRIMARY KEY,
  PERSON_ID BIGINT NOT NULL REFERENCES person(PERSON_ID) ON DELETE CASCADE,
  OFFICIAL_CONFIG_ID BIGINT NOT NULL REFERENCES official_config(OFFICIAL_CONFIG_ID) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_official_person_id ON official(PERSON_ID);
CREATE INDEX idx_official_config_id ON official(OFFICIAL_CONFIG_ID);

COMMENT ON TABLE official IS 'Officials in the system (umpires, referees, etc.)';

CREATE TABLE official_slots (
  OFFICIAL_ASSOCIATION_ID BIGINT NOT NULL REFERENCES officials_association(OFFICIALS_ASSOCIATION_ID) ON DELETE CASCADE,
  SLOT_NAME VARCHAR(45) NOT NULL,
  SPORT_ID INT NOT NULL REFERENCES sport(sport_id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (OFFICIAL_ASSOCIATION_ID, SPORT_ID),
  UNIQUE (SLOT_NAME)
);

COMMENT ON TABLE official_slots IS 'Role slots assigned to officials associations (e.g., umpire, scorer)';
