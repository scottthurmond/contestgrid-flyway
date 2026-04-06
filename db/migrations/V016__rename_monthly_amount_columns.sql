-- V016: Rename monthly-specific amount columns to billing-period-neutral names
--
-- monthly_base_amount      → bill_amount
-- effective_monthly_amount → effective_bill_amount
--
-- These columns store the per-billing-period amount (monthly OR annual),
-- so the "monthly" prefix was misleading for annual subscriptions.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'app' AND table_name = 'association_subscription'
      AND column_name = 'monthly_base_amount'
  ) THEN
    ALTER TABLE association_subscription RENAME COLUMN monthly_base_amount TO bill_amount;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'app' AND table_name = 'association_subscription'
      AND column_name = 'effective_monthly_amount'
  ) THEN
    ALTER TABLE association_subscription RENAME COLUMN effective_monthly_amount TO effective_bill_amount;
  END IF;
END
$$;

COMMENT ON COLUMN association_subscription.bill_amount IS 'Tier cost × active officials for the billing period (before plan discount)';
COMMENT ON COLUMN association_subscription.effective_bill_amount IS 'Final charge for the billing period after all discounts';
