-- V043: Enforce max-holders-per-tenant for singleton roles (e.g. Primary Assigner Admin)
--
-- 1.  Add max_holders_per_tenant column to roles (NULL = unlimited).
-- 2.  Set Primary Assigner Admin to max 1 holder per tenant.
-- 3.  Create a trigger on person_roles that checks the limit on INSERT.
--     (The trigger fires per-row inside the same transaction, so setPersonRoles
--      which does DELETE + INSERT in a txn will work correctly.)

-- ── 1. New column ──
ALTER TABLE app.roles
  ADD COLUMN max_holders_per_tenant INT DEFAULT NULL;

COMMENT ON COLUMN app.roles.max_holders_per_tenant
  IS 'Maximum number of persons who can hold this role within one tenant. NULL = unlimited.';

-- ── 2. Seed: PAA is singleton ──
-- Must bypass RLS (roles table has FORCE ROW LEVEL SECURITY)
SELECT set_config('app.is_platform_admin', 'true', false);

UPDATE app.roles
   SET max_holders_per_tenant = 1
 WHERE role_description = 'Primary Assigner Admin';

-- Reset
SELECT set_config('app.is_platform_admin', '', false);

-- ── 3. Trigger function ──
CREATE OR REPLACE FUNCTION app.enforce_role_holder_limit()
RETURNS TRIGGER AS $$
DECLARE
  v_limit   INT;
  v_current INT;
  v_desc    VARCHAR;
BEGIN
  -- Look up the limit for the role being assigned
  SELECT max_holders_per_tenant, role_description
    INTO v_limit, v_desc
    FROM app.roles
   WHERE role_id = NEW.role_id;

  -- NULL means unlimited
  IF v_limit IS NULL THEN
    RETURN NEW;
  END IF;

  -- Count how many people already hold this role in the same tenant
  SELECT COUNT(*)
    INTO v_current
    FROM app.person_roles
   WHERE role_id  = NEW.role_id
     AND tenant_id = NEW.tenant_id;

  IF v_current >= v_limit THEN
    RAISE EXCEPTION 'Role "%" already has % holder(s) in this tenant (limit: %)',
      v_desc, v_current, v_limit
      USING ERRCODE = 'unique_violation';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_enforce_role_holder_limit
  BEFORE INSERT ON app.person_roles
  FOR EACH ROW
  EXECUTE FUNCTION app.enforce_role_holder_limit();
