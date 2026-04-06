-- V037: Entitlement-based RBAC system
--
-- Adds fine-grained CRUD entitlements that are mapped to the existing
-- tenant-scoped roles.  The entitlement *definitions* are global
-- (like phone_type) while the role↔entitlement *mappings* are
-- tenant-scoped so each tenant can tailor what their roles can do.
--
-- Tables created:
--   app.entitlement          – global lookup (resource:operation pairs)
--   app.role_entitlement     – tenant-scoped junction (role ↔ entitlement)
--
-- See ADR 0034 for design rationale.
-- ---------------------------------------------------------------------------

-- =========================================================================
-- 1. app.entitlement — global definition table (no RLS)
-- =========================================================================
CREATE TABLE IF NOT EXISTS app.entitlement (
    entitlement_id   SERIAL       PRIMARY KEY,
    resource_name    VARCHAR(100) NOT NULL,
    operation        VARCHAR(20)  NOT NULL,
    entitlement_key  VARCHAR(150) NOT NULL UNIQUE,
    description      VARCHAR(255),
    display_order    INTEGER      NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uq_entitlement_resource_op UNIQUE (resource_name, operation)
);

COMMENT ON TABLE  app.entitlement IS 'Global catalogue of fine-grained CRUD entitlements (resource:operation pairs).';
COMMENT ON COLUMN app.entitlement.entitlement_key IS 'Canonical key used in middleware checks, e.g. officials:create.';
COMMENT ON COLUMN app.entitlement.resource_name IS 'Logical resource area, e.g. officials, contests, billing.';
COMMENT ON COLUMN app.entitlement.operation IS 'CRUD operation: create, read, update, delete.';

-- No RLS — global lookup table (same pattern as phone_type)
GRANT SELECT ON app.entitlement TO contestgrid_lab_id;

-- updated_at trigger (V033 pattern)
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON app.entitlement
    FOR EACH ROW
    EXECUTE FUNCTION app.set_updated_at();

-- =========================================================================
-- 2. Seed entitlement definitions
-- =========================================================================
-- Resource areas derived from existing route structure.
-- Each resource gets create / read / update / delete.
INSERT INTO app.entitlement (resource_name, operation, entitlement_key, description, display_order) VALUES
  -- tenants (platform-level, rarely assigned to tenant roles)
  ('tenants',      'create', 'tenants:create',      'Create new tenants',                      1),
  ('tenants',      'read',   'tenants:read',         'View tenant details',                     2),
  ('tenants',      'update', 'tenants:update',       'Update tenant settings',                  3),
  ('tenants',      'delete', 'tenants:delete',       'Delete / deactivate tenants',             4),
  -- persons
  ('persons',      'create', 'persons:create',       'Create person records',                  10),
  ('persons',      'read',   'persons:read',         'View person records',                    11),
  ('persons',      'update', 'persons:update',       'Update person records',                  12),
  ('persons',      'delete', 'persons:delete',       'Delete person records',                  13),
  -- customers
  ('customers',    'create', 'customers:create',     'Create customer (league) records',       20),
  ('customers',    'read',   'customers:read',       'View customer records',                  21),
  ('customers',    'update', 'customers:update',     'Update customer records',                22),
  ('customers',    'delete', 'customers:delete',     'Delete customer records',                23),
  -- sports
  ('sports',       'create', 'sports:create',        'Create sport definitions',               30),
  ('sports',       'read',   'sports:read',          'View sport definitions',                 31),
  ('sports',       'update', 'sports:update',        'Update sport definitions',               32),
  ('sports',       'delete', 'sports:delete',        'Delete sport definitions',               33),
  -- levels
  ('levels',       'create', 'levels:create',        'Create contest level definitions',       40),
  ('levels',       'read',   'levels:read',          'View contest levels',                    41),
  ('levels',       'update', 'levels:update',        'Update contest levels',                  42),
  ('levels',       'delete', 'levels:delete',        'Delete contest levels',                  43),
  -- seasons
  ('seasons',      'create', 'seasons:create',       'Create season definitions',              50),
  ('seasons',      'read',   'seasons:read',         'View season definitions',                51),
  ('seasons',      'update', 'seasons:update',       'Update season definitions',              52),
  ('seasons',      'delete', 'seasons:delete',       'Delete season definitions',              53),
  -- leagues
  ('leagues',      'create', 'leagues:create',       'Create league records',                  60),
  ('leagues',      'read',   'leagues:read',         'View league records',                    61),
  ('leagues',      'update', 'leagues:update',       'Update league records',                  62),
  ('leagues',      'delete', 'leagues:delete',       'Delete league records',                  63),
  -- teams
  ('teams',        'create', 'teams:create',         'Create team records',                    70),
  ('teams',        'read',   'teams:read',           'View team records',                      71),
  ('teams',        'update', 'teams:update',         'Update team records',                    72),
  ('teams',        'delete', 'teams:delete',         'Delete team records',                    73),
  -- venues
  ('venues',       'create', 'venues:create',        'Create venue records',                   80),
  ('venues',       'read',   'venues:read',          'View venue records',                     81),
  ('venues',       'update', 'venues:update',        'Update venue records',                   82),
  ('venues',       'delete', 'venues:delete',        'Delete venue records',                   83),
  -- officials
  ('officials',    'create', 'officials:create',     'Create official records',                90),
  ('officials',    'read',   'officials:read',       'View official records',                  91),
  ('officials',    'update', 'officials:update',     'Update official records',                92),
  ('officials',    'delete', 'officials:delete',     'Delete official records',                93),
  -- contests
  ('contests',     'create', 'contests:create',      'Create contest schedule entries',       100),
  ('contests',     'read',   'contests:read',        'View contest schedules',                101),
  ('contests',     'update', 'contests:update',      'Update contest schedules',              102),
  ('contests',     'delete', 'contests:delete',      'Delete contest schedules',              103),
  -- assignments
  ('assignments',  'create', 'assignments:create',   'Create official → contest assignments', 110),
  ('assignments',  'read',   'assignments:read',     'View official assignments',             111),
  ('assignments',  'update', 'assignments:update',   'Update official assignments',           112),
  ('assignments',  'delete', 'assignments:delete',   'Remove official assignments',           113),
  -- billing
  ('billing',      'create', 'billing:create',       'Create invoices / payments',            120),
  ('billing',      'read',   'billing:read',         'View billing data',                     121),
  ('billing',      'update', 'billing:update',       'Update billing records',                122),
  ('billing',      'delete', 'billing:delete',       'Void / delete billing records',         123),
  -- rates
  ('rates',        'create', 'rates:create',         'Create contest & pay rates',            130),
  ('rates',        'read',   'rates:read',           'View contest & pay rates',              131),
  ('rates',        'update', 'rates:update',         'Update contest & pay rates',            132),
  ('rates',        'delete', 'rates:delete',         'Delete contest & pay rates',            133),
  -- roles (meta — who can manage roles within tenant)
  ('roles',        'create', 'roles:create',         'Create new roles',                      140),
  ('roles',        'read',   'roles:read',           'View role definitions',                 141),
  ('roles',        'update', 'roles:update',         'Update role definitions',               142),
  ('roles',        'delete', 'roles:delete',         'Delete roles',                          143),
  -- entitlements (meta — who can assign entitlements to roles)
  ('entitlements', 'create', 'entitlements:create',  'Assign entitlements to roles',          150),
  ('entitlements', 'read',   'entitlements:read',    'View entitlement assignments',          151),
  ('entitlements', 'update', 'entitlements:update',  'Modify entitlement assignments',        152),
  ('entitlements', 'delete', 'entitlements:delete',  'Remove entitlement assignments',        153),
  -- imports (bulk operations)
  ('imports',      'create', 'imports:create',       'Execute bulk import operations',        160),
  ('imports',      'read',   'imports:read',         'Download import templates',             161),
  ('imports',      'update', 'imports:update',       'Modify import configuration',           162),
  ('imports',      'delete', 'imports:delete',       'Delete imported batches',               163);

-- =========================================================================
-- 3. app.role_entitlement — tenant-scoped junction
-- =========================================================================
CREATE TABLE IF NOT EXISTS app.role_entitlement (
    role_entitlement_id SERIAL  PRIMARY KEY,
    role_id             INTEGER NOT NULL REFERENCES app.roles(role_id) ON DELETE CASCADE,
    entitlement_id      INTEGER NOT NULL REFERENCES app.entitlement(entitlement_id) ON DELETE CASCADE,
    tenant_id           BIGINT  NOT NULL REFERENCES app.tenant(tenant_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_role_entitlement UNIQUE (role_id, entitlement_id, tenant_id)
);

COMMENT ON TABLE app.role_entitlement IS 'Maps entitlements to tenant-scoped roles. Tenant admins configure which CRUD operations each role may perform.';

-- RLS — tenant-scoped with platform-admin bypass
ALTER TABLE app.role_entitlement ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.role_entitlement FORCE ROW LEVEL SECURITY;

CREATE POLICY role_entitlement_tenant_isolation ON app.role_entitlement FOR ALL
    USING (
        current_setting('app.is_platform_admin', true) = 'true'
        OR tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::bigint
    );

GRANT SELECT, INSERT, UPDATE, DELETE ON app.role_entitlement TO contestgrid_lab_id;
GRANT USAGE, SELECT ON SEQUENCE app.role_entitlement_role_entitlement_id_seq TO contestgrid_lab_id;

-- Indexes
CREATE INDEX idx_role_entitlement_role   ON app.role_entitlement(role_id);
CREATE INDEX idx_role_entitlement_tenant ON app.role_entitlement(tenant_id);

-- updated_at trigger
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON app.role_entitlement
    FOR EACH ROW
    EXECUTE FUNCTION app.set_updated_at();

-- =========================================================================
-- 4. Seed default role↔entitlement mappings for every tenant.
--
-- Policy:
--   Primary Assigner Admin   → ALL entitlements
--   Secondary Assigner Admin → ALL entitlements
--   League Director          → read + update on leagues/teams/venues/contests/
--                               assignments/seasons/levels/sports/officials/rates;
--                               read on billing/persons/customers
--   Coach                    → read on contests/teams/assignments/venues/
--                               leagues/levels/sports/seasons
--   Official                 → read on contests/assignments/venues/sports/levels
-- =========================================================================

-- Helper: insert all entitlements for a given role description across all tenants
-- Primary Assigner Admin — full access
INSERT INTO app.role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM app.roles r
 CROSS JOIN app.entitlement e
 WHERE r.role_description = 'Primary Assigner Admin';

-- Secondary Assigner Admin — full access
INSERT INTO app.role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM app.roles r
 CROSS JOIN app.entitlement e
 WHERE r.role_description = 'Secondary Assigner Admin';

-- League Director — broad read + targeted write
INSERT INTO app.role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM app.roles r
 CROSS JOIN app.entitlement e
 WHERE r.role_description = 'League Director'
   AND (
     -- full CRUD on their domain areas
     (e.resource_name IN ('leagues','teams','venues','contests','assignments','seasons') AND e.operation IN ('create','read','update','delete'))
     -- read + update on adjacent areas
     OR (e.resource_name IN ('levels','sports','officials','rates') AND e.operation IN ('read','update'))
     -- read-only on sensitive areas
     OR (e.resource_name IN ('billing','persons','customers','imports') AND e.operation = 'read')
   );

-- Coach — read-only on scheduling-related resources
INSERT INTO app.role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM app.roles r
 CROSS JOIN app.entitlement e
 WHERE r.role_description = 'Coach'
   AND e.operation = 'read'
   AND e.resource_name IN ('contests','teams','assignments','venues','leagues','levels','sports','seasons');

-- Official — read-only on assignment / schedule areas
INSERT INTO app.role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM app.roles r
 CROSS JOIN app.entitlement e
 WHERE r.role_description = 'Official'
   AND e.operation = 'read'
   AND e.resource_name IN ('contests','assignments','venues','sports','levels','seasons');

-- =========================================================================
-- 5. Grant sequence usage for entitlement table
-- =========================================================================
GRANT USAGE, SELECT ON SEQUENCE app.entitlement_entitlement_id_seq TO contestgrid_lab_id;
