-- V041: Root admin flag and tenant-admin listing support
--
-- 1. Add is_root_admin flag to platform_role_assignment
--    The root admin is the one super user whose roles/access cannot be
--    viewed or changed by anyone — not even other platform admins.
--
-- 2. Seed person_id = 1 (bootstrap admin) as the root admin.

-- ── 1. Add is_root_admin column ──
ALTER TABLE app.platform_role_assignment
  ADD COLUMN is_root_admin BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN app.platform_role_assignment.is_root_admin IS
  'When TRUE this assignment (and the person behind it) is protected from '
  'any viewing or modification by other users. Only one person should have '
  'this flag set on their platform_admin assignment.';

-- ── 2. Seed root admin for person_id = 1 (bootstrap platform_admin) ──
UPDATE app.platform_role_assignment
   SET is_root_admin = TRUE
 WHERE person_id = 1
   AND platform_role_type_id = (
     SELECT platform_role_type_id
       FROM app.platform_role_type
      WHERE role_name = 'platform_admin'
   );
