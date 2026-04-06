-- V064: Change assignment_financial_audit FK to CASCADE on DELETE
-- so removing an official also removes their pay audit trail.
-- Must clean orphans and disable RLS temporarily since migration user is subject to RLS.

-- Clean up any orphaned audit records (from prior deletions that bypassed FK)
DELETE FROM app.assignment_financial_audit
WHERE assignment_id NOT IN (
  SELECT assignment_id FROM app.official_contest_assignment
);

-- Drop and re-add the FK with ON DELETE CASCADE
ALTER TABLE app.assignment_financial_audit
  DROP CONSTRAINT IF EXISTS assignment_financial_audit_assignment_id_fkey;

ALTER TABLE app.assignment_financial_audit
  ADD CONSTRAINT assignment_financial_audit_assignment_id_fkey
    FOREIGN KEY (assignment_id)
    REFERENCES app.official_contest_assignment(assignment_id)
    ON DELETE CASCADE
    NOT VALID;

-- Validate separately (NOT VALID + VALIDATE avoids full table lock and RLS issues)
ALTER TABLE app.assignment_financial_audit
  VALIDATE CONSTRAINT assignment_financial_audit_assignment_id_fkey;
