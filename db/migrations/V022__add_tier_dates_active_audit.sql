-- V022: Add start_date, stop_date, is_active to subscription_tier
--       and create subscription_tier_date_audit trail table.

-- ── 1. New columns on subscription_tier ──
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'app' AND table_name = 'subscription_tier' AND column_name = 'start_date'
  ) THEN
    ALTER TABLE subscription_tier ADD COLUMN start_date DATE NOT NULL DEFAULT CURRENT_DATE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'app' AND table_name = 'subscription_tier' AND column_name = 'stop_date'
  ) THEN
    ALTER TABLE subscription_tier ADD COLUMN stop_date DATE NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'app' AND table_name = 'subscription_tier' AND column_name = 'is_active'
  ) THEN
    ALTER TABLE subscription_tier ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;
  END IF;
END $$;

-- ── 2. Check constraint: stop_date must be >= start_date when not null ──
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage
    WHERE table_schema = 'app' AND table_name = 'subscription_tier' AND constraint_name = 'chk_tier_dates'
  ) THEN
    ALTER TABLE subscription_tier
      ADD CONSTRAINT chk_tier_dates CHECK (stop_date IS NULL OR stop_date >= start_date);
  END IF;
END $$;

-- ── 3. Audit trail for tier date changes ──
CREATE TABLE IF NOT EXISTS subscription_tier_date_audit (
  audit_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  subscription_tier_id BIGINT NOT NULL REFERENCES subscription_tier(subscription_tier_id),
  field_changed     VARCHAR(20) NOT NULL,           -- 'start_date', 'stop_date', or 'is_active'
  old_value         TEXT,
  new_value         TEXT,
  changed_by        VARCHAR(255) NOT NULL,          -- email or user identifier
  changed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tier_date_audit_tier
  ON subscription_tier_date_audit(subscription_tier_id);
