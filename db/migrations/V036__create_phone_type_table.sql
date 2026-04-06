-- V036: Create phone_type definition table (not tenant-aware)
-- Replaces hardcoded phone_type integer convention with a proper lookup table.

-- 1. Create the phone_type table
CREATE TABLE IF NOT EXISTS app.phone_type (
    phone_type_id   INTEGER PRIMARY KEY,
    phone_type_name VARCHAR(50)  NOT NULL UNIQUE,
    aliases         VARCHAR(200),          -- comma-separated alternative labels accepted during import
    display_order   INTEGER      NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON TABLE  app.phone_type IS 'System-wide phone type definitions (not tenant-scoped)';
COMMENT ON COLUMN app.phone_type.aliases IS 'Comma-separated alternative labels accepted during CSV import (e.g. "cell" for Mobile)';

-- 2. Seed the three standard phone types
INSERT INTO app.phone_type (phone_type_id, phone_type_name, aliases, display_order) VALUES
  (1, 'Mobile', 'cell',             1),
  (2, 'Home',   NULL,               2),
  (3, 'Work',   'office,business',  3);

-- 3. Add foreign key from phone.phone_type → phone_type.phone_type_id
ALTER TABLE app.phone
    ADD CONSTRAINT phone_phone_type_fk
    FOREIGN KEY (phone_type) REFERENCES app.phone_type (phone_type_id);

-- 4. No RLS on phone_type — it is a global definition table readable by all authenticated users.
--    RLS is NOT enabled so every session can read the rows without tenant context.

-- 5. Grant access
GRANT SELECT ON app.phone_type TO contestgrid_lab_id;

-- 6. Add updated_at trigger (consistent with V033 pattern)
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON app.phone_type
    FOR EACH ROW
    EXECUTE FUNCTION app.set_updated_at();
