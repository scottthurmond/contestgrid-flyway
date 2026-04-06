-- V056: Make team.customer_id nullable
--
-- Teams may or may not belong to a customer. At least one team in a contest
-- must be associated with the paying customer, but the DB enforces that via
-- contest_schedule.customer_id (NOT NULL), not via team.customer_id.

-- 1. Drop the existing unique constraint that includes customer_id
ALTER TABLE app.team DROP CONSTRAINT IF EXISTS uq_team_customer_level_league_name;

-- 2. Make customer_id nullable
ALTER TABLE app.team ALTER COLUMN customer_id DROP NOT NULL;

-- 3. Re-create unique constraint: when customer_id is present use it;
--    a partial unique index covers the NULL-customer case separately.
CREATE UNIQUE INDEX uq_team_customer_level_league_name
  ON app.team (customer_id, contest_level_id, contest_league_id, team_name)
  WHERE customer_id IS NOT NULL;

CREATE UNIQUE INDEX uq_team_no_customer_level_league_name
  ON app.team (contest_level_id, contest_league_id, team_name)
  WHERE customer_id IS NULL;
