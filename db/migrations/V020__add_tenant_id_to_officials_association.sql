-- V020: Add tenant_id to officials_association
--
-- Each officials association belongs to a tenant (its owning org).
-- This allows direct lookup of subscriptions when a tenant is deactivated.
-- The existing officials_tenant_map is a *different* relationship:
--   it maps which league tenants an association works WITH.

ALTER TABLE officials_association
  ADD COLUMN IF NOT EXISTS tenant_id BIGINT REFERENCES tenant(tenant_id) ON DELETE RESTRICT;

-- Backfill: MUA (officials_association_id=1) belongs to tenant 1 (Metro Umpires Association)
UPDATE officials_association
SET tenant_id = 1
WHERE officials_association_id = 1
  AND tenant_id IS NULL;

-- Add index for lookups
CREATE INDEX IF NOT EXISTS idx_officials_association_tenant ON officials_association(tenant_id);

COMMENT ON COLUMN officials_association.tenant_id IS 'The tenant that owns this officials association';
