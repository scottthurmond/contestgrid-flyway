-- V048: Make officials_association_id nullable on venue
-- Venues are now shared across tenants, so not every venue originates from
-- a tenant that has an officials_association record.

ALTER TABLE app.venue
  ALTER COLUMN officials_association_id DROP NOT NULL;
