-- ============================================================================
-- V039: Platform role table — DB-backed superuser and app-level role storage
-- ============================================================================
-- Replaces the BFF in-memory roleAssignmentService with a persistent,
-- auditable, production-ready store for platform-level roles.
--
-- Platform roles are GLOBAL (not tenant-scoped) and NOT subject to RLS.
-- They represent application-wide privileges that Cognito groups will
-- provide in production.
--
-- The 5 app roles:
--   platform_admin     — full superuser, bypasses all entitlement checks
--   officials_admin    — manages officials across the platform
--   contest_assigner   — can create/manage contest assignments
--   league_director    — league-level administrative access
--   billing_admin      — billing and subscription management
-- ============================================================================

-- ── Lookup table for valid platform role names ──
CREATE TABLE app.platform_role_type (
    platform_role_type_id   SERIAL PRIMARY KEY,
    role_name               VARCHAR(50)  NOT NULL UNIQUE,
    description             VARCHAR(255) NOT NULL DEFAULT '',
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- Seed the 5 app roles
INSERT INTO app.platform_role_type (role_name, description) VALUES
    ('platform_admin',   'Full superuser — bypasses all entitlement checks, manages tenants and platform config'),
    ('officials_admin',  'Manages officials data and configurations across the platform'),
    ('contest_assigner', 'Can create and manage contest assignments'),
    ('league_director',  'League-level administrative access'),
    ('billing_admin',    'Billing, subscription, and invoice management');

-- ── Person ↔ platform role junction ──
-- A person can hold multiple platform roles.
-- No RLS — platform roles are global, not tenant-scoped.
CREATE TABLE app.platform_role_assignment (
    platform_role_assignment_id  SERIAL PRIMARY KEY,
    person_id                    BIGINT       NOT NULL REFERENCES app.person(person_id) ON DELETE CASCADE,
    platform_role_type_id        INTEGER      NOT NULL REFERENCES app.platform_role_type(platform_role_type_id) ON DELETE CASCADE,
    assigned_by                  BIGINT       REFERENCES app.person(person_id),  -- who granted this role (NULL = system seed)
    assigned_at                  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    notes                        TEXT,
    created_at                   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at                   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uq_platform_role_assignment UNIQUE (person_id, platform_role_type_id)
);

-- Indexes for common lookups
CREATE INDEX idx_platform_role_assignment_person
    ON app.platform_role_assignment (person_id);
CREATE INDEX idx_platform_role_assignment_type
    ON app.platform_role_assignment (platform_role_type_id);

-- ── updated_at triggers ──
CREATE TRIGGER trg_platform_role_type_updated_at
    BEFORE UPDATE ON app.platform_role_type
    FOR EACH ROW EXECUTE FUNCTION app.set_updated_at();

CREATE TRIGGER trg_platform_role_assignment_updated_at
    BEFORE UPDATE ON app.platform_role_assignment
    FOR EACH ROW EXECUTE FUNCTION app.set_updated_at();

-- ── Seed initial platform admin ──
-- Person ID 1 is the first person in the system (typically the owner).
-- This is the bootstrap record that allows the first admin to log in
-- and assign platform roles to others.
INSERT INTO app.platform_role_assignment (person_id, platform_role_type_id, notes)
SELECT 1, prt.platform_role_type_id, 'System bootstrap — initial platform administrator'
  FROM app.platform_role_type prt
 WHERE prt.role_name = 'platform_admin'
    ON CONFLICT DO NOTHING;
