-- V026: Add platform-admin bypass to ALL existing RLS policies + enable RLS on 5 tenant-identity tables
-- This is a prerequisite for V027-V030 which need cross-tenant data access during migration.

------------------------------------------------------------
-- PART 1: Update existing 20 table policies to add platform-admin bypass
------------------------------------------------------------

-- address
DROP POLICY IF EXISTS address_tenant_isolation ON app.address;
CREATE POLICY address_tenant_isolation ON app.address FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- bookings
DROP POLICY IF EXISTS bookings_tenant_isolation ON app.bookings;
CREATE POLICY bookings_tenant_isolation ON app.bookings FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- contest_league
DROP POLICY IF EXISTS contest_league_tenant_isolation ON app.contest_league;
CREATE POLICY contest_league_tenant_isolation ON app.contest_league FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- contest_level
DROP POLICY IF EXISTS contest_level_tenant_isolation ON app.contest_level;
CREATE POLICY contest_level_tenant_isolation ON app.contest_level FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- contest_rates
DROP POLICY IF EXISTS contest_rates_tenant_isolation ON app.contest_rates;
CREATE POLICY contest_rates_tenant_isolation ON app.contest_rates FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- contest_schedule
DROP POLICY IF EXISTS contest_schedule_tenant_isolation ON app.contest_schedule;
CREATE POLICY contest_schedule_tenant_isolation ON app.contest_schedule FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- contest_season
DROP POLICY IF EXISTS contest_season_tenant_isolation ON app.contest_season;
CREATE POLICY contest_season_tenant_isolation ON app.contest_season FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- official
DROP POLICY IF EXISTS official_tenant_isolation ON app.official;
CREATE POLICY official_tenant_isolation ON app.official FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- official_association_membership
DROP POLICY IF EXISTS oam_tenant_isolation ON app.official_association_membership;
CREATE POLICY oam_tenant_isolation ON app.official_association_membership FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- official_config
DROP POLICY IF EXISTS official_config_tenant_isolation ON app.official_config;
CREATE POLICY official_config_tenant_isolation ON app.official_config FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- official_contest_assignment
DROP POLICY IF EXISTS oca_tenant_isolation ON app.official_contest_assignment;
CREATE POLICY oca_tenant_isolation ON app.official_contest_assignment FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- officials_association
DROP POLICY IF EXISTS officials_association_tenant_isolation ON app.officials_association;
CREATE POLICY officials_association_tenant_isolation ON app.officials_association FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- payment (has 2 policies)
DROP POLICY IF EXISTS payment_tenant_isolation ON app.payment;
DROP POLICY IF EXISTS payment_tenant_insert ON app.payment;
CREATE POLICY payment_tenant_isolation ON app.payment FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- person (keep email lookup policy, update tenant isolation)
DROP POLICY IF EXISTS person_tenant_isolation ON app.person;
CREATE POLICY person_tenant_isolation ON app.person FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);
-- NOTE: person_auth_email_lookup policy (V025) left intact

-- team
DROP POLICY IF EXISTS team_tenant_isolation ON app.team;
CREATE POLICY team_tenant_isolation ON app.team FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- tenant_config
DROP POLICY IF EXISTS tenant_config_tenant_isolation ON app.tenant_config;
CREATE POLICY tenant_config_tenant_isolation ON app.tenant_config FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- tenant_person_map
DROP POLICY IF EXISTS tenant_person_map_tenant_isolation ON app.tenant_person_map;
CREATE POLICY tenant_person_map_tenant_isolation ON app.tenant_person_map FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- venue
DROP POLICY IF EXISTS venue_tenant_isolation ON app.venue;
CREATE POLICY venue_tenant_isolation ON app.venue FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- phone (subquery-based via person)
DROP POLICY IF EXISTS phone_tenant_isolation ON app.phone;
CREATE POLICY phone_tenant_isolation ON app.phone FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR person_id IN (SELECT person_id FROM app.person
                          WHERE tenant_id = current_setting('app.tenant_id', true)::BIGINT))
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR person_id IN (SELECT person_id FROM app.person
                               WHERE tenant_id = current_setting('app.tenant_id', true)::BIGINT));

-- venue_sub (subquery-based via venue)
DROP POLICY IF EXISTS venue_sub_tenant_isolation ON app.venue_sub;
CREATE POLICY venue_sub_tenant_isolation ON app.venue_sub FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR venue_id IN (SELECT venue_id FROM app.venue
                         WHERE tenant_id = current_setting('app.tenant_id', true)::BIGINT))
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR venue_id IN (SELECT venue_id FROM app.venue
                              WHERE tenant_id = current_setting('app.tenant_id', true)::BIGINT));

------------------------------------------------------------
-- PART 2: Enable RLS on 5 tenant-identity tables
------------------------------------------------------------

-- tenant (tenant_id IS the PK)
ALTER TABLE app.tenant ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.tenant FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_tenant_isolation ON app.tenant FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- tenant_license
ALTER TABLE app.tenant_license ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.tenant_license FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_license_tenant_isolation ON app.tenant_license FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- tenant_pay_rate_map
ALTER TABLE app.tenant_pay_rate_map ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.tenant_pay_rate_map FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_pay_rate_map_tenant_isolation ON app.tenant_pay_rate_map FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- tenant_sport_map
ALTER TABLE app.tenant_sport_map ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.tenant_sport_map FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_sport_map_tenant_isolation ON app.tenant_sport_map FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- officials_tenant_map
ALTER TABLE app.officials_tenant_map ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.officials_tenant_map FORCE ROW LEVEL SECURITY;
CREATE POLICY officials_tenant_map_tenant_isolation ON app.officials_tenant_map FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);
