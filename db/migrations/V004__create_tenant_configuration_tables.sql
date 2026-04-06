-- V004__create_tenant_configuration_tables.sql
-- Description: Create tenant configuration tables (config, license, pay rates, person mapping, sport mapping)

CREATE TABLE tenant_config (
  tenant_id BIGINT PRIMARY KEY REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  CONTEST_STATUS_ID INT REFERENCES contest_status(CONTEST_STATUS_ID),
  CONTEST_TYPE_ID INT REFERENCES contest_type(contest_type_id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE tenant_config IS 'Tenant-specific configurations (statuses, types, etc.)';

CREATE TABLE tenant_license (
  tenant_id BIGINT PRIMARY KEY REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  number_of_licenses INT NOT NULL DEFAULT 0,
  price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE tenant_license IS 'Licensing and pricing information for tenants';

CREATE TABLE tenant_pay_rate_map (
  tenant_id BIGINT PRIMARY KEY REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  rate_id INT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE tenant_pay_rate_map IS 'Maps pay rates to tenants';

CREATE TABLE tenant_person_map (
  tenant_id BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  person_id BIGINT NOT NULL REFERENCES person(PERSON_ID) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (tenant_id, person_id)
);

CREATE INDEX idx_tenant_person_map_person ON tenant_person_map(person_id);

COMMENT ON TABLE tenant_person_map IS 'Maps persons to tenants (multi-tenancy association)';

CREATE TABLE tenant_sport_map (
  tenant_id BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  sport_id INT NOT NULL REFERENCES sport(sport_id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (tenant_id, sport_id)
);

COMMENT ON TABLE tenant_sport_map IS 'Maps sports offered by tenant';
