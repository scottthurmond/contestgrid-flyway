-- V027: Add tenant_id + RLS to 6 billing data tables
-- Backfill tenant_id from FK chains to officials_association

-- Enable platform admin bypass for this migration's data operations
SELECT set_config('app.is_platform_admin', 'true', true);

------------------------------------------------------------
-- 1. association_subscription
------------------------------------------------------------
ALTER TABLE app.association_subscription ADD COLUMN tenant_id BIGINT;

UPDATE app.association_subscription AS sub
  SET tenant_id = oa.tenant_id
  FROM app.officials_association oa
  WHERE sub.officials_association_id = oa.officials_association_id;

ALTER TABLE app.association_subscription ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.association_subscription
  ADD CONSTRAINT fk_assoc_sub_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);

ALTER TABLE app.association_subscription ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.association_subscription FORCE ROW LEVEL SECURITY;
CREATE POLICY assoc_sub_tenant_isolation ON app.association_subscription FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

------------------------------------------------------------
-- 2. invoice
------------------------------------------------------------
ALTER TABLE app.invoice ADD COLUMN tenant_id BIGINT;

UPDATE app.invoice AS inv
  SET tenant_id = oa.tenant_id
  FROM app.officials_association oa
  WHERE inv.officials_association_id = oa.officials_association_id;

ALTER TABLE app.invoice ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.invoice
  ADD CONSTRAINT fk_invoice_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);

ALTER TABLE app.invoice ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.invoice FORCE ROW LEVEL SECURITY;
CREATE POLICY invoice_tenant_isolation ON app.invoice FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

------------------------------------------------------------
-- 3. invoice_line_item
------------------------------------------------------------
ALTER TABLE app.invoice_line_item ADD COLUMN tenant_id BIGINT;

UPDATE app.invoice_line_item AS ili
  SET tenant_id = inv.tenant_id
  FROM app.invoice inv
  WHERE ili.invoice_id = inv.invoice_id;

-- Handle any orphans (shouldn't exist but safety)
DELETE FROM app.invoice_line_item WHERE tenant_id IS NULL;

ALTER TABLE app.invoice_line_item ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.invoice_line_item
  ADD CONSTRAINT fk_inv_line_item_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);

ALTER TABLE app.invoice_line_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.invoice_line_item FORCE ROW LEVEL SECURITY;
CREATE POLICY inv_line_item_tenant_isolation ON app.invoice_line_item FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

------------------------------------------------------------
-- 4. invoice_payment (0 rows — just add column + RLS)
------------------------------------------------------------
ALTER TABLE app.invoice_payment ADD COLUMN tenant_id BIGINT;

-- Backfill any rows that might exist
UPDATE app.invoice_payment AS ip
  SET tenant_id = inv.tenant_id
  FROM app.invoice inv
  WHERE ip.invoice_id = inv.invoice_id;

DELETE FROM app.invoice_payment WHERE tenant_id IS NULL;

ALTER TABLE app.invoice_payment ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.invoice_payment
  ADD CONSTRAINT fk_inv_payment_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);

ALTER TABLE app.invoice_payment ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.invoice_payment FORCE ROW LEVEL SECURITY;
CREATE POLICY inv_payment_tenant_isolation ON app.invoice_payment FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

------------------------------------------------------------
-- 5. billing_notification_config
------------------------------------------------------------
ALTER TABLE app.billing_notification_config ADD COLUMN tenant_id BIGINT;

UPDATE app.billing_notification_config AS bnc
  SET tenant_id = oa.tenant_id
  FROM app.officials_association oa
  WHERE bnc.officials_association_id = oa.officials_association_id;

ALTER TABLE app.billing_notification_config ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.billing_notification_config
  ADD CONSTRAINT fk_billing_notif_config_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);

ALTER TABLE app.billing_notification_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.billing_notification_config FORCE ROW LEVEL SECURITY;
CREATE POLICY billing_notif_config_tenant_isolation ON app.billing_notification_config FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

------------------------------------------------------------
-- 6. billing_notification_log (0 rows — just add column + RLS)
------------------------------------------------------------
ALTER TABLE app.billing_notification_log ADD COLUMN tenant_id BIGINT;

-- Backfill any rows that might exist
UPDATE app.billing_notification_log AS bnl
  SET tenant_id = bnc.tenant_id
  FROM app.billing_notification_config bnc
  WHERE bnl.billing_notification_config_id = bnc.billing_notification_config_id;

DELETE FROM app.billing_notification_log WHERE tenant_id IS NULL;

ALTER TABLE app.billing_notification_log ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.billing_notification_log
  ADD CONSTRAINT fk_billing_notif_log_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);

ALTER TABLE app.billing_notification_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.billing_notification_log FORCE ROW LEVEL SECURITY;
CREATE POLICY billing_notif_log_tenant_isolation ON app.billing_notification_log FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);
