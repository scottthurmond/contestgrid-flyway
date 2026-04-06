-- V047__customer_venue_selection.sql
-- Description: Add customer-venue association and subvenue name overrides.
--
-- Changes:
--   1. Enable pg_trgm extension for fuzzy venue search
--   2. Create customer_venue (many-to-many: tenant ↔ venue)
--   3. Create customer_venue_sub (per-tenant subvenue name overrides)
--   4. Add trigram GIN index on venue_name for fast ILIKE / similarity search
--   5. Broaden venue & venue_sub RLS to allow cross-tenant reads (for search)
--   6. Migrate existing venue rows into customer_venue (preserve associations)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 1. pg_trgm — fuzzy text-search support                       ║
-- ╚═══════════════════════════════════════════════════════════════╝
-- NOTE: pg_trgm must be created by a superuser before running this migration.
-- Run:  CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- It is assumed to already exist.

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 2. customer_venue — which venues a tenant has selected        ║
-- ╚═══════════════════════════════════════════════════════════════╝
CREATE TABLE customer_venue (
  customer_venue_id  BIGSERIAL PRIMARY KEY,
  tenant_id          BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  venue_id           BIGINT NOT NULL REFERENCES venue(VENUE_ID)   ON DELETE CASCADE,
  created_at         TIMESTAMPTZ DEFAULT now(),
  UNIQUE (tenant_id, venue_id)
);

CREATE INDEX idx_customer_venue_tenant ON customer_venue(tenant_id);
CREATE INDEX idx_customer_venue_venue  ON customer_venue(venue_id);

COMMENT ON TABLE customer_venue IS 'Many-to-many: tenants select venues for their venue list';

ALTER TABLE customer_venue ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_venue FORCE ROW LEVEL SECURITY;

CREATE POLICY customer_venue_tenant_isolation ON customer_venue
  USING (
    tenant_id = current_setting('app.tenant_id', true)::BIGINT
    OR current_setting('app.is_platform_admin', true) = 'true'
  );

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 3. customer_venue_sub — per-tenant subvenue name overrides    ║
-- ╚═══════════════════════════════════════════════════════════════╝
CREATE TABLE customer_venue_sub (
  customer_venue_sub_id  BIGSERIAL PRIMARY KEY,
  tenant_id              BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  sub_venue_id           BIGINT NOT NULL REFERENCES venue_sub(sub_venue_id) ON DELETE CASCADE,
  custom_sub_venue_name  VARCHAR(45) NOT NULL,
  created_at             TIMESTAMPTZ DEFAULT now(),
  updated_at             TIMESTAMPTZ DEFAULT now(),
  UNIQUE (tenant_id, sub_venue_id)
);

CREATE INDEX idx_customer_venue_sub_tenant ON customer_venue_sub(tenant_id);
CREATE INDEX idx_customer_venue_sub_sub    ON customer_venue_sub(sub_venue_id);

COMMENT ON TABLE customer_venue_sub IS 'Per-tenant custom names for sub-venues (overrides the global default)';

ALTER TABLE customer_venue_sub ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_venue_sub FORCE ROW LEVEL SECURITY;

CREATE POLICY customer_venue_sub_tenant_isolation ON customer_venue_sub
  USING (
    tenant_id = current_setting('app.tenant_id', true)::BIGINT
    OR current_setting('app.is_platform_admin', true) = 'true'
  );

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 4. Trigram index on venue_name for fast ILIKE search          ║
-- ╚═══════════════════════════════════════════════════════════════╝
CREATE INDEX idx_venue_name_trgm ON venue USING gin (VENUE_NAME gin_trgm_ops);

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 5. Broaden venue & venue_sub RLS for cross-tenant reads       ║
-- ╚═══════════════════════════════════════════════════════════════╝
-- Drop existing policies and recreate with read-all / write-own-tenant semantics.

-- venue: allow any authenticated user to SELECT, restrict writes to own tenant
DROP POLICY IF EXISTS venue_tenant_isolation ON venue;
DROP POLICY IF EXISTS venue_platform_admin_bypass ON venue;

CREATE POLICY venue_read_all ON venue
  FOR SELECT
  USING (true);

CREATE POLICY venue_write_own_tenant ON venue
  FOR ALL
  USING (
    tenant_id = current_setting('app.tenant_id', true)::BIGINT
    OR current_setting('app.is_platform_admin', true) = 'true'
  )
  WITH CHECK (
    tenant_id = current_setting('app.tenant_id', true)::BIGINT
    OR current_setting('app.is_platform_admin', true) = 'true'
  );

-- venue_sub: allow any authenticated user to SELECT, restrict writes via venue ownership
DROP POLICY IF EXISTS venue_sub_tenant_isolation ON venue_sub;
DROP POLICY IF EXISTS venue_sub_platform_admin_bypass ON venue_sub;

CREATE POLICY venue_sub_read_all ON venue_sub
  FOR SELECT
  USING (true);

CREATE POLICY venue_sub_write_own_tenant ON venue_sub
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM venue v
      WHERE v.VENUE_ID = venue_sub.VENUE_ID
        AND (v.tenant_id = current_setting('app.tenant_id', true)::BIGINT
             OR current_setting('app.is_platform_admin', true) = 'true')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM venue v
      WHERE v.VENUE_ID = venue_sub.VENUE_ID
        AND (v.tenant_id = current_setting('app.tenant_id', true)::BIGINT
             OR current_setting('app.is_platform_admin', true) = 'true')
    )
  );

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 6. Migrate existing venue associations into customer_venue    ║
-- ╚═══════════════════════════════════════════════════════════════╝
-- Every venue currently "belongs" to a tenant. Create a customer_venue row
-- so existing tenants continue to see their venues after this change.
-- Temporarily relax RLS for the migration insert, then re-enable.
ALTER TABLE customer_venue DISABLE ROW LEVEL SECURITY;

INSERT INTO customer_venue (tenant_id, venue_id)
SELECT tenant_id, VENUE_ID
FROM venue
ON CONFLICT DO NOTHING;

ALTER TABLE customer_venue ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_venue FORCE ROW LEVEL SECURITY;
