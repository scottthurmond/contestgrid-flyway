-- V019: Add suspended_at timestamp to association_subscription
--
-- Records when a subscription was suspended (e.g., tenant deactivation).
-- Mirrors the existing cancelled_at pattern.

ALTER TABLE association_subscription ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMPTZ;

COMMENT ON COLUMN association_subscription.suspended_at IS 'Timestamp when the subscription was suspended, NULL if not suspended';
