-- V017: Add is_active flag to tenant table
--
-- New tenants start as inactive (is_active = false).
-- A platform admin must activate a tenant after payment is received.
-- Deactivating a tenant blocks all logins for users under that tenant.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'app' AND table_name = 'tenant'
      AND column_name = 'is_active'
  ) THEN
    ALTER TABLE tenant ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT false;
    -- Activate all existing tenants so current users are not locked out
    UPDATE tenant SET is_active = true;
  END IF;
END
$$;

COMMENT ON COLUMN tenant.is_active IS 'Whether the tenant account is active. Inactive tenants cannot log in.';
