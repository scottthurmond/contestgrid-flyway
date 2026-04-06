-- ============================================================
-- V035: Encrypt birth_date column in person table
-- ============================================================
-- Uses pgcrypto (must be pre-installed by a superuser).
-- Provides helper functions that read the encryption key from
-- the session variable  app.encryption_key  so application code
-- never embeds the key in SQL text.
-- ============================================================

-- 0. Verify pgcrypto is available
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    RAISE EXCEPTION 'pgcrypto extension is not installed. A superuser must run: CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA public;';
  END IF;
END $$;

-- 1. Helper: encrypt a plaintext value using the session encryption key
CREATE OR REPLACE FUNCTION app.encrypt_pii(plain_text TEXT)
RETURNS BYTEA
LANGUAGE plpgsql IMMUTABLE STRICT AS $$
BEGIN
  RETURN public.pgp_sym_encrypt(
    plain_text,
    current_setting('app.encryption_key')
  );
END;
$$;

-- 2. Helper: decrypt a bytea value back to text
CREATE OR REPLACE FUNCTION app.decrypt_pii(cipher BYTEA)
RETURNS TEXT
LANGUAGE plpgsql IMMUTABLE STRICT AS $$
BEGIN
  RETURN public.pgp_sym_decrypt(
    cipher,
    current_setting('app.encryption_key')
  );
END;
$$;

-- 3. Grant execute to the application role
GRANT EXECUTE ON FUNCTION app.encrypt_pii(TEXT)  TO contestgrid_lab_id;
GRANT EXECUTE ON FUNCTION app.decrypt_pii(BYTEA) TO contestgrid_lab_id;

-- 4. Convert person.birth_date from DATE → BYTEA (encrypted)
--    First encrypt any existing non-null values, then alter column type.
--    NOTE: If existing rows have birth_date values, we need the encryption
--    key set before migration. For fresh/empty data this is a no-op.

-- Add a temporary bytea column
ALTER TABLE app.person ADD COLUMN birth_date_enc BYTEA;

-- Copy + encrypt any existing values (requires app.encryption_key to be set
-- if rows exist; safe to skip if column is all NULLs which is our case).
-- We use a DO block so we can conditionally encrypt only when data exists.
DO $$
DECLARE
  row_count INT;
BEGIN
  SELECT count(*) INTO row_count FROM app.person WHERE birth_date IS NOT NULL;
  IF row_count > 0 THEN
    -- The migration runner must SET app.encryption_key before running this.
    UPDATE app.person
    SET birth_date_enc = app.encrypt_pii(birth_date::TEXT)
    WHERE birth_date IS NOT NULL;
  END IF;
END $$;

-- Drop old column, rename new one
ALTER TABLE app.person DROP COLUMN birth_date;
ALTER TABLE app.person RENAME COLUMN birth_date_enc TO birth_date;

-- 5. Add a comment for documentation
COMMENT ON COLUMN app.person.birth_date IS 'PII-encrypted (pgp_sym_encrypt). Decrypt with app.decrypt_pii(birth_date). Stores YYYY-MM-DD date string.';
