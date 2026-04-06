-- V006__create_venue_tables.sql
-- Description: Create venue and sub-venue tables

CREATE TABLE venue (
  VENUE_ID BIGSERIAL PRIMARY KEY,
  tenant_id BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  VENUE_ADDRESS_ID BIGINT NOT NULL REFERENCES address(address_id) ON DELETE RESTRICT,
  OFFICIALS_ASSOCIATION_ID BIGINT NOT NULL REFERENCES officials_association(OFFICIALS_ASSOCIATION_ID) ON DELETE RESTRICT,
  VENUE_NAME VARCHAR(100) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_venue_tenant_id ON venue(tenant_id);
CREATE INDEX idx_venue_address_id ON venue(VENUE_ADDRESS_ID);
CREATE INDEX idx_venue_association_id ON venue(OFFICIALS_ASSOCIATION_ID);

COMMENT ON TABLE venue IS 'Physical venues/locations for contests (fields, courts, etc.)';

CREATE TABLE venue_sub (
  sub_venue_id BIGSERIAL PRIMARY KEY,
  VENUE_ID BIGINT NOT NULL REFERENCES venue(VENUE_ID) ON DELETE CASCADE,
  SUB_VENUE_NAME VARCHAR(45) NOT NULL,
  SUB_VENUE_DESC VARCHAR(255),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (VENUE_ID, SUB_VENUE_NAME)
);

CREATE INDEX idx_venue_sub_venue_id ON venue_sub(VENUE_ID);

COMMENT ON TABLE venue_sub IS 'Sub-venues within a venue (individual courts, fields, etc.)';
