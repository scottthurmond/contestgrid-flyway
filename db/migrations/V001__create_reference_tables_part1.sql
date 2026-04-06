-- V001__create_reference_tables_part1.sql
-- Description: Create person_type, contest_status, contest_type, sport reference tables
-- These tables are shared across all tenants (no tenant_id)

CREATE TABLE person_type (
  PERSON_TYPE_ID SERIAL PRIMARY KEY,
  PERSON_TYPE_DESCRIPTION VARCHAR(45) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO person_type (PERSON_TYPE_ID, PERSON_TYPE_DESCRIPTION) VALUES
  (1, 'Payer'),
  (2, 'Contact'),
  (3, 'Official');

CREATE TABLE contest_status (
  CONTEST_STATUS_ID SERIAL PRIMARY KEY,
  CONTEST_STATUS_NAME VARCHAR(45) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO contest_status (CONTEST_STATUS_NAME) VALUES
  ('Normal'),
  ('Cancelled'),
  ('Rainout'),
  ('Forfeit'),
  ('Suspended');

CREATE TABLE contest_type (
  contest_type_id SERIAL PRIMARY KEY,
  CONTEST_TYPE_NAME VARCHAR(45) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE sport (
  sport_id SERIAL PRIMARY KEY,
  sport_name VARCHAR(45) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE tenant_type (
  tenant_type_id SERIAL PRIMARY KEY,
  tenant_type_name VARCHAR(45) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO tenant_type (tenant_type_name) VALUES
  ('Officials Association'),
  ('Sports League');

CREATE TABLE roles (
  ROLE_ID SERIAL PRIMARY KEY,
  ROLE_DESCRIPTION VARCHAR(100) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO roles (ROLE_DESCRIPTION) VALUES
  ('Primary Assigner Admin'),
  ('Secondary Assigner Admin'),
  ('League Director'),
  ('Coach'),
  ('Official');

COMMENT ON TABLE person_type IS 'Reference table for person types (Payer, Contact, Official)';
COMMENT ON TABLE contest_status IS 'Reference table for contest statuses (Normal, Cancelled, Rainout, etc.)';
COMMENT ON TABLE contest_type IS 'Reference table for contest types (League, Tournament, etc.)';
COMMENT ON TABLE sport IS 'Reference table for sports (Baseball, Softball, etc.)';
COMMENT ON TABLE tenant_type IS 'Reference table for tenant types (Officials Association, Sports League)';
COMMENT ON TABLE roles IS 'Reference table for user roles in the system';
