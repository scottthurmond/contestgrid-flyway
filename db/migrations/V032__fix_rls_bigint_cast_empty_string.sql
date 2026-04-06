-- V032: Fix RLS policies — prevent bigint cast error on empty app.tenant_id
--
-- Problem:  When platformQuery sets app.is_platform_admin = 'true' but does NOT
--           set app.tenant_id, PostgreSQL still evaluates both sides of the OR
--           in the RLS policy.  The cast  current_setting('app.tenant_id',true)::bigint
--           throws "invalid input syntax for type bigint: ''" when the setting
--           is an empty string.
--
-- Fix:      Wrap the cast in NULLIF so an empty string becomes NULL before
--           the cast.  NULL::bigint is safe and tenant_id = NULL is simply false,
--           so the platform_admin branch still controls access.

-- Helper: generate ALTER POLICY statements for every affected policy.
-- Each policy keeps the exact same logic — only the cast is wrapped in NULLIF.

DO $$
DECLARE
  r RECORD;
  new_qual TEXT;
BEGIN
  FOR r IN
    SELECT tablename, policyname, qual::text
      FROM pg_policies
     WHERE schemaname = 'app'
       AND qual::text LIKE '%current_setting(''app.tenant_id''%::bigint%'
       AND qual::text NOT LIKE '%NULLIF%'
  LOOP
    -- Replace the raw cast with the safe NULLIF-wrapped version
    new_qual := replace(
      r.qual::text,
      $x$(current_setting('app.tenant_id'::text, true))::bigint$x$,
      $x$(NULLIF(current_setting('app.tenant_id'::text, true), ''))::bigint$x$
    );

    EXECUTE format(
      'ALTER POLICY %I ON app.%I USING (%s)',
      r.policyname,
      r.tablename,
      new_qual
    );

    RAISE NOTICE 'Updated policy % on %', r.policyname, r.tablename;
  END LOOP;
END;
$$;
