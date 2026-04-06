-- V055: Add entitlements for contest-types and contest-statuses configuration
--
-- Adds CRUD entitlements so tenant admins can manage contest types and statuses.
-- The V042 auto-provision trigger grants all entitlements to new Tenant Admin
-- roles automatically.  Existing tenant admin roles are back-filled here.

-- ── 1. Insert entitlement definitions ────────────────────────────────────────
INSERT INTO app.entitlement (resource_name, operation, entitlement_key, description, display_order)
VALUES
  ('contest-types', 'create', 'contest-types:create', 'Create contest types',            71),
  ('contest-types', 'read',   'contest-types:read',   'View contest types',              72),
  ('contest-types', 'update', 'contest-types:update', 'Update contest types',            73),
  ('contest-types', 'delete', 'contest-types:delete', 'Delete contest types',            74),
  ('contest-statuses', 'create', 'contest-statuses:create', 'Create contest statuses',   75),
  ('contest-statuses', 'read',   'contest-statuses:read',   'View contest statuses',     76),
  ('contest-statuses', 'update', 'contest-statuses:update', 'Update contest statuses',   77),
  ('contest-statuses', 'delete', 'contest-statuses:delete', 'Delete contest statuses',   78);

-- ── 2. Back-fill: grant new entitlements to every existing admin role ─────────
INSERT INTO app.role_entitlement (role_id, entitlement_id, tenant_id)
SELECT r.role_id, e.entitlement_id, r.tenant_id
  FROM app.roles r
  CROSS JOIN app.entitlement e
 WHERE r.is_admin_role = TRUE
   AND e.resource_name IN ('contest-types', 'contest-statuses')
   AND NOT EXISTS (
       SELECT 1 FROM app.role_entitlement re
        WHERE re.role_id = r.role_id
          AND re.entitlement_id = e.entitlement_id
          AND re.tenant_id = r.tenant_id
   );
