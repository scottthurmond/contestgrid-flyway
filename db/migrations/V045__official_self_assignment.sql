-- ============================================================
-- V045: Official Self-Assignment (ADR-0040)
-- ============================================================
-- Adds:
--   1. Global toggle on officials_association
--   2. Per-official toggle on official_config
--   3. self_assign_restriction table
--   4. New entitlements: self-assign:read, self-assign:write
--   5. Seed entitlements into role_entitlement for admin roles
-- ============================================================

SET search_path TO app, public;

-- Bypass RLS for data modifications
SELECT set_config('app.is_platform_admin', 'true', false);


-- ============================================================
-- 1. Global toggle on officials_association
-- ============================================================

ALTER TABLE officials_association
    ADD COLUMN self_assign_enabled BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN officials_association.self_assign_enabled
    IS 'When false, no official in this association may self-assign. When true, per-official settings govern. (ADR-0040 §1)';


-- ============================================================
-- 2. Per-official toggle on official_config
-- ============================================================

ALTER TABLE official_config
    ADD COLUMN is_self_assign_enabled BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN official_config.is_self_assign_enabled
    IS 'Whether this official may self-assign when the association global toggle is also on. (ADR-0040 §2)';


-- ============================================================
-- 3. Self-assign restriction rules table
-- ============================================================

CREATE TABLE self_assign_restriction (
    self_assign_restriction_id BIGSERIAL     PRIMARY KEY,
    official_id                BIGINT        NOT NULL REFERENCES official(official_id) ON DELETE CASCADE,
    sport_id                   INTEGER       REFERENCES sport(sport_id),
    venue_id                   BIGINT        REFERENCES venue(venue_id),
    contest_level_id           BIGINT        REFERENCES contest_level(contest_level_id),
    contest_league_id          BIGINT        REFERENCES contest_league(contest_league_id),
    max_tier                   SMALLINT,
    tenant_id                  BIGINT        NOT NULL REFERENCES tenant(tenant_id),
    created_at                 TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at                 TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT chk_max_tier_range CHECK (max_tier IS NULL OR max_tier BETWEEN 1 AND 10)
);

-- Prevent duplicate rules (NULLs treated as equivalent via COALESCE)
CREATE UNIQUE INDEX uq_self_assign_restriction
    ON self_assign_restriction (
        official_id,
        COALESCE(sport_id, -1),
        COALESCE(venue_id, -1),
        COALESCE(contest_level_id, -1),
        COALESCE(contest_league_id, -1)
    );

CREATE INDEX idx_self_assign_restriction_official
    ON self_assign_restriction (official_id);

COMMENT ON TABLE  self_assign_restriction IS 'Whitelist rules governing what an official may self-assign to (ADR-0040 §3). Zero rows = unrestricted.';
COMMENT ON COLUMN self_assign_restriction.max_tier IS 'Official must hold tier <= this in the level+division to self-assign. NULL = no tier check.';


-- ============================================================
-- 4. RLS for self_assign_restriction
-- ============================================================

ALTER TABLE self_assign_restriction ENABLE ROW LEVEL SECURITY;
ALTER TABLE self_assign_restriction FORCE  ROW LEVEL SECURITY;

CREATE POLICY self_assign_restriction_tenant_isolation
    ON self_assign_restriction FOR ALL
    USING  (current_setting('app.is_platform_admin', true) = 'true'
            OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
    WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
                OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);


-- ============================================================
-- 5. updated_at trigger
-- ============================================================

CREATE TRIGGER trg_set_updated_at
    BEFORE UPDATE ON self_assign_restriction
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();


-- ============================================================
-- 6. Seed entitlements: self-assign:read, self-assign:write
-- ============================================================

INSERT INTO entitlement (resource_name, operation, entitlement_key, description, display_order)
VALUES
    ('self-assign', 'read',  'self-assign:read',  'View self-assignment configuration', 69),
    ('self-assign', 'write', 'self-assign:write', 'Manage self-assignment settings and restrictions', 70);

-- Grant to Primary Assigner Admin (full access)
INSERT INTO role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM roles r
 CROSS JOIN entitlement e
 WHERE r.role_description = 'Primary Assigner Admin'
   AND e.resource_name = 'self-assign'
ON CONFLICT ON CONSTRAINT uq_role_entitlement DO NOTHING;

-- Grant self-assign:read to Secondary Assigner Admin
INSERT INTO role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM roles r
 CROSS JOIN entitlement e
 WHERE r.role_description = 'Secondary Assigner Admin'
   AND e.entitlement_key = 'self-assign:read'
ON CONFLICT ON CONSTRAINT uq_role_entitlement DO NOTHING;

-- Grant self-assign:write to Secondary Assigner Admin too (they manage officials)
INSERT INTO role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM roles r
 CROSS JOIN entitlement e
 WHERE r.role_description = 'Secondary Assigner Admin'
   AND e.entitlement_key = 'self-assign:write'
ON CONFLICT ON CONSTRAINT uq_role_entitlement DO NOTHING;


-- ============================================================
-- 7. Reset platform admin bypass
-- ============================================================

SELECT set_config('app.is_platform_admin', '', false);
