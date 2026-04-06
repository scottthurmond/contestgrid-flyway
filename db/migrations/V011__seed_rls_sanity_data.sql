-- V011__seed_rls_sanity_data.sql
-- Description: Seed deterministic test data for validating tenant isolation (RLS)
-- Safe to run once in shared dev environments (idempotent inserts)

-- -----------------------------------------------------------------------------
-- Tenants used for RLS sanity testing
-- -----------------------------------------------------------------------------
INSERT INTO tenant (tenant_id, tenant_name, tenant_abbreviation, tenant_type_id, tenant_sub_domain)
VALUES
  (1001, 'RLS Tenant One', 'RLS1', 2, 'rls-tenant-1'),
  (1002, 'RLS Tenant Two', 'RLS2', 2, 'rls-tenant-2')
ON CONFLICT (tenant_id) DO NOTHING;

-- Keep serial sequence aligned after explicit IDs
SELECT setval(
  pg_get_serial_sequence('tenant', 'tenant_id'),
  GREATEST((SELECT COALESCE(MAX(tenant_id), 1) FROM tenant), 1),
  true
);

-- -----------------------------------------------------------------------------
-- Person rows (one per tenant) for RLS filtering checks
-- person_type_id = 2 (Contact) from V001 seed
-- -----------------------------------------------------------------------------
INSERT INTO person (
  tenant_id,
  person_type_id,
  email_address,
  first_name,
  last_name
)
VALUES
  (1001, 2, 'alice@rls-tenant-1.test', 'Alice', 'TenantOne'),
  (1002, 2, 'bob@rls-tenant-2.test', 'Bob', 'TenantTwo')
ON CONFLICT DO NOTHING;

-- -----------------------------------------------------------------------------
-- Optional manual verification (run in psql as NON-superuser):
--
--   SET app.tenant_id = '1001';
--   SELECT person_id, tenant_id, email_address FROM person ORDER BY person_id;
--
--   SET app.tenant_id = '1002';
--   SELECT person_id, tenant_id, email_address FROM person ORDER BY person_id;
--
-- Expected: each query only returns rows for that tenant.
-- -----------------------------------------------------------------------------
