-- V052: Add per-assignment pay/bill override columns
--
-- Allows each official assigned to a contest to have independent
-- pay and/or bill multiplier & flat-adjustment overrides.
-- NULL = use the contest_rates default for that field.
-- Pay and bill overrides are fully independent of each other.

ALTER TABLE app.official_contest_assignment
  ADD COLUMN pay_multiplier_override    NUMERIC(10,4) DEFAULT NULL,
  ADD COLUMN pay_flat_adjustment_override NUMERIC(10,2) DEFAULT NULL,
  ADD COLUMN bill_multiplier_override   NUMERIC(10,4) DEFAULT NULL,
  ADD COLUMN bill_flat_adjustment_override NUMERIC(10,2) DEFAULT NULL;

COMMENT ON COLUMN app.official_contest_assignment.pay_multiplier_override
  IS 'Per-official pay multiplier override. NULL = use contest_rates.pay_multiplier.';
COMMENT ON COLUMN app.official_contest_assignment.pay_flat_adjustment_override
  IS 'Per-official pay flat adjustment override. NULL = use contest_rates.pay_flat_adjustment.';
COMMENT ON COLUMN app.official_contest_assignment.bill_multiplier_override
  IS 'Per-official bill multiplier override. NULL = use contest_rates.bill_multiplier.';
COMMENT ON COLUMN app.official_contest_assignment.bill_flat_adjustment_override
  IS 'Per-official bill flat adjustment override. NULL = use contest_rates.bill_flat_adjustment.';
