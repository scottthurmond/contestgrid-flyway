-- V010__create_bookings_and_row_level_security.sql
-- Description: Create bookings table and enable RLS policies for multi-tenancy

-- Bookings table (for scheduling/availability tracking)
CREATE TABLE bookings (
  id BIGSERIAL PRIMARY KEY,
  tenant_id BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  address_1 VARCHAR(255),
  address_2 VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(2),
  postal_code VARCHAR(10),
  country_code VARCHAR(2),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_bookings_tenant_id ON bookings(tenant_id);

COMMENT ON TABLE bookings IS 'Booking records for venue/facility availability';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
-- Enable RLS on all tenant-scoped tables to enforce tenant isolation
-- This ensures each tenant can only access their own data via app.tenant_id session variable

ALTER TABLE address ENABLE ROW LEVEL SECURITY;
ALTER TABLE person ENABLE ROW LEVEL SECURITY;
ALTER TABLE phone ENABLE ROW LEVEL SECURITY;
ALTER TABLE venue ENABLE ROW LEVEL SECURITY;
ALTER TABLE venue_sub ENABLE ROW LEVEL SECURITY;
ALTER TABLE contest_season ENABLE ROW LEVEL SECURITY;
ALTER TABLE contest_level ENABLE ROW LEVEL SECURITY;
ALTER TABLE contest_league ENABLE ROW LEVEL SECURITY;
ALTER TABLE team ENABLE ROW LEVEL SECURITY;
ALTER TABLE contest_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_person_map ENABLE ROW LEVEL SECURITY;
ALTER TABLE contest_rates ENABLE ROW LEVEL SECURITY;

-- Address RLS policy - users can only access addresses for their tenant
CREATE POLICY address_tenant_isolation ON address
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- Person RLS policy
CREATE POLICY person_tenant_isolation ON person
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- Phone RLS policy (access phones for persons in user's tenant)
CREATE POLICY phone_tenant_isolation ON phone
  USING (PERSON_ID IN (
    SELECT PERSON_ID FROM person WHERE tenant_id = current_setting('app.tenant_id', true)::BIGINT
  ))
  WITH CHECK (PERSON_ID IN (
    SELECT PERSON_ID FROM person WHERE tenant_id = current_setting('app.tenant_id', true)::BIGINT
  ));

-- Venue RLS policy
CREATE POLICY venue_tenant_isolation ON venue
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- Venue_sub RLS policy (access sub-venues for venues in user's tenant)
CREATE POLICY venue_sub_tenant_isolation ON venue_sub
  USING (VENUE_ID IN (
    SELECT VENUE_ID FROM venue WHERE tenant_id = current_setting('app.tenant_id', true)::BIGINT
  ))
  WITH CHECK (VENUE_ID IN (
    SELECT VENUE_ID FROM venue WHERE tenant_id = current_setting('app.tenant_id', true)::BIGINT
  ));

-- Contest season RLS policy
CREATE POLICY contest_season_tenant_isolation ON contest_season
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- Contest level RLS policy
CREATE POLICY contest_level_tenant_isolation ON contest_level
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- Contest league RLS policy
CREATE POLICY contest_league_tenant_isolation ON contest_league
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- Team RLS policy
CREATE POLICY team_tenant_isolation ON team
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- Contest schedule RLS policy
CREATE POLICY contest_schedule_tenant_isolation ON contest_schedule
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- Bookings RLS policy
CREATE POLICY bookings_tenant_isolation ON bookings
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- Tenant config RLS policy
CREATE POLICY tenant_config_tenant_isolation ON tenant_config
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- Tenant person map RLS policy
CREATE POLICY tenant_person_map_tenant_isolation ON tenant_person_map
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- Contest rates RLS policy
CREATE POLICY contest_rates_tenant_isolation ON contest_rates
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

COMMENT ON POLICY address_tenant_isolation ON address IS 'Users can only access addresses belonging to their tenant';
COMMENT ON POLICY person_tenant_isolation ON person IS 'Users can only access persons belonging to their tenant';
COMMENT ON POLICY team_tenant_isolation ON team IS 'Users can only access teams belonging to their tenant';
COMMENT ON POLICY contest_schedule_tenant_isolation ON contest_schedule IS 'Users can only access contests belonging to their tenant';
