-- V021: Remove min_officials from subscription_tier
--
-- The min of one tier is implied by the max of the previous tier,
-- so min_officials is redundant.

ALTER TABLE subscription_tier DROP COLUMN IF EXISTS min_officials;
