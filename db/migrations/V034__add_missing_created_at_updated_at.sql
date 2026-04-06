-- V034: Ensure every table has created_at and updated_at columns
--
-- Adds missing columns with sensible defaults and attaches the
-- updated_at trigger (from V033) to each newly eligible table.

-- 1. Add updated_at to tables that have created_at but not updated_at
--    Default to created_at for existing rows so timestamps stay consistent.
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN
    SELECT t.table_name
      FROM information_schema.tables t
     WHERE t.table_schema = 'app'
       AND t.table_type = 'BASE TABLE'
       AND t.table_name != 'flyway_schema_history'
       AND EXISTS (
         SELECT 1 FROM information_schema.columns c
          WHERE c.table_schema = 'app' AND c.table_name = t.table_name
            AND c.column_name = 'created_at'
       )
       AND NOT EXISTS (
         SELECT 1 FROM information_schema.columns c
          WHERE c.table_schema = 'app' AND c.table_name = t.table_name
            AND c.column_name = 'updated_at'
       )
     ORDER BY t.table_name
  LOOP
    -- Add column, default existing rows to their created_at value
    EXECUTE format(
      'ALTER TABLE app.%I ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()',
      tbl
    );
    EXECUTE format(
      'UPDATE app.%I SET updated_at = created_at',
      tbl
    );

    -- Attach the trigger
    EXECUTE format(
      'CREATE TRIGGER trg_set_updated_at
       BEFORE UPDATE ON app.%I
       FOR EACH ROW
       EXECUTE FUNCTION app.set_updated_at()',
      tbl
    );

    RAISE NOTICE 'Added updated_at + trigger to app.%', tbl;
  END LOOP;
END;
$$;

-- 2. Add both columns to tables missing both (subscription_tier_date_audit)
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN
    SELECT t.table_name
      FROM information_schema.tables t
     WHERE t.table_schema = 'app'
       AND t.table_type = 'BASE TABLE'
       AND t.table_name != 'flyway_schema_history'
       AND NOT EXISTS (
         SELECT 1 FROM information_schema.columns c
          WHERE c.table_schema = 'app' AND c.table_name = t.table_name
            AND c.column_name = 'created_at'
       )
       AND NOT EXISTS (
         SELECT 1 FROM information_schema.columns c
          WHERE c.table_schema = 'app' AND c.table_name = t.table_name
            AND c.column_name = 'updated_at'
       )
     ORDER BY t.table_name
  LOOP
    EXECUTE format(
      'ALTER TABLE app.%I ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()',
      tbl
    );
    EXECUTE format(
      'ALTER TABLE app.%I ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()',
      tbl
    );

    EXECUTE format(
      'CREATE TRIGGER trg_set_updated_at
       BEFORE UPDATE ON app.%I
       FOR EACH ROW
       EXECUTE FUNCTION app.set_updated_at()',
      tbl
    );

    RAISE NOTICE 'Added created_at + updated_at + trigger to app.%', tbl;
  END LOOP;
END;
$$;
