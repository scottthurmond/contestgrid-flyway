-- V062: Add stored financial amounts to assignments + audit trail
-- Two financial tracks: official pay and customer billing
-- Every change is recorded for full audit compliance

-- 1. Add computed/snapshotted amount columns to official_contest_assignment
ALTER TABLE app.official_contest_assignment
  ADD COLUMN base_pay_rate          numeric,          -- snapshot of contest_umpire_rate at time of save
  ADD COLUMN effective_pay_amount   numeric,          -- (base_pay_rate * pay_multiplier_override) + pay_flat_adjustment_override
  ADD COLUMN base_bill_rate         numeric,          -- snapshot of contest_bill_amount at time of save
  ADD COLUMN effective_bill_amount  numeric,          -- (base_bill_rate * bill_multiplier_override) + bill_flat_adjustment_override
  ADD COLUMN pay_updated_by        bigint,            -- person_id who last changed pay fields
  ADD COLUMN pay_updated_at        timestamptz,       -- when pay was last changed
  ADD COLUMN bill_updated_by       bigint,            -- person_id who last changed bill fields
  ADD COLUMN bill_updated_at       timestamptz;       -- when bill was last changed

COMMENT ON COLUMN app.official_contest_assignment.base_pay_rate IS 'Snapshot of contest_umpire_rate from contest_rates at time of save';
COMMENT ON COLUMN app.official_contest_assignment.effective_pay_amount IS 'Calculated: (base_pay_rate * COALESCE(pay_multiplier_override,1)) + COALESCE(pay_flat_adjustment_override,0)';
COMMENT ON COLUMN app.official_contest_assignment.base_bill_rate IS 'Snapshot of contest_bill_amount from contest_rates at time of save';
COMMENT ON COLUMN app.official_contest_assignment.effective_bill_amount IS 'Calculated: (base_bill_rate * COALESCE(bill_multiplier_override,1)) + COALESCE(bill_flat_adjustment_override,0)';

-- 2. Create the audit trail table — one row per financial change
CREATE TABLE app.assignment_financial_audit (
  audit_id                      bigserial       PRIMARY KEY,
  assignment_id                 bigint          NOT NULL REFERENCES app.official_contest_assignment(assignment_id),
  change_type                   text            NOT NULL,   -- 'pay_override', 'bill_override', 'rate_applied', 'pay_and_bill'
  -- Pay snapshot
  base_pay_rate                 numeric,
  pay_multiplier                numeric,
  pay_flat_adjustment           numeric,
  effective_pay_amount          numeric,
  -- Bill snapshot
  base_bill_rate                numeric,
  bill_multiplier               numeric,
  bill_flat_adjustment          numeric,
  effective_bill_amount         numeric,
  -- Who / when
  changed_by_person_id          bigint,          -- person_id from JWT sub → person lookup
  changed_by_email              text,            -- email from JWT (denormalized for easy reading)
  changed_at                    timestamptz      NOT NULL DEFAULT NOW(),
  notes                         text,
  tenant_id                     bigint           NOT NULL
);

-- RLS
ALTER TABLE app.assignment_financial_audit ENABLE ROW LEVEL SECURITY;

CREATE POLICY assignment_financial_audit_tenant_isolation
  ON app.assignment_financial_audit
  USING (tenant_id = current_setting('app.current_tenant_id')::bigint);

-- Indexes
CREATE INDEX idx_assignment_financial_audit_assignment
  ON app.assignment_financial_audit(assignment_id);

CREATE INDEX idx_assignment_financial_audit_tenant_changed
  ON app.assignment_financial_audit(tenant_id, changed_at DESC);

COMMENT ON TABLE app.assignment_financial_audit IS 'Full audit trail of every financial change to an assignment (pay and billing)';
