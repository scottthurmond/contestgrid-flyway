-- V050: Redesign contest_rates
--   - Add contest_rate_id serial PK (replacing composite PK)
--   - Make contest_league_id NOT NULL
--   - Add effective_start_date, effective_end_date, is_active
--   - Add exclusion constraint preventing overlapping date ranges
--     for the same (officials_association_id, tenant_id, sport_id,
--     contest_level_id, contest_league_id)

-- 0. Temporarily disable RLS so migration user can see all rows
ALTER TABLE app.contest_rates DISABLE ROW LEVEL SECURITY;

-- 0a. Remove any existing rows with NULL league (pre-redesign test data)
DELETE FROM app.contest_rates WHERE contest_league_id IS NULL;

-- 1. Drop old composite primary key
ALTER TABLE app.contest_rates
  DROP CONSTRAINT contest_rates_pkey;

-- 2. Add surrogate PK
ALTER TABLE app.contest_rates
  ADD COLUMN contest_rate_id SERIAL;

ALTER TABLE app.contest_rates
  ADD PRIMARY KEY (contest_rate_id);

-- 3. Make contest_league_id NOT NULL
ALTER TABLE app.contest_rates
  ALTER COLUMN contest_league_id SET NOT NULL;

-- 4. Add date range and active flag columns
ALTER TABLE app.contest_rates
  ADD COLUMN effective_start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  ADD COLUMN effective_end_date   DATE,
  ADD COLUMN is_active            BOOLEAN NOT NULL DEFAULT true;

-- 5. Exclusion constraint: no overlapping date ranges for the same
--    association + tenant + sport + level + league combination.
--    Uses daterange with && (overlap) operator.
--    NULL effective_end_date treated as 'infinity'.
ALTER TABLE app.contest_rates
  ADD CONSTRAINT contest_rates_no_overlap
  EXCLUDE USING gist (
    officials_association_id WITH =,
    tenant_id               WITH =,
    sport_id                WITH =,
    contest_level_id        WITH =,
    contest_league_id       WITH =,
    daterange(effective_start_date, COALESCE(effective_end_date, '9999-12-31'::date), '[]') WITH &&
  );

-- 6. Index for fast lookups by tenant + active
CREATE INDEX idx_contest_rates_tenant_active
  ON app.contest_rates (tenant_id, is_active)
  WHERE is_active = true;

-- 7. Unique constraint so we still prevent exact-duplicate combos
--    within the same date range boundary (belt-and-suspenders with the exclusion).
CREATE UNIQUE INDEX idx_contest_rates_natural_key
  ON app.contest_rates (
    officials_association_id, tenant_id, sport_id,
    contest_level_id, contest_league_id, effective_start_date
  );

-- 8. Re-enable RLS
ALTER TABLE app.contest_rates ENABLE ROW LEVEL SECURITY;
