-- ============================================================================
-- V051  Create proper customer table, migrate data off fake tenant records
-- ============================================================================
-- Previously a "customer" was represented as a tenant row linked via
-- officials_tenant_map.  Now customers get their own first-class table and
-- child entities (levels, leagues, seasons, teams, venues, rates) are
-- scoped to customer_id instead of the fake tenant_id.
--
-- Run with:  psql --single-transaction -f V051__customer_table.sql
-- ============================================================================

-- ── 1. Create customer table ────────────────────────────────────────────────

CREATE TABLE app.customer (
  customer_id               SERIAL        PRIMARY KEY,
  customer_name             VARCHAR(255)  NOT NULL,
  customer_abbreviation     VARCHAR(50),
  officials_association_id  BIGINT        NOT NULL
      REFERENCES app.officials_association(officials_association_id) ON DELETE RESTRICT,
  tenant_id                 BIGINT        NOT NULL
      REFERENCES app.tenant(tenant_id) ON DELETE CASCADE,
  is_active                 BOOLEAN       NOT NULL DEFAULT true,
  created_at                TIMESTAMPTZ   DEFAULT NOW(),
  updated_at                TIMESTAMPTZ   DEFAULT NOW(),
  _legacy_tenant_id         BIGINT        -- temp column for data migration
);

ALTER TABLE app.customer ENABLE ROW LEVEL SECURITY;

CREATE POLICY customer_tenant_isolation ON app.customer
  FOR ALL
  USING (
    current_setting('app.is_platform_admin', true) = 'true'
    OR tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::BIGINT
  )
  WITH CHECK (
    current_setting('app.is_platform_admin', true) = 'true'
    OR tenant_id = current_setting('app.tenant_id', true)::BIGINT
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON app.customer TO contestgrid_lab_id;
GRANT USAGE, SELECT ON SEQUENCE app.customer_customer_id_seq TO contestgrid_lab_id;


-- ── 2. Create customer_sport_map ────────────────────────────────────────────

CREATE TABLE app.customer_sport_map (
  customer_id   INT     NOT NULL REFERENCES app.customer(customer_id) ON DELETE CASCADE,
  sport_id      INT     NOT NULL REFERENCES app.sport(sport_id)      ON DELETE CASCADE,
  tenant_id     BIGINT  NOT NULL REFERENCES app.tenant(tenant_id)    ON DELETE CASCADE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (customer_id, sport_id)
);

ALTER TABLE app.customer_sport_map ENABLE ROW LEVEL SECURITY;

CREATE POLICY customer_sport_map_tenant_isolation ON app.customer_sport_map
  FOR ALL
  USING (
    current_setting('app.is_platform_admin', true) = 'true'
    OR tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::BIGINT
  )
  WITH CHECK (
    current_setting('app.is_platform_admin', true) = 'true'
    OR tenant_id = current_setting('app.tenant_id', true)::BIGINT
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON app.customer_sport_map TO contestgrid_lab_id;


-- ── 3. Seed customer rows from officials_tenant_map ─────────────────────────

INSERT INTO app.customer
       (customer_name, customer_abbreviation, officials_association_id,
        tenant_id, is_active, _legacy_tenant_id)
SELECT t.tenant_name,
       t.tenant_abbreviation,
       sub.officials_association_id,
       oa.tenant_id,
       t.is_active,
       sub.old_tenant_id
FROM (
  SELECT DISTINCT officials_association_id, tenant_id AS old_tenant_id
  FROM app.officials_tenant_map
) sub
JOIN app.tenant t                ON t.tenant_id = sub.old_tenant_id
JOIN app.officials_association oa ON oa.officials_association_id = sub.officials_association_id;

-- ── 4. Seed customer_sport_map ──────────────────────────────────────────────

INSERT INTO app.customer_sport_map (customer_id, sport_id, tenant_id)
SELECT c.customer_id, otm.sport_id, c.tenant_id
FROM app.officials_tenant_map otm
JOIN app.customer c
  ON  c._legacy_tenant_id = otm.tenant_id
  AND c.officials_association_id = otm.officials_association_id;


-- ── 5. Add customer_id column to child tables ───────────────────────────────

ALTER TABLE app.contest_level      ADD COLUMN customer_id INT;
ALTER TABLE app.contest_league     ADD COLUMN customer_id INT;
ALTER TABLE app.contest_season     ADD COLUMN customer_id INT;
ALTER TABLE app.team               ADD COLUMN customer_id INT;
ALTER TABLE app.customer_venue     ADD COLUMN customer_id INT;
ALTER TABLE app.customer_venue_sub ADD COLUMN customer_id INT;
ALTER TABLE app.contest_rates      ADD COLUMN customer_id INT;


-- ── 6. Populate customer_id on child rows (match via old tenant_id) ─────────

UPDATE app.contest_level cl   SET customer_id = c.customer_id FROM app.customer c WHERE c._legacy_tenant_id = cl.tenant_id;
UPDATE app.contest_league cl  SET customer_id = c.customer_id FROM app.customer c WHERE c._legacy_tenant_id = cl.tenant_id;
UPDATE app.contest_season cs  SET customer_id = c.customer_id FROM app.customer c WHERE c._legacy_tenant_id = cs.tenant_id;
UPDATE app.team t             SET customer_id = c.customer_id FROM app.customer c WHERE c._legacy_tenant_id = t.tenant_id;
UPDATE app.customer_venue cv  SET customer_id = c.customer_id FROM app.customer c WHERE c._legacy_tenant_id = cv.tenant_id;
UPDATE app.customer_venue_sub cvs SET customer_id = c.customer_id FROM app.customer c WHERE c._legacy_tenant_id = cvs.tenant_id;
UPDATE app.contest_rates cr   SET customer_id = c.customer_id FROM app.customer c WHERE c._legacy_tenant_id = cr.tenant_id;


-- ── 7. Delete orphan rows that belong to association tenants directly ────────
-- These rows were created without a customer context.  They have NULL
-- customer_id because their tenant_id is the association itself (not a
-- customer fake-tenant).

DELETE FROM app.team              WHERE customer_id IS NULL;
DELETE FROM app.contest_league    WHERE customer_id IS NULL;
DELETE FROM app.contest_level     WHERE customer_id IS NULL;
DELETE FROM app.contest_season    WHERE customer_id IS NULL;
DELETE FROM app.customer_venue    WHERE customer_id IS NULL;
DELETE FROM app.customer_venue_sub WHERE customer_id IS NULL;
DELETE FROM app.contest_rates     WHERE customer_id IS NULL;


-- ── 8. Drop OLD unique / exclusion constraints ──────────────────────────────
-- Must happen BEFORE changing tenant_id to avoid collisions.

ALTER TABLE app.contest_level      DROP CONSTRAINT uq_contest_level_tenant_sport_name;
ALTER TABLE app.contest_league     DROP CONSTRAINT uq_contest_league_tenant_level_name;
ALTER TABLE app.contest_season     DROP CONSTRAINT uq_contest_season_tenant_sport_name;
ALTER TABLE app.team               DROP CONSTRAINT uq_team_tenant_level_league_name;
ALTER TABLE app.customer_venue     DROP CONSTRAINT customer_venue_tenant_id_venue_id_key;
ALTER TABLE app.customer_venue_sub DROP CONSTRAINT customer_venue_sub_tenant_id_sub_venue_id_key;
ALTER TABLE app.contest_rates      DROP CONSTRAINT contest_rates_no_overlap;


-- ── 9. Update tenant_id → association's real tenant ─────────────────────────

UPDATE app.contest_level cl   SET tenant_id = c.tenant_id FROM app.customer c WHERE c.customer_id = cl.customer_id;
UPDATE app.contest_league cl  SET tenant_id = c.tenant_id FROM app.customer c WHERE c.customer_id = cl.customer_id;
UPDATE app.contest_season cs  SET tenant_id = c.tenant_id FROM app.customer c WHERE c.customer_id = cs.customer_id;
UPDATE app.team t             SET tenant_id = c.tenant_id FROM app.customer c WHERE c.customer_id = t.customer_id;
UPDATE app.customer_venue cv  SET tenant_id = c.tenant_id FROM app.customer c WHERE c.customer_id = cv.customer_id;
UPDATE app.customer_venue_sub cvs SET tenant_id = c.tenant_id FROM app.customer c WHERE c.customer_id = cvs.customer_id;
UPDATE app.contest_rates cr   SET tenant_id = c.tenant_id FROM app.customer c WHERE c.customer_id = cr.customer_id;


-- ── 10. Make customer_id NOT NULL + FK ──────────────────────────────────────

ALTER TABLE app.contest_level      ALTER COLUMN customer_id SET NOT NULL,
  ADD CONSTRAINT contest_level_customer_id_fkey      FOREIGN KEY (customer_id) REFERENCES app.customer(customer_id) ON DELETE CASCADE;
ALTER TABLE app.contest_league     ALTER COLUMN customer_id SET NOT NULL,
  ADD CONSTRAINT contest_league_customer_id_fkey     FOREIGN KEY (customer_id) REFERENCES app.customer(customer_id) ON DELETE CASCADE;
ALTER TABLE app.contest_season     ALTER COLUMN customer_id SET NOT NULL,
  ADD CONSTRAINT contest_season_customer_id_fkey     FOREIGN KEY (customer_id) REFERENCES app.customer(customer_id) ON DELETE CASCADE;
ALTER TABLE app.team               ALTER COLUMN customer_id SET NOT NULL,
  ADD CONSTRAINT team_customer_id_fkey               FOREIGN KEY (customer_id) REFERENCES app.customer(customer_id) ON DELETE CASCADE;
ALTER TABLE app.customer_venue     ALTER COLUMN customer_id SET NOT NULL,
  ADD CONSTRAINT customer_venue_customer_id_fkey     FOREIGN KEY (customer_id) REFERENCES app.customer(customer_id) ON DELETE CASCADE;
ALTER TABLE app.customer_venue_sub ALTER COLUMN customer_id SET NOT NULL,
  ADD CONSTRAINT customer_venue_sub_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES app.customer(customer_id) ON DELETE CASCADE;
ALTER TABLE app.contest_rates      ALTER COLUMN customer_id SET NOT NULL,
  ADD CONSTRAINT contest_rates_customer_id_fkey      FOREIGN KEY (customer_id) REFERENCES app.customer(customer_id) ON DELETE CASCADE;


-- ── 11. Add NEW unique / exclusion constraints (customer_id) ────────────────

ALTER TABLE app.contest_level ADD CONSTRAINT uq_contest_level_customer_sport_name
  UNIQUE (customer_id, sport_id, contest_level_name);

ALTER TABLE app.contest_league ADD CONSTRAINT uq_contest_league_customer_level_name
  UNIQUE (customer_id, contest_level_id, contest_league_name);

ALTER TABLE app.contest_season ADD CONSTRAINT uq_contest_season_customer_sport_name
  UNIQUE (customer_id, sport_id, contest_season_name);

ALTER TABLE app.team ADD CONSTRAINT uq_team_customer_level_league_name
  UNIQUE (customer_id, contest_level_id, contest_league_id, team_name);

ALTER TABLE app.customer_venue ADD CONSTRAINT customer_venue_customer_id_venue_id_key
  UNIQUE (customer_id, venue_id);

ALTER TABLE app.customer_venue_sub ADD CONSTRAINT customer_venue_sub_customer_id_sub_venue_id_key
  UNIQUE (customer_id, sub_venue_id);

ALTER TABLE app.contest_rates ADD CONSTRAINT contest_rates_no_overlap
  EXCLUDE USING gist (
    officials_association_id WITH =,
    customer_id             WITH =,
    sport_id                WITH =,
    contest_level_id        WITH =,
    contest_league_id       WITH =,
    daterange(effective_start_date,
              COALESCE(effective_end_date, '9999-12-31'::date),
              '[]') WITH &&
  );


-- ── 12. Drop _legacy_tenant_id ──────────────────────────────────────────────

ALTER TABLE app.customer DROP COLUMN _legacy_tenant_id;


-- ── 13. Clean up fake customer tenants ──────────────────────────────────────

UPDATE app.tenant
   SET tenant_type_id = 1, updated_at = NOW()
 WHERE tenant_id IN (SELECT DISTINCT tenant_id FROM app.officials_tenant_map);

DELETE FROM app.tenant_type
 WHERE tenant_id IN (SELECT DISTINCT tenant_id FROM app.officials_tenant_map);

UPDATE app.tenant
   SET is_active = false, updated_at = NOW()
 WHERE tenant_id IN (SELECT DISTINCT tenant_id FROM app.officials_tenant_map);


-- ── 14. Drop officials_tenant_map ──────────────────────────────────────────

DROP TABLE app.officials_tenant_map;
