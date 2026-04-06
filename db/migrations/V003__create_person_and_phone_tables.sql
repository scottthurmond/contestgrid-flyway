-- V003__create_person_and_phone_tables.sql
-- Description: Create person (coaches, officials, contacts) and phone tables

CREATE TABLE phone (
  PHONE_ID BIGSERIAL PRIMARY KEY,
  PERSON_ID BIGINT,
  NUMBER VARCHAR(20) NOT NULL,
  EXTENSION VARCHAR(10),
  PHONE_TYPE INT,
  CARRIER INT,
  PUBLIC BOOLEAN DEFAULT false,
  NOTES TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_phone_person_id ON phone(PERSON_ID);

COMMENT ON TABLE phone IS 'Phone contact information for persons';

-- Person table - multi-tenant (coaches, officials, contacts)
CREATE TABLE person (
  PERSON_ID BIGSERIAL PRIMARY KEY,
  tenant_id BIGINT NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  PERSON_TYPE_ID INT NOT NULL REFERENCES person_type(PERSON_TYPE_ID),
  phone_id BIGINT REFERENCES phone(PHONE_ID),
  ADDRESS_ID BIGINT REFERENCES address(address_id),
  EMAIL_ADDRESS VARCHAR(255) NOT NULL,
  FIRST_NAME VARCHAR(45),
  MIDDLE_NAME VARCHAR(45),
  LAST_NAME VARCHAR(45),
  NICK_NAME VARCHAR(45),
  SUFFIX VARCHAR(45),
  BIRTH_DATE DATE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_person_tenant_id ON person(tenant_id);
CREATE INDEX idx_person_email ON person(EMAIL_ADDRESS);
CREATE INDEX idx_person_type ON person(PERSON_TYPE_ID);

COMMENT ON TABLE person IS 'Persons in the system (coaches, officials, contacts, etc.)';

-- Add phone constraint after person table exists
ALTER TABLE phone ADD CONSTRAINT fk_phone_person_id FOREIGN KEY (PERSON_ID) REFERENCES person(PERSON_ID) ON DELETE CASCADE;

-- Person roles junction table
CREATE TABLE person_roles (
  PERSON_ID BIGINT NOT NULL REFERENCES person(PERSON_ID) ON DELETE CASCADE,
  ROLE_ID INT NOT NULL REFERENCES roles(ROLE_ID) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (PERSON_ID, ROLE_ID)
);

COMMENT ON TABLE person_roles IS 'Maps roles to persons (many-to-many)';
