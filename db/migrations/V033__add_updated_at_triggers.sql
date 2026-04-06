-- V033: Add updated_at trigger to all tables that have an updated_at column
--
-- Creates a reusable trigger function and attaches it to every table
-- in the app schema that has an updated_at column.  On any UPDATE the
-- column is automatically set to NOW().

-- 1. Create the trigger function
CREATE OR REPLACE FUNCTION app.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Attach the trigger to every table that has an updated_at column
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN
    SELECT table_name
      FROM information_schema.columns
     WHERE table_schema = 'app'
       AND column_name  = 'updated_at'
     ORDER BY table_name
  LOOP
    EXECUTE format(
      'CREATE TRIGGER trg_set_updated_at
       BEFORE UPDATE ON app.%I
       FOR EACH ROW
       EXECUTE FUNCTION app.set_updated_at()',
      tbl
    );
    RAISE NOTICE 'Created updated_at trigger on app.%', tbl;
  END LOOP;
END;
$$;
