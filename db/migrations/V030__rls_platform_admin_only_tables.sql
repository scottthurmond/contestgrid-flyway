-- V030: Platform-admin-only RLS on subscription and discount tables
-- These tables are NOT accessible to tenants. Only platform admins can read/write.

------------------------------------------------------------
-- subscription_plan
------------------------------------------------------------
ALTER TABLE app.subscription_plan ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.subscription_plan FORCE ROW LEVEL SECURITY;
CREATE POLICY subscription_plan_platform_admin ON app.subscription_plan FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true')
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true');

------------------------------------------------------------
-- subscription_status
------------------------------------------------------------
ALTER TABLE app.subscription_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.subscription_status FORCE ROW LEVEL SECURITY;
CREATE POLICY subscription_status_platform_admin ON app.subscription_status FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true')
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true');

------------------------------------------------------------
-- subscription_tier
------------------------------------------------------------
ALTER TABLE app.subscription_tier ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.subscription_tier FORCE ROW LEVEL SECURITY;
CREATE POLICY subscription_tier_platform_admin ON app.subscription_tier FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true')
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true');

------------------------------------------------------------
-- subscription_tier_date_audit
------------------------------------------------------------
ALTER TABLE app.subscription_tier_date_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.subscription_tier_date_audit FORCE ROW LEVEL SECURITY;
CREATE POLICY sub_tier_audit_platform_admin ON app.subscription_tier_date_audit FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true')
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true');

------------------------------------------------------------
-- discount_code
------------------------------------------------------------
ALTER TABLE app.discount_code ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.discount_code FORCE ROW LEVEL SECURITY;
CREATE POLICY discount_code_platform_admin ON app.discount_code FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true')
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true');

------------------------------------------------------------
-- discount_type
------------------------------------------------------------
ALTER TABLE app.discount_type ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.discount_type FORCE ROW LEVEL SECURITY;
CREATE POLICY discount_type_platform_admin ON app.discount_type FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true')
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true');
