-- V002__create_tenant_and_address_tables.sql
-- Description: Create multi-tenant foundation tables (tenant, address)
-- These are the base tables for multi-tenancy; all other tables reference tenant_id

CREATE TABLE tenant (
  tenant_id BIGSERIAL PRIMARY KEY,
  tenant_name VARCHAR(255) NOT NULL,
  tenant_abbreviation VARCHAR(10) NOT NULL,
  tenant_type_id INT NOT NULL REFERENCES tenant_type(tenant_type_id),
  tenant_sub_domain VARCHAR(50) UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE index idx_tenant_subdomain ON tenant(tenant_sub_domain);
CREATE INDEX idx_tenant_type_id ON tenant(tenant_type_id);

COMMENT ON TABLE tenant IS 'Multi-tenant root entities (leagues, officials associations)';
COMMENT ON COLUMN tenant.tenant_sub_domain IS 'Unique subdomain for tenant (e.g., dacula, brookwood)';

-- Address table - multi-tenant (address belongs to specific tenant)
CREATE TABLE address (
  address_id BIGSERIAL PRIMARY KEY,
  tenant_id BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  address_1 VARCHAR(255),
  address_2 VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(2),
  postal_code VARCHAR(10),
  country_code VARCHAR(2),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_address_tenant_id ON address(tenant_id);

COMMENT ON TABLE address IS 'Physical addresses for venues, officials associations, etc.';
