-- ============================================================
-- V014: Create payment_status and payment tables
-- ============================================================
-- Supports billing-proc payment processing and payroll workflows.
-- payment_status: reference table for payment lifecycle states
-- payment: records payments for contests (billed to league tenant)
--          and payouts to officials (earned per assignment)
-- ============================================================

SET search_path TO app, public;

-- ── Reference: Payment Status ──
CREATE TABLE IF NOT EXISTS payment_status (
    payment_status_id   SERIAL PRIMARY KEY,
    payment_status_name VARCHAR(50) NOT NULL UNIQUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO payment_status (payment_status_name) VALUES
    ('Pending'),
    ('Processing'),
    ('Completed'),
    ('Failed'),
    ('Refunded'),
    ('Cancelled');

-- ── Reference: Payment Type ──
CREATE TABLE IF NOT EXISTS payment_type (
    payment_type_id   SERIAL PRIMARY KEY,
    payment_type_name VARCHAR(50) NOT NULL UNIQUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO payment_type (payment_type_name) VALUES
    ('Contest Bill'),       -- league pays for the contest
    ('Official Payout');    -- association pays the official

-- ── Payment ──
CREATE TABLE IF NOT EXISTS payment (
    payment_id              BIGSERIAL PRIMARY KEY,
    tenant_id               BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
    payment_type_id         INT NOT NULL REFERENCES payment_type(payment_type_id) ON DELETE RESTRICT,
    payment_status_id       INT NOT NULL REFERENCES payment_status(payment_status_id) ON DELETE RESTRICT
                                DEFAULT 1,  -- Pending

    -- Contest link (always set)
    contest_schedule_id     BIGINT NOT NULL REFERENCES contest_schedule(contest_schedule_id) ON DELETE CASCADE,

    -- Official link (set for Official Payout type)
    official_id             BIGINT REFERENCES official(official_id) ON DELETE SET NULL,
    assignment_id           BIGINT REFERENCES official_contest_assignment(assignment_id) ON DELETE SET NULL,

    -- Money
    amount                  NUMERIC(10,2) NOT NULL,
    currency                VARCHAR(3) NOT NULL DEFAULT 'USD',

    -- External payment processor
    processor               VARCHAR(50),         -- 'stripe', 'manual', etc.
    processor_transaction_id VARCHAR(255),        -- Stripe charge/transfer ID
    processor_response      JSONB,               -- raw response for audit

    -- Metadata
    description             TEXT,
    period_start            DATE,                -- payroll period start
    period_end              DATE,                -- payroll period end
    paid_at                 TIMESTAMPTZ,         -- when payment actually settled
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_payment_tenant          ON payment(tenant_id);
CREATE INDEX idx_payment_contest         ON payment(contest_schedule_id);
CREATE INDEX idx_payment_official        ON payment(official_id);
CREATE INDEX idx_payment_status          ON payment(payment_status_id);
CREATE INDEX idx_payment_type            ON payment(payment_type_id);
CREATE INDEX idx_payment_period          ON payment(period_start, period_end);
CREATE INDEX idx_payment_processor_txn   ON payment(processor_transaction_id) WHERE processor_transaction_id IS NOT NULL;

-- RLS
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

CREATE POLICY payment_tenant_isolation ON payment
    USING (tenant_id = current_setting('app.tenant_id')::BIGINT);

CREATE POLICY payment_tenant_insert ON payment
    FOR INSERT WITH CHECK (tenant_id = current_setting('app.tenant_id')::BIGINT);

COMMENT ON TABLE payment IS 'Payment records for contest bills and official payouts';
COMMENT ON COLUMN payment.payment_type_id IS '1=Contest Bill (league pays), 2=Official Payout (to official)';
