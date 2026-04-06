-- V040: Tenant Admin role & per-person entitlement overrides
--
-- Requirements:
--   1. Platform admin controls DEFAULT CRUD access per role (role_entitlement).
--   2. "Tenant Admin" is the superuser within a tenant account.
--      They can assign roles to people and customise per-person entitlements.
--   3. Per-person overrides let a tenant admin grant or revoke specific
--      entitlements beyond the role defaults.
--
-- Changes:
--   a) Add is_admin_role flag to app.roles
--   b) Seed "Tenant Admin" role for every tenant (is_admin_role = TRUE)
--   c) Grant all entitlements to the Tenant Admin role in every tenant
--   d) Create app.person_entitlement_override table
-- ---------------------------------------------------------------------------

-- Bypass RLS for this transaction
SELECT set_config('app.is_platform_admin', 'true', false);

-- =========================================================================
-- 1. Add is_admin_role flag to app.roles
-- =========================================================================
ALTER TABLE app.roles
  ADD COLUMN is_admin_role BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN app.roles.is_admin_role
  IS 'When TRUE this role grants tenant-admin privileges (manage roles, person overrides, etc).';

-- =========================================================================
-- 2. Seed "Tenant Admin" role for every existing tenant
-- =========================================================================
INSERT INTO app.roles (role_description, tenant_id, is_admin_role)
SELECT 'Tenant Admin', t.tenant_id, TRUE
  FROM app.tenant t
ON CONFLICT ON CONSTRAINT roles_desc_tenant_uq DO NOTHING;

-- =========================================================================
-- 3. Grant ALL entitlements to Tenant Admin role in every tenant
-- =========================================================================
INSERT INTO app.role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM app.roles r
 CROSS JOIN app.entitlement e
 WHERE r.role_description = 'Tenant Admin'
ON CONFLICT ON CONSTRAINT uq_role_entitlement DO NOTHING;

-- =========================================================================
-- 4. app.person_entitlement_override — per-person grant / revoke
-- =========================================================================
CREATE TABLE IF NOT EXISTS app.person_entitlement_override (
    person_entitlement_override_id  SERIAL       PRIMARY KEY,
    person_id                       BIGINT       NOT NULL REFERENCES app.person(person_id) ON DELETE CASCADE,
    tenant_id                       BIGINT       NOT NULL REFERENCES app.tenant(tenant_id),
    entitlement_id                  INTEGER      NOT NULL REFERENCES app.entitlement(entitlement_id) ON DELETE CASCADE,
    override_type                   VARCHAR(10)  NOT NULL CHECK (override_type IN ('grant', 'revoke')),
    granted_by                      BIGINT       REFERENCES app.person(person_id),
    notes                           TEXT,
    created_at                      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at                      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uq_person_entitlement_override UNIQUE (person_id, tenant_id, entitlement_id)
);

COMMENT ON TABLE app.person_entitlement_override
  IS 'Per-person entitlement overrides. Tenant admins use these to grant or revoke specific CRUD access beyond the role defaults.';
COMMENT ON COLUMN app.person_entitlement_override.override_type
  IS '''grant'' adds an entitlement the person would not normally have; ''revoke'' removes one they would.';

-- RLS — tenant-scoped with platform-admin bypass
ALTER TABLE app.person_entitlement_override ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.person_entitlement_override FORCE ROW LEVEL SECURITY;

CREATE POLICY person_entitlement_override_tenant_isolation
    ON app.person_entitlement_override FOR ALL
    USING (
        current_setting('app.is_platform_admin', true) = 'true'
        OR tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::bigint
    );

GRANT SELECT, INSERT, UPDATE, DELETE ON app.person_entitlement_override TO contestgrid_lab_id;
GRANT USAGE, SELECT ON SEQUENCE app.person_entitlement_override_person_entitlement_override_id_seq TO contestgrid_lab_id;

-- Indexes
CREATE INDEX idx_person_ent_override_person   ON app.person_entitlement_override(person_id);
CREATE INDEX idx_person_ent_override_tenant   ON app.person_entitlement_override(tenant_id);
CREATE INDEX idx_person_ent_override_ent      ON app.person_entitlement_override(entitlement_id);

-- updated_at trigger
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON app.person_entitlement_override
    FOR EACH ROW
    EXECUTE FUNCTION app.set_updated_at();

-- Reset
SELECT set_config('app.is_platform_admin', '', false);
