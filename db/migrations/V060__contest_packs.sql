-- V060: Contest packs – group contests for bulk assignment
-- The pack is simply an ID that links contests together.

-- ── contest_pack ──
CREATE TABLE IF NOT EXISTS app.contest_pack (
    contest_pack_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL,
    customer_id      INTEGER NOT NULL REFERENCES app.customer(customer_id),
    created_at       TIMESTAMPTZ DEFAULT now()
);

-- ── contest_pack_member ──
CREATE TABLE IF NOT EXISTS app.contest_pack_member (
    contest_pack_member_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contest_pack_id         BIGINT NOT NULL REFERENCES app.contest_pack(contest_pack_id) ON DELETE CASCADE,
    contest_schedule_id     BIGINT NOT NULL REFERENCES app.contest_schedule(contest_schedule_id) ON DELETE CASCADE,
    tenant_id               BIGINT NOT NULL,
    added_at                TIMESTAMPTZ DEFAULT now(),
    UNIQUE (contest_schedule_id)
);

-- RLS
ALTER TABLE app.contest_pack ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.contest_pack_member ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='contest_pack' AND policyname='contest_pack_tenant_isolation') THEN
    CREATE POLICY contest_pack_tenant_isolation ON app.contest_pack
      USING (current_setting('app.is_platform_admin', true) = 'true'
             OR tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::bigint);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='contest_pack_member' AND policyname='contest_pack_member_tenant_isolation') THEN
    CREATE POLICY contest_pack_member_tenant_isolation ON app.contest_pack_member
      USING (current_setting('app.is_platform_admin', true) = 'true'
             OR tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::bigint);
  END IF;
END $$;

-- Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON app.contest_pack TO contestgrid_lab_id;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.contest_pack_member TO contestgrid_lab_id;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_contest_pack_tenant ON app.contest_pack(tenant_id);
CREATE INDEX IF NOT EXISTS idx_contest_pack_customer ON app.contest_pack(customer_id);
CREATE INDEX IF NOT EXISTS idx_contest_pack_member_pack ON app.contest_pack_member(contest_pack_id);
CREATE INDEX IF NOT EXISTS idx_contest_pack_member_contest ON app.contest_pack_member(contest_schedule_id);
