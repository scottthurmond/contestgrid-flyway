-- ============================================================================
-- V025: Add RLS policy for auth email lookup on person table
--
-- Problem: During login we need to find which tenant a user belongs to by
-- email address, but FORCE ROW LEVEL SECURITY (V024) requires a tenant_id
-- context to read the person table.
--
-- Solution: Add a second permissive SELECT policy that allows reading a
-- single person row when the session variable 'app.auth_email_lookup' is
-- set to the target email address. Permissive policies are OR'd together,
-- so normal tenant-based access continues to work alongside this.
-- ============================================================================

-- Allow looking up a person by email without tenant context (used during login)
CREATE POLICY person_auth_email_lookup ON app.person
  FOR SELECT
  USING (
    current_setting('app.auth_email_lookup', true) IS NOT NULL
    AND LOWER(email_address) = LOWER(current_setting('app.auth_email_lookup', true))
  );

COMMENT ON POLICY person_auth_email_lookup ON app.person IS
  'Auth-only: allows looking up a person by email to resolve tenant_id during login';
