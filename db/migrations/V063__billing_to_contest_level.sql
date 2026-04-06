-- V063: Move billing from per-official to per-contest level.
-- Pay stays on official_contest_assignment; billing belongs on contest_schedule.

-- 1. Add billing columns to contest_schedule
ALTER TABLE contest_schedule
  ADD COLUMN base_bill_rate        NUMERIC(10,2),
  ADD COLUMN bill_multiplier       NUMERIC(6,4) DEFAULT 1.0,
  ADD COLUMN bill_flat_adjustment  NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN effective_bill_amount NUMERIC(10,2),
  ADD COLUMN bill_updated_by       BIGINT,
  ADD COLUMN bill_updated_at       TIMESTAMPTZ;

-- 2. Create contest-level billing audit table
CREATE TABLE contest_billing_audit (
  audit_id             BIGSERIAL PRIMARY KEY,
  contest_schedule_id  BIGINT NOT NULL REFERENCES contest_schedule(contest_schedule_id),
  change_type          TEXT NOT NULL DEFAULT 'bill_override',
  base_bill_rate       NUMERIC(10,2),
  bill_multiplier      NUMERIC(6,4),
  bill_flat_adjustment NUMERIC(10,2),
  effective_bill_amount NUMERIC(10,2),
  changed_by_person_id BIGINT,
  changed_by_email     TEXT,
  changed_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  notes                TEXT,
  tenant_id            BIGINT NOT NULL
);

ALTER TABLE contest_billing_audit ENABLE ROW LEVEL SECURITY;
CREATE POLICY contest_billing_audit_tenant ON contest_billing_audit
  USING (tenant_id = current_setting('app.current_tenant', true)::bigint);

CREATE INDEX idx_contest_billing_audit_contest ON contest_billing_audit(contest_schedule_id);

-- 3. Remove bill columns from official_contest_assignment
ALTER TABLE official_contest_assignment
  DROP COLUMN IF EXISTS bill_multiplier_override,
  DROP COLUMN IF EXISTS bill_flat_adjustment_override,
  DROP COLUMN IF EXISTS base_bill_rate,
  DROP COLUMN IF EXISTS effective_bill_amount,
  DROP COLUMN IF EXISTS bill_updated_by,
  DROP COLUMN IF EXISTS bill_updated_at;

-- 4. Remove bill columns from assignment_financial_audit
ALTER TABLE assignment_financial_audit
  DROP COLUMN IF EXISTS base_bill_rate,
  DROP COLUMN IF EXISTS bill_multiplier,
  DROP COLUMN IF EXISTS bill_flat_adjustment,
  DROP COLUMN IF EXISTS effective_bill_amount;

-- 5. Update change_type values — all existing records are pay-only now
UPDATE assignment_financial_audit SET change_type = 'pay_override' WHERE change_type = 'pay_and_bill';
