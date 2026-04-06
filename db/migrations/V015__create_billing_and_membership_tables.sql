-- ============================================================
-- V015: Create billing & membership tables
-- ============================================================
-- 10 tables supporting officials-association subscription billing:
--   1. subscription_plan          – Monthly / Annual reference
--   2. subscription_tier          – 13 pricing tiers by official count
--   3. official_association_membership – many-to-many official↔association (active/inactive)
--   4. association_subscription   – per-association subscription record
--   5. discount_code              – single-use promo codes
--   6. invoice                    – billing history
--   7. invoice_line_item          – itemised charges
--   8. invoice_payment            – charges & refunds
--   9. billing_notification_config – configurable reminder schedule
--  10. billing_notification_log   – sent notification audit trail
-- ============================================================

SET search_path TO app, public;

-- ────────────────────────────────────────────────────────────
-- 1. Subscription Plan (reference)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS subscription_plan (
    subscription_plan_id    SERIAL PRIMARY KEY,
    plan_name               VARCHAR(50)   NOT NULL UNIQUE,
    billing_interval_months INT           NOT NULL,   -- 1 = monthly, 12 = annual
    discount_percent        NUMERIC(5,2)  NOT NULL DEFAULT 0,  -- e.g. 15.00 for annual
    created_at              TIMESTAMPTZ   NOT NULL DEFAULT now()
);

INSERT INTO subscription_plan (plan_name, billing_interval_months, discount_percent) VALUES
    ('Monthly', 1,  0.00),
    ('Annual', 12, 15.00);

COMMENT ON TABLE  subscription_plan IS 'Billing cadence options for association subscriptions';
COMMENT ON COLUMN subscription_plan.discount_percent IS 'Discount applied when choosing this plan (e.g. 15% for annual)';

-- ────────────────────────────────────────────────────────────
-- 2. Subscription Tier
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS subscription_tier (
    subscription_tier_id    SERIAL PRIMARY KEY,
    tier_name               VARCHAR(100)  NOT NULL UNIQUE,
    min_officials           INT           NOT NULL,
    max_officials           INT           NOT NULL,
    cost_per_official       NUMERIC(10,2) NOT NULL,
    created_at              TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT chk_tier_range CHECK (min_officials <= max_officials),
    CONSTRAINT chk_cost_positive CHECK (cost_per_official > 0)
);

-- 13 pricing tiers
INSERT INTO subscription_tier (tier_name, min_officials, max_officials, cost_per_official) VALUES
    ('Tier 1  – up to 25',    1,  25, 1.50),
    ('Tier 2  – up to 50',   26,  50, 1.45),
    ('Tier 3  – up to 75',   51,  75, 1.40),
    ('Tier 4  – up to 100',  76, 100, 1.35),
    ('Tier 5  – up to 150', 101, 150, 1.25),
    ('Tier 6  – up to 200', 151, 200, 1.15),
    ('Tier 7  – up to 250', 201, 250, 1.05),
    ('Tier 8  – up to 300', 251, 300, 0.95),
    ('Tier 9  – up to 350', 301, 350, 0.85),
    ('Tier 10 – up to 400', 351, 400, 0.75),
    ('Tier 11 – up to 450', 401, 450, 0.65),
    ('Tier 12 – up to 500', 451, 500, 0.55),
    ('Tier 13 – up to 600', 501, 600, 0.50);

COMMENT ON TABLE  subscription_tier IS 'Pricing tiers keyed on number of active officials';
COMMENT ON COLUMN subscription_tier.cost_per_official IS 'Monthly cost per active official at this tier level';

-- ────────────────────────────────────────────────────────────
-- 3. Official ↔ Association Membership (many-to-many)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS membership_status (
    membership_status_id    SERIAL PRIMARY KEY,
    membership_status_name  VARCHAR(50) NOT NULL UNIQUE,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO membership_status (membership_status_id, membership_status_name) VALUES
    (1, 'Active'),
    (2, 'Inactive'),
    (3, 'Suspended')
ON CONFLICT (membership_status_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('membership_status', 'membership_status_id'),
  GREATEST((SELECT COALESCE(MAX(membership_status_id), 1) FROM membership_status), 3), true);

COMMENT ON TABLE membership_status IS 'Lookup table for official-association membership statuses';

CREATE TABLE IF NOT EXISTS official_association_membership (
    membership_id               BIGSERIAL PRIMARY KEY,
    official_id                 BIGINT NOT NULL REFERENCES official(official_id) ON DELETE CASCADE,
    officials_association_id    BIGINT NOT NULL REFERENCES officials_association(officials_association_id) ON DELETE CASCADE,
    membership_status_id        INT    NOT NULL DEFAULT 1 REFERENCES membership_status(membership_status_id) ON DELETE RESTRICT,
    joined_at                   DATE   NOT NULL DEFAULT CURRENT_DATE,
    deactivated_at              TIMESTAMPTZ,
    notes                       TEXT,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_official_association UNIQUE (official_id, officials_association_id)
);

CREATE INDEX idx_oam_official    ON official_association_membership(official_id);
CREATE INDEX idx_oam_association ON official_association_membership(officials_association_id);
CREATE INDEX idx_oam_status      ON official_association_membership(membership_status_id);

COMMENT ON TABLE  official_association_membership IS 'Many-to-many: an official can belong to 1+ associations with per-row active/inactive status';
COMMENT ON COLUMN official_association_membership.membership_status_id IS '1=Active, 2=Inactive, 3=Suspended';
COMMENT ON COLUMN official_association_membership.deactivated_at IS 'Set when official is deactivated in this association';

-- ────────────────────────────────────────────────────────────
-- 4. Association Subscription
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS subscription_status (
    subscription_status_id   SERIAL PRIMARY KEY,
    subscription_status_name VARCHAR(50) NOT NULL UNIQUE,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO subscription_status (subscription_status_id, subscription_status_name) VALUES
    (1, 'Active'),
    (2, 'Past Due'),
    (3, 'Cancelled'),
    (4, 'Suspended'),
    (5, 'Trial')
ON CONFLICT (subscription_status_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('subscription_status', 'subscription_status_id'),
  GREATEST((SELECT COALESCE(MAX(subscription_status_id), 1) FROM subscription_status), 5), true);

COMMENT ON TABLE subscription_status IS 'Lookup table for association subscription lifecycle states';

CREATE TABLE IF NOT EXISTS association_subscription (
    association_subscription_id  BIGSERIAL PRIMARY KEY,
    officials_association_id     BIGINT  NOT NULL REFERENCES officials_association(officials_association_id) ON DELETE CASCADE,
    subscription_plan_id         INT     NOT NULL REFERENCES subscription_plan(subscription_plan_id) ON DELETE RESTRICT,
    subscription_tier_id         INT     NOT NULL REFERENCES subscription_tier(subscription_tier_id) ON DELETE RESTRICT,
    subscription_status_id       INT     NOT NULL DEFAULT 1 REFERENCES subscription_status(subscription_status_id) ON DELETE RESTRICT,
    active_official_count        INT     NOT NULL DEFAULT 0,
    monthly_base_amount          NUMERIC(10,2) NOT NULL,   -- tier cost × active officials (before plan discount)
    plan_discount_amount         NUMERIC(10,2) NOT NULL DEFAULT 0,
    discount_code_amount         NUMERIC(10,2) NOT NULL DEFAULT 0,
    effective_monthly_amount     NUMERIC(10,2) NOT NULL,   -- what they actually pay per month
    current_period_start         DATE    NOT NULL,
    current_period_end           DATE    NOT NULL,
    cancelled_at                 TIMESTAMPTZ,
    created_at                   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_asub_association ON association_subscription(officials_association_id);
CREATE INDEX idx_asub_plan        ON association_subscription(subscription_plan_id);
CREATE INDEX idx_asub_tier        ON association_subscription(subscription_tier_id);
CREATE INDEX idx_asub_status      ON association_subscription(subscription_status_id);
CREATE INDEX idx_asub_period      ON association_subscription(current_period_start, current_period_end);

COMMENT ON TABLE  association_subscription IS 'Active subscription record for each officials association';
COMMENT ON COLUMN association_subscription.active_official_count IS 'Snapshot of active officials at last billing calculation';
COMMENT ON COLUMN association_subscription.effective_monthly_amount IS 'Final monthly charge after all discounts';

-- ────────────────────────────────────────────────────────────
-- 5. Discount Code (single-use)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS discount_type (
    discount_type_id   SERIAL PRIMARY KEY,
    discount_type_name VARCHAR(50) NOT NULL UNIQUE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO discount_type (discount_type_id, discount_type_name) VALUES
    (1, 'Percentage'),
    (2, 'Fixed Amount')
ON CONFLICT (discount_type_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('discount_type', 'discount_type_id'),
  GREATEST((SELECT COALESCE(MAX(discount_type_id), 1) FROM discount_type), 2), true);

COMMENT ON TABLE discount_type IS 'Discount code types: percentage off or fixed dollar amount';

CREATE TABLE IF NOT EXISTS discount_code (
    discount_code_id                BIGSERIAL PRIMARY KEY,
    code                            VARCHAR(50)   NOT NULL UNIQUE,
    description                     VARCHAR(255),
    discount_type_id                INT           NOT NULL REFERENCES discount_type(discount_type_id) ON DELETE RESTRICT,
    discount_value                  NUMERIC(10,2) NOT NULL,
    max_discount_amount             NUMERIC(10,2),              -- cap for percentage discounts
    valid_from                      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    valid_until                     TIMESTAMPTZ,                -- NULL = no expiration
    redeemed_by_subscription_id     BIGINT REFERENCES association_subscription(association_subscription_id) ON DELETE SET NULL,
    redeemed_at                     TIMESTAMPTZ,
    created_at                      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT chk_discount_value_positive CHECK (discount_value > 0),
    CONSTRAINT chk_redeemed_consistency CHECK (
        (redeemed_at IS NULL AND redeemed_by_subscription_id IS NULL)
        OR (redeemed_at IS NOT NULL AND redeemed_by_subscription_id IS NOT NULL)
    )
);

CREATE INDEX idx_dc_code     ON discount_code(code);
CREATE INDEX idx_dc_redeemed ON discount_code(redeemed_by_subscription_id) WHERE redeemed_by_subscription_id IS NOT NULL;

COMMENT ON TABLE  discount_code IS 'Single-use promo/discount codes. Once redeemed, cannot be used again by any entity.';
COMMENT ON COLUMN discount_code.redeemed_by_subscription_id IS 'Set when the code is used; prevents re-use';
COMMENT ON COLUMN discount_code.redeemed_at IS 'Timestamp of redemption; NULL means still available';
COMMENT ON COLUMN discount_code.max_discount_amount IS 'Optional cap when discount_type is Percentage';

-- ────────────────────────────────────────────────────────────
-- 6. Invoice
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS invoice_status (
    invoice_status_id   SERIAL PRIMARY KEY,
    invoice_status_name VARCHAR(50) NOT NULL UNIQUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO invoice_status (invoice_status_id, invoice_status_name) VALUES
    (1, 'Draft'),
    (2, 'Sent'),
    (3, 'Paid'),
    (4, 'Past Due'),
    (5, 'Void'),
    (6, 'Partially Paid'),
    (7, 'Refunded'),
    (8, 'Partially Refunded')
ON CONFLICT (invoice_status_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('invoice_status', 'invoice_status_id'),
  GREATEST((SELECT COALESCE(MAX(invoice_status_id), 1) FROM invoice_status), 8), true);

COMMENT ON TABLE invoice_status IS 'Lookup table for invoice lifecycle states';

CREATE TABLE IF NOT EXISTS invoice (
    invoice_id                   BIGSERIAL PRIMARY KEY,
    invoice_number               VARCHAR(50)   NOT NULL UNIQUE,   -- human-readable (e.g. INV-2026-000001)
    association_subscription_id  BIGINT        NOT NULL REFERENCES association_subscription(association_subscription_id) ON DELETE RESTRICT,
    officials_association_id     BIGINT        NOT NULL REFERENCES officials_association(officials_association_id) ON DELETE RESTRICT,
    invoice_status_id            INT           NOT NULL DEFAULT 1 REFERENCES invoice_status(invoice_status_id) ON DELETE RESTRICT,
    period_start                 DATE          NOT NULL,
    period_end                   DATE          NOT NULL,
    subtotal                     NUMERIC(10,2) NOT NULL DEFAULT 0,
    discount_total               NUMERIC(10,2) NOT NULL DEFAULT 0,
    tax_total                    NUMERIC(10,2) NOT NULL DEFAULT 0,
    total                        NUMERIC(10,2) NOT NULL DEFAULT 0,
    amount_paid                  NUMERIC(10,2) NOT NULL DEFAULT 0,
    amount_due                   NUMERIC(10,2) NOT NULL DEFAULT 0,
    currency                     VARCHAR(3)    NOT NULL DEFAULT 'USD',
    due_date                     DATE          NOT NULL,
    sent_at                      TIMESTAMPTZ,
    paid_at                      TIMESTAMPTZ,
    notes                        TEXT,
    created_at                   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at                   TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX idx_inv_association  ON invoice(officials_association_id);
CREATE INDEX idx_inv_subscription ON invoice(association_subscription_id);
CREATE INDEX idx_inv_status       ON invoice(invoice_status_id);
CREATE INDEX idx_inv_number       ON invoice(invoice_number);
CREATE INDEX idx_inv_due_date     ON invoice(due_date);
CREATE INDEX idx_inv_period       ON invoice(period_start, period_end);

COMMENT ON TABLE  invoice IS 'Billing history: one invoice per billing period per association subscription';
COMMENT ON COLUMN invoice.invoice_number IS 'Human-readable invoice identifier (e.g. INV-2026-000001)';
COMMENT ON COLUMN invoice.amount_due IS 'total - amount_paid; updated on each payment';

-- ────────────────────────────────────────────────────────────
-- 7. Invoice Line Item
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS invoice_line_item (
    line_item_id    BIGSERIAL PRIMARY KEY,
    invoice_id      BIGINT        NOT NULL REFERENCES invoice(invoice_id) ON DELETE CASCADE,
    description     VARCHAR(255)  NOT NULL,
    quantity        INT           NOT NULL DEFAULT 1,
    unit_price      NUMERIC(10,2) NOT NULL,
    line_total      NUMERIC(10,2) NOT NULL,          -- quantity × unit_price
    sort_order      INT           NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX idx_ili_invoice ON invoice_line_item(invoice_id);

COMMENT ON TABLE  invoice_line_item IS 'Itemised breakdown of charges on an invoice';
COMMENT ON COLUMN invoice_line_item.line_total IS 'quantity × unit_price';

-- ────────────────────────────────────────────────────────────
-- 8. Invoice Payment (charges & refunds)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS invoice_payment_type (
    invoice_payment_type_id   SERIAL PRIMARY KEY,
    invoice_payment_type_name VARCHAR(50) NOT NULL UNIQUE,
    created_at                TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO invoice_payment_type (invoice_payment_type_id, invoice_payment_type_name) VALUES
    (1, 'Charge'),
    (2, 'Full Refund'),
    (3, 'Partial Refund')
ON CONFLICT (invoice_payment_type_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('invoice_payment_type', 'invoice_payment_type_id'),
  GREATEST((SELECT COALESCE(MAX(invoice_payment_type_id), 1) FROM invoice_payment_type), 3), true);

COMMENT ON TABLE invoice_payment_type IS 'Types: Charge, Full Refund, Partial Refund';

CREATE TABLE IF NOT EXISTS invoice_payment (
    invoice_payment_id          BIGSERIAL PRIMARY KEY,
    invoice_id                  BIGINT        NOT NULL REFERENCES invoice(invoice_id) ON DELETE RESTRICT,
    invoice_payment_type_id     INT           NOT NULL REFERENCES invoice_payment_type(invoice_payment_type_id) ON DELETE RESTRICT,
    amount                      NUMERIC(10,2) NOT NULL,
    currency                    VARCHAR(3)    NOT NULL DEFAULT 'USD',
    processor                   VARCHAR(50),           -- 'stripe', 'manual', etc.
    processor_transaction_id    VARCHAR(255),
    processor_response          JSONB,
    paid_at                     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    notes                       TEXT,
    created_at                  TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX idx_ip_invoice       ON invoice_payment(invoice_id);
CREATE INDEX idx_ip_type          ON invoice_payment(invoice_payment_type_id);
CREATE INDEX idx_ip_processor_txn ON invoice_payment(processor_transaction_id) WHERE processor_transaction_id IS NOT NULL;

COMMENT ON TABLE  invoice_payment IS 'Payment transactions and refunds against invoices';
COMMENT ON COLUMN invoice_payment.amount IS 'Positive for charges, positive for refund amounts (type distinguishes direction)';

-- ────────────────────────────────────────────────────────────
-- 9. Billing Notification Config
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notification_type (
    notification_type_id   SERIAL PRIMARY KEY,
    notification_type_name VARCHAR(50) NOT NULL UNIQUE,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO notification_type (notification_type_id, notification_type_name) VALUES
    (1, 'Payment Due Reminder'),
    (2, 'Payment Past Due'),
    (3, 'Payment Received'),
    (4, 'Subscription Renewed'),
    (5, 'Subscription Cancelled')
ON CONFLICT (notification_type_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('notification_type', 'notification_type_id'),
  GREATEST((SELECT COALESCE(MAX(notification_type_id), 1) FROM notification_type), 5), true);

COMMENT ON TABLE notification_type IS 'Types of billing notifications that can be configured';

CREATE TABLE IF NOT EXISTS billing_notification_config (
    billing_notification_config_id  BIGSERIAL PRIMARY KEY,
    officials_association_id        BIGINT  NOT NULL REFERENCES officials_association(officials_association_id) ON DELETE CASCADE,
    notification_type_id            INT     NOT NULL REFERENCES notification_type(notification_type_id) ON DELETE RESTRICT,
    enabled                         BOOLEAN NOT NULL DEFAULT true,
    days_before_due                 INT,               -- for reminder type: 30, 14, 7, 3, 1
    email_recipients                TEXT[],            -- array of email addresses
    created_at                      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_notif_config UNIQUE (officials_association_id, notification_type_id, days_before_due)
);

CREATE INDEX idx_bnc_association ON billing_notification_config(officials_association_id);
CREATE INDEX idx_bnc_type        ON billing_notification_config(notification_type_id);

COMMENT ON TABLE  billing_notification_config IS 'Per-association configuration for billing notifications';
COMMENT ON COLUMN billing_notification_config.days_before_due IS 'For reminder type: how many days before due date to send';
COMMENT ON COLUMN billing_notification_config.email_recipients IS 'Override email list; NULL = use association default contact';

-- ────────────────────────────────────────────────────────────
-- 10. Billing Notification Log
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notification_status (
    notification_status_id   SERIAL PRIMARY KEY,
    notification_status_name VARCHAR(50) NOT NULL UNIQUE,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO notification_status (notification_status_id, notification_status_name) VALUES
    (1, 'Queued'),
    (2, 'Sent'),
    (3, 'Failed'),
    (4, 'Bounced')
ON CONFLICT (notification_status_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('notification_status', 'notification_status_id'),
  GREATEST((SELECT COALESCE(MAX(notification_status_id), 1) FROM notification_status), 4), true);

COMMENT ON TABLE notification_status IS 'Delivery status for billing notifications';

CREATE TABLE IF NOT EXISTS billing_notification_log (
    billing_notification_log_id  BIGSERIAL PRIMARY KEY,
    billing_notification_config_id BIGINT REFERENCES billing_notification_config(billing_notification_config_id) ON DELETE SET NULL,
    invoice_id                   BIGINT REFERENCES invoice(invoice_id) ON DELETE SET NULL,
    notification_type_id         INT    NOT NULL REFERENCES notification_type(notification_type_id) ON DELETE RESTRICT,
    notification_status_id       INT    NOT NULL DEFAULT 1 REFERENCES notification_status(notification_status_id) ON DELETE RESTRICT,
    recipient_email              VARCHAR(255) NOT NULL,
    subject                      VARCHAR(255),
    body                         TEXT,
    sent_at                      TIMESTAMPTZ,
    error_message                TEXT,
    created_at                   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_bnl_config  ON billing_notification_log(billing_notification_config_id);
CREATE INDEX idx_bnl_invoice ON billing_notification_log(invoice_id);
CREATE INDEX idx_bnl_type    ON billing_notification_log(notification_type_id);
CREATE INDEX idx_bnl_status  ON billing_notification_log(notification_status_id);
CREATE INDEX idx_bnl_sent_at ON billing_notification_log(sent_at);

COMMENT ON TABLE  billing_notification_log IS 'Audit trail of all billing notifications sent';
COMMENT ON COLUMN billing_notification_log.error_message IS 'Populated when notification_status is Failed or Bounced';

-- ────────────────────────────────────────────────────────────
-- RLS Policies
-- ────────────────────────────────────────────────────────────
-- Tables scoped to officials_association_id get RLS
-- (subscription_plan, subscription_tier, discount_type, etc. are global reference tables – no RLS)

-- Note: RLS for association-scoped tables can be added once the
-- app.officials_association_id session variable pattern is established.
-- For now, these tables follow the same convention as V014 (tenant-scoped RLS).
-- The billing-sys service will set the appropriate association context.
