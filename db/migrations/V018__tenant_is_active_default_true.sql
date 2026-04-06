-- V018: Change is_active default to true
--
-- New tenants should be active by default.

ALTER TABLE tenant ALTER COLUMN is_active SET DEFAULT true;
