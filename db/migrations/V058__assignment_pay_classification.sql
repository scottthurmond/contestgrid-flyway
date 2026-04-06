-- V058: Add pay_classification_id to official_contest_assignment
-- Allows per-assignment pay classification selection (e.g. Standard, Premium, etc.)

SET search_path TO app;

ALTER TABLE official_contest_assignment
  ADD COLUMN pay_classification_id BIGINT NULL;

-- FK to pay_classification table
ALTER TABLE official_contest_assignment
  ADD CONSTRAINT fk_oca_pay_classification
  FOREIGN KEY (pay_classification_id) REFERENCES pay_classification(pay_classification_id);

COMMENT ON COLUMN official_contest_assignment.pay_classification_id
  IS 'Optional pay classification override for this assignment; references pay_classification.pay_classification_id';
