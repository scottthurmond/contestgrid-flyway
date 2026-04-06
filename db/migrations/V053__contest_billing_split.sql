-- V053: Add customer_id to contest_schedule + contest_billing_split table
--
-- 1. Add customer_id to contest_schedule (the primary/default payer)
-- 2. Create contest_billing_split for split-billing scenarios
-- 3. Add contest_season_id to contest_schedule for season context

-- ── 1. Add customer_id to contest_schedule ──
ALTER TABLE app.contest_schedule
  ADD COLUMN customer_id INTEGER;

-- Backfill from home team's customer_id
UPDATE app.contest_schedule cs
SET customer_id = t.customer_id
FROM app.team t
WHERE t.team_id = cs.home_team_id;

-- Now make it NOT NULL
ALTER TABLE app.contest_schedule
  ALTER COLUMN customer_id SET NOT NULL;

ALTER TABLE app.contest_schedule
  ADD CONSTRAINT contest_schedule_customer_id_fkey
  FOREIGN KEY (customer_id) REFERENCES app.customer(customer_id) ON DELETE RESTRICT;

-- ── 2. Add optional contest_season_id ──
ALTER TABLE app.contest_schedule
  ADD COLUMN contest_season_id BIGINT;

ALTER TABLE app.contest_schedule
  ADD CONSTRAINT contest_schedule_contest_season_id_fkey
  FOREIGN KEY (contest_season_id) REFERENCES app.contest_season(contest_season_id) ON DELETE SET NULL;

-- ── 3. Create contest_billing_split ──
-- Supports splitting bills by percentage or flat amount.
-- When a contest has rows in this table, they override the simple customer_id payer.
CREATE TABLE app.contest_billing_split (
  billing_split_id    SERIAL PRIMARY KEY,
  contest_schedule_id BIGINT NOT NULL REFERENCES app.contest_schedule(contest_schedule_id) ON DELETE CASCADE,
  customer_id         INTEGER NOT NULL REFERENCES app.customer(customer_id) ON DELETE RESTRICT,
  split_type          VARCHAR(10) NOT NULL CHECK (split_type IN ('percent', 'amount')),
  split_value         NUMERIC(10,2) NOT NULL,  -- percentage (0-100) or dollar amount
  tenant_id           BIGINT NOT NULL REFERENCES app.tenant(tenant_id) ON DELETE CASCADE,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE app.contest_billing_split ENABLE ROW LEVEL SECURITY;
CREATE POLICY billing_split_tenant_isolation ON app.contest_billing_split
  USING (
    current_setting('app.is_platform_admin', true) = 'true'
    OR tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::bigint
  )
  WITH CHECK (
    current_setting('app.is_platform_admin', true) = 'true'
    OR tenant_id = current_setting('app.tenant_id', true)::bigint
  );

-- Grant access
GRANT SELECT, INSERT, UPDATE, DELETE ON app.contest_billing_split TO contestgrid_lab_id;
GRANT USAGE, SELECT ON SEQUENCE app.contest_billing_split_billing_split_id_seq TO contestgrid_lab_id;

-- Index for lookups
CREATE INDEX idx_billing_split_contest ON app.contest_billing_split(contest_schedule_id);

COMMENT ON TABLE app.contest_billing_split
  IS 'Split-billing for contests. Each row assigns a portion of the contest bill to a customer. split_type=percent uses 0-100 scale; split_type=amount uses a dollar value.';
COMMENT ON COLUMN app.contest_schedule.customer_id
  IS 'Primary payer for this contest. Defaults to the home team customer. Can be overridden by contest_billing_split rows.';
COMMENT ON COLUMN app.contest_schedule.contest_season_id
  IS 'Optional season context for this contest.';
