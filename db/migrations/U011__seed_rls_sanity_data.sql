-- U011__seed_rls_sanity_data.sql
-- Description: Undo seed data created by V011__seed_rls_sanity_data.sql
-- Scope: Dev/test cleanup only

-- Remove seeded person rows first (child/related table)
DELETE FROM person
WHERE email_address IN ('alice@rls-tenant-1.test', 'bob@rls-tenant-2.test');

-- Remove seeded tenant rows
DELETE FROM tenant
WHERE tenant_id IN (1001, 1002)
  AND tenant_sub_domain IN ('rls-tenant-1', 'rls-tenant-2');

-- Re-align tenant sequence after deletes
SELECT setval(
  pg_get_serial_sequence('tenant', 'tenant_id'),
  GREATEST((SELECT COALESCE(MAX(tenant_id), 1) FROM tenant), 1),
  true
);
