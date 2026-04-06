-- V038: Seed role_entitlement data with platform-admin context
--
-- V037 created the tables correctly but the INSERT … SELECT statements
-- returned 0 rows because RLS on app.roles blocked the FROM clause
-- during migration.  This migration sets the platform-admin bypass flag
-- before re-running the inserts.
-- ---------------------------------------------------------------------------

-- Bypass RLS for this transaction
SELECT set_config('app.is_platform_admin', 'true', false);

-- Primary Assigner Admin — full access
INSERT INTO app.role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM app.roles r
 CROSS JOIN app.entitlement e
 WHERE r.role_description = 'Primary Assigner Admin'
ON CONFLICT ON CONSTRAINT uq_role_entitlement DO NOTHING;

-- Secondary Assigner Admin — full access
INSERT INTO app.role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM app.roles r
 CROSS JOIN app.entitlement e
 WHERE r.role_description = 'Secondary Assigner Admin'
ON CONFLICT ON CONSTRAINT uq_role_entitlement DO NOTHING;

-- League Director — broad read + targeted write
INSERT INTO app.role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM app.roles r
 CROSS JOIN app.entitlement e
 WHERE r.role_description = 'League Director'
   AND (
     (e.resource_name IN ('leagues','teams','venues','contests','assignments','seasons') AND e.operation IN ('create','read','update','delete'))
     OR (e.resource_name IN ('levels','sports','officials','rates') AND e.operation IN ('read','update'))
     OR (e.resource_name IN ('billing','persons','customers','imports') AND e.operation = 'read')
   )
ON CONFLICT ON CONSTRAINT uq_role_entitlement DO NOTHING;

-- Coach — read-only on scheduling-related resources
INSERT INTO app.role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM app.roles r
 CROSS JOIN app.entitlement e
 WHERE r.role_description = 'Coach'
   AND e.operation = 'read'
   AND e.resource_name IN ('contests','teams','assignments','venues','leagues','levels','sports','seasons')
ON CONFLICT ON CONSTRAINT uq_role_entitlement DO NOTHING;

-- Official — read-only on assignment / schedule areas
INSERT INTO app.role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM app.roles r
 CROSS JOIN app.entitlement e
 WHERE r.role_description = 'Official'
   AND e.operation = 'read'
   AND e.resource_name IN ('contests','assignments','venues','sports','levels','seasons')
ON CONFLICT ON CONSTRAINT uq_role_entitlement DO NOTHING;

-- Reset
SELECT set_config('app.is_platform_admin', '', false);
