-- ============================================================================
-- V023: Enable Row-Level Security on all officials-domain tables
--
-- Adds tenant_id to tables that lack it, backfills from related data,
-- enables RLS, and creates tenant-isolation policies using the same
-- pattern as V010 (current_setting('app.tenant_id', true)::BIGINT).
-- ============================================================================

-- ── 1. officials_association ─────────────────────────────────────────────────
-- Already has tenant_id (V020).  Just enable RLS + policy.
ALTER TABLE app.officials_association ENABLE ROW LEVEL SECURITY;

CREATE POLICY officials_association_tenant_isolation ON app.officials_association
  FOR ALL
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- ── 2. official ──────────────────────────────────────────────────────────────
-- Add tenant_id, backfill from person.tenant_id via official.person_id
ALTER TABLE app.official ADD COLUMN IF NOT EXISTS tenant_id BIGINT;

UPDATE app.official o
SET tenant_id = p.tenant_id
FROM app.person p
WHERE o.person_id = p.person_id
  AND o.tenant_id IS NULL;

ALTER TABLE app.official
  ALTER COLUMN tenant_id SET NOT NULL;

ALTER TABLE app.official
  ADD CONSTRAINT fk_official_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);

CREATE INDEX IF NOT EXISTS idx_official_tenant_id ON app.official(tenant_id);

ALTER TABLE app.official ENABLE ROW LEVEL SECURITY;

CREATE POLICY official_tenant_isolation ON app.official
  FOR ALL
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- ── 3. official_config ───────────────────────────────────────────────────────
-- Add tenant_id, backfill from official → person
ALTER TABLE app.official_config ADD COLUMN IF NOT EXISTS tenant_id BIGINT;

UPDATE app.official_config oc
SET tenant_id = p.tenant_id
FROM app.official o
JOIN app.person p ON o.person_id = p.person_id
WHERE oc.official_config_id = o.official_config_id
  AND oc.tenant_id IS NULL;

ALTER TABLE app.official_config
  ALTER COLUMN tenant_id SET NOT NULL;

ALTER TABLE app.official_config
  ADD CONSTRAINT fk_official_config_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);

CREATE INDEX IF NOT EXISTS idx_official_config_tenant_id ON app.official_config(tenant_id);

ALTER TABLE app.official_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY official_config_tenant_isolation ON app.official_config
  FOR ALL
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- ── 4. official_association_membership ────────────────────────────────────────
-- Add tenant_id, backfill from officials_association.tenant_id
ALTER TABLE app.official_association_membership ADD COLUMN IF NOT EXISTS tenant_id BIGINT;

UPDATE app.official_association_membership oam
SET tenant_id = oa.tenant_id
FROM app.officials_association oa
WHERE oam.officials_association_id = oa.officials_association_id
  AND oam.tenant_id IS NULL;

ALTER TABLE app.official_association_membership
  ALTER COLUMN tenant_id SET NOT NULL;

ALTER TABLE app.official_association_membership
  ADD CONSTRAINT fk_oam_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);

CREATE INDEX IF NOT EXISTS idx_oam_tenant_id ON app.official_association_membership(tenant_id);

ALTER TABLE app.official_association_membership ENABLE ROW LEVEL SECURITY;

CREATE POLICY oam_tenant_isolation ON app.official_association_membership
  FOR ALL
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- ── 5. official_contest_assignment ───────────────────────────────────────────
-- Add tenant_id, backfill from contest_schedule.tenant_id
ALTER TABLE app.official_contest_assignment ADD COLUMN IF NOT EXISTS tenant_id BIGINT;

UPDATE app.official_contest_assignment oca
SET tenant_id = cs.tenant_id
FROM app.contest_schedule cs
WHERE oca.contest_schedule_id = cs.contest_schedule_id
  AND oca.tenant_id IS NULL;

ALTER TABLE app.official_contest_assignment
  ALTER COLUMN tenant_id SET NOT NULL;

ALTER TABLE app.official_contest_assignment
  ADD CONSTRAINT fk_oca_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);

CREATE INDEX IF NOT EXISTS idx_oca_tenant_id ON app.official_contest_assignment(tenant_id);

ALTER TABLE app.official_contest_assignment ENABLE ROW LEVEL SECURITY;

CREATE POLICY oca_tenant_isolation ON app.official_contest_assignment
  FOR ALL
  USING (tenant_id = current_setting('app.tenant_id', true)::BIGINT);
