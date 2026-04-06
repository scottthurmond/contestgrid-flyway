-- V028: Add tenant_id + RLS to person_roles and official_slots
-- Backfill from FK chains

-- Enable platform admin bypass for this migration
SELECT set_config('app.is_platform_admin', 'true', true);

------------------------------------------------------------
-- 1. person_roles — backfill via person.tenant_id
------------------------------------------------------------
ALTER TABLE app.person_roles ADD COLUMN tenant_id BIGINT;

UPDATE app.person_roles AS pr
  SET tenant_id = p.tenant_id
  FROM app.person p
  WHERE pr.person_id = p.person_id;

DELETE FROM app.person_roles WHERE tenant_id IS NULL;

ALTER TABLE app.person_roles ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.person_roles
  ADD CONSTRAINT fk_person_roles_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);

ALTER TABLE app.person_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.person_roles FORCE ROW LEVEL SECURITY;
CREATE POLICY person_roles_tenant_isolation ON app.person_roles FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

------------------------------------------------------------
-- 2. official_slots — backfill via officials_association.tenant_id
------------------------------------------------------------
ALTER TABLE app.official_slots ADD COLUMN tenant_id BIGINT;

UPDATE app.official_slots AS os
  SET tenant_id = oa.tenant_id
  FROM app.officials_association oa
  WHERE os.official_association_id = oa.officials_association_id;

DELETE FROM app.official_slots WHERE tenant_id IS NULL;

ALTER TABLE app.official_slots ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.official_slots
  ADD CONSTRAINT fk_official_slots_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);

ALTER TABLE app.official_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.official_slots FORCE ROW LEVEL SECURITY;
CREATE POLICY official_slots_tenant_isolation ON app.official_slots FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);
