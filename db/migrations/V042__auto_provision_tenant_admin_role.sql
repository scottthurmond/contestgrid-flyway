-- V042: Auto-provision Tenant Admin role + entitlements on tenant creation
--
-- When a new tenant is inserted, the system must automatically:
--   1. Create a "Tenant Admin" role (is_admin_role = TRUE)
--   2. Grant ALL entitlements to that role
--
-- This replaces the one-time seed in V040 with a permanent trigger so that
-- tenants created via onboarding (or any future flow) always get a Tenant
-- Admin role ready for the platform admin to assign.
-- ---------------------------------------------------------------------------

-- Bypass RLS for this migration
SELECT set_config('app.is_platform_admin', 'true', false);

-- =========================================================================
-- 1. Trigger function: provision_tenant_admin_role()
-- =========================================================================
CREATE OR REPLACE FUNCTION app.provision_tenant_admin_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER  -- runs with table-owner privileges (bypasses RLS)
AS $$
DECLARE
  v_role_id BIGINT;
BEGIN
  -- Create the Tenant Admin role for the new tenant
  INSERT INTO app.roles (role_description, tenant_id, is_admin_role)
  VALUES ('Tenant Admin', NEW.tenant_id, TRUE)
  ON CONFLICT ON CONSTRAINT roles_desc_tenant_uq DO NOTHING
  RETURNING role_id INTO v_role_id;

  -- If the role already existed (ON CONFLICT), look it up
  IF v_role_id IS NULL THEN
    SELECT role_id INTO v_role_id
      FROM app.roles
     WHERE role_description = 'Tenant Admin'
       AND tenant_id = NEW.tenant_id;
  END IF;

  -- Grant ALL entitlements to the Tenant Admin role
  IF v_role_id IS NOT NULL THEN
    INSERT INTO app.role_entitlement (role_id, entitlement_id, tenant_id)
    SELECT v_role_id, e.entitlement_id, NEW.tenant_id
      FROM app.entitlement e
    ON CONFLICT ON CONSTRAINT uq_role_entitlement DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION app.provision_tenant_admin_role()
  IS 'AFTER INSERT trigger on app.tenant — auto-creates the Tenant Admin role '
     'and grants all entitlements so the platform admin can immediately assign it.';

-- =========================================================================
-- 2. Attach trigger to app.tenant
-- =========================================================================
CREATE TRIGGER trg_provision_tenant_admin_role
  AFTER INSERT ON app.tenant
  FOR EACH ROW
  EXECUTE FUNCTION app.provision_tenant_admin_role();
