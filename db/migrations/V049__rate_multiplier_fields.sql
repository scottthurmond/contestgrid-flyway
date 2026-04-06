-- V049: Add multiplier and flat adjustment fields to contest_rates
--
-- Use case: If the normal bill rate for a Senior game is $50, but only one
-- umpire was used, the association might bill 1.5× the normal rate, or add
-- a flat surcharge, or both.  Same concept applies to official pay.
--
-- Effective bill  = (contest_bill_amount × bill_multiplier) + bill_flat_adjustment
-- Effective pay   = (contest_umpire_rate × pay_multiplier)  + pay_flat_adjustment

ALTER TABLE app.contest_rates
  ADD COLUMN bill_multiplier      NUMERIC(5,2) NOT NULL DEFAULT 1.00,
  ADD COLUMN bill_flat_adjustment NUMERIC(10,2) NOT NULL DEFAULT 0.00,
  ADD COLUMN pay_multiplier       NUMERIC(5,2) NOT NULL DEFAULT 1.00,
  ADD COLUMN pay_flat_adjustment  NUMERIC(10,2) NOT NULL DEFAULT 0.00;

COMMENT ON COLUMN app.contest_rates.bill_multiplier IS 'Multiplier applied to contest_bill_amount (e.g. 1.5 = 150% of base)';
COMMENT ON COLUMN app.contest_rates.bill_flat_adjustment IS 'Flat dollar amount added to (contest_bill_amount × bill_multiplier)';
COMMENT ON COLUMN app.contest_rates.pay_multiplier IS 'Multiplier applied to contest_umpire_rate (e.g. 1.5 = 150% of base)';
COMMENT ON COLUMN app.contest_rates.pay_flat_adjustment IS 'Flat dollar amount added to (contest_umpire_rate × pay_multiplier)';
