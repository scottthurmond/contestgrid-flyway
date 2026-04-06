-- ============================================================
-- V044: Official Profile & Qualifications (ADR-0036)
-- ============================================================
-- Creates all database structures for the enhanced official
-- profile: certifications, appearance compliance, travel
-- origins, venue/team preferences, pay classification, and
-- new official_config columns (years of service, schedule
-- limits, payment method).
--
-- Tables created:
--   1. certification_type           – reference: cert/license types
--   2. official_certification       – official ↔ certification instances
--   3. appearance_checklist_item    – reference: appearance check items
--   4. appearance_check             – per-official appearance inspection
--   5. appearance_check_detail      – line items within an inspection
--   6. pay_classification           – reference: pay modifier tiers
--   7. official_travel_origin       – multi-address travel preferences
--   8. official_venue_preference    – preferred/restricted venues
--   9. official_team_preference     – preferred/restricted teams
--
-- Also:
--   - ALTER official_config: add service_start, schedule limits,
--     pay classification, payment method columns
--   - Backfill service_start from association_joined_date
--   - RLS policies for all new tables
--   - updated_at triggers for all new tables
-- ============================================================

SET search_path TO app, public;

-- Enable platform-admin bypass so RLS doesn't block backfill
SELECT set_config('app.is_platform_admin', 'true', false);

-- ============================================================
-- 1. REFERENCE TABLES
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1a. certification_type
-- ────────────────────────────────────────────────────────────
CREATE TABLE certification_type (
    certification_type_id   SERIAL        PRIMARY KEY,
    certification_type_name VARCHAR(100)  NOT NULL,
    issuing_body            VARCHAR(200),
    sport_id                INTEGER       REFERENCES sport(sport_id),
    requires_renewal        BOOLEAN       NOT NULL DEFAULT false,
    default_validity_months INTEGER,
    tenant_id               BIGINT        NOT NULL REFERENCES tenant(tenant_id),
    created_at              TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT uq_cert_type_name_tenant
        UNIQUE (tenant_id, certification_type_name)
);

COMMENT ON TABLE  certification_type IS 'Reference table for official certification/license types (ADR-0036 §1)';
COMMENT ON COLUMN certification_type.requires_renewal IS 'Whether this cert expires and must be renewed periodically';
COMMENT ON COLUMN certification_type.default_validity_months IS 'Default validity in months; NULL = indefinite';

-- ────────────────────────────────────────────────────────────
-- 1b. appearance_checklist_item
-- ────────────────────────────────────────────────────────────
CREATE TABLE appearance_checklist_item (
    checklist_item_id  SERIAL        PRIMARY KEY,
    item_name          VARCHAR(150)  NOT NULL,
    sport_id           INTEGER       REFERENCES sport(sport_id),
    is_required        BOOLEAN       NOT NULL DEFAULT true,
    display_order      INTEGER       NOT NULL DEFAULT 0,
    tenant_id          BIGINT        NOT NULL REFERENCES tenant(tenant_id),
    created_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT uq_checklist_item_name_tenant
        UNIQUE (tenant_id, item_name)
);

COMMENT ON TABLE appearance_checklist_item IS 'Reference table for appearance-compliance checklist items (ADR-0036 §4)';

-- ────────────────────────────────────────────────────────────
-- 1c. pay_classification
-- ────────────────────────────────────────────────────────────
CREATE TABLE pay_classification (
    pay_classification_id SERIAL        PRIMARY KEY,
    classification_name   VARCHAR(100)  NOT NULL,
    rate_modifier         NUMERIC(5,4)  DEFAULT 1.0000,
    tenant_id             BIGINT        NOT NULL REFERENCES tenant(tenant_id),
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT uq_pay_class_name_tenant
        UNIQUE (tenant_id, classification_name),
    CONSTRAINT chk_rate_modifier_positive
        CHECK (rate_modifier > 0)
);

COMMENT ON TABLE  pay_classification IS 'Pay rate multiplier tiers for officials (ADR-0036 §8)';
COMMENT ON COLUMN pay_classification.rate_modifier IS 'Multiplier applied to base contest_rates.contest_umpire_rate (e.g. 1.25 = 25% premium)';


-- ============================================================
-- 2. ALTER official_config — add profile columns
-- ============================================================

-- 2a. Years of service (§3)
ALTER TABLE official_config
    ADD COLUMN service_start_month SMALLINT,
    ADD COLUMN service_start_year  SMALLINT;

-- Backfill from association_joined_date (which is NOT NULL)
UPDATE official_config
   SET service_start_month = EXTRACT(MONTH FROM association_joined_date)::SMALLINT,
       service_start_year  = EXTRACT(YEAR  FROM association_joined_date)::SMALLINT;

-- Now enforce NOT NULL
ALTER TABLE official_config
    ALTER COLUMN service_start_month SET NOT NULL,
    ALTER COLUMN service_start_year  SET NOT NULL;

ALTER TABLE official_config
    ADD CONSTRAINT chk_service_start_month CHECK (service_start_month BETWEEN 1 AND 12),
    ADD CONSTRAINT chk_service_start_year  CHECK (service_start_year  BETWEEN 1950 AND 2100);

-- 2b. Schedule limits (§7)
ALTER TABLE official_config
    ADD COLUMN max_games_per_day  SMALLINT,
    ADD COLUMN max_games_per_week SMALLINT;

ALTER TABLE official_config
    ADD CONSTRAINT chk_max_games_per_day  CHECK (max_games_per_day  > 0),
    ADD CONSTRAINT chk_max_games_per_week CHECK (max_games_per_week > 0);

-- 2c. Pay classification (§8)
ALTER TABLE official_config
    ADD COLUMN pay_classification_id INTEGER REFERENCES pay_classification(pay_classification_id);

-- 2d. Payment method (§9)
ALTER TABLE official_config
    ADD COLUMN preferred_payment_method VARCHAR(30);

ALTER TABLE official_config
    ADD CONSTRAINT chk_payment_method CHECK (
        preferred_payment_method IS NULL
        OR preferred_payment_method IN (
            'check', 'direct_deposit', 'venmo', 'zelle', 'cash_app', 'paypal'
        )
    );


-- ============================================================
-- 3. DEPENDENT TABLES
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 3a. official_certification (§1)
-- ────────────────────────────────────────────────────────────
CREATE TABLE official_certification (
    official_certification_id BIGSERIAL     PRIMARY KEY,
    official_id              BIGINT        NOT NULL REFERENCES official(official_id),
    certification_type_id    INTEGER       NOT NULL REFERENCES certification_type(certification_type_id),
    certificate_number       VARCHAR(100),
    issued_date              DATE,
    expiry_date              DATE,
    status                   VARCHAR(20)   NOT NULL DEFAULT 'active',
    document_url             TEXT,
    notes                    TEXT,
    tenant_id                BIGINT        NOT NULL REFERENCES tenant(tenant_id),
    created_at               TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT chk_cert_status CHECK (
        status IN ('active', 'expired', 'revoked', 'pending')
    )
);

-- One active cert per type per official
CREATE UNIQUE INDEX uq_official_cert_active
    ON official_certification (official_id, certification_type_id)
    WHERE status = 'active';

-- Admin expiration queries
CREATE INDEX idx_cert_expiry
    ON official_certification (tenant_id, status, expiry_date);

COMMENT ON TABLE official_certification IS 'Certification/license instances held by officials (ADR-0036 §1)';

-- ────────────────────────────────────────────────────────────
-- 3b. appearance_check (§4)
-- ────────────────────────────────────────────────────────────
CREATE TABLE appearance_check (
    appearance_check_id BIGSERIAL     PRIMARY KEY,
    official_id         BIGINT        NOT NULL REFERENCES official(official_id),
    contest_schedule_id BIGINT        REFERENCES contest_schedule(contest_schedule_id),
    checked_by          BIGINT        NOT NULL REFERENCES person(person_id),
    check_date          DATE          NOT NULL,
    overall_pass        BOOLEAN       NOT NULL,
    notes               TEXT,
    tenant_id           BIGINT        NOT NULL REFERENCES tenant(tenant_id),
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX idx_appearance_check_official
    ON appearance_check (official_id, check_date DESC);

COMMENT ON TABLE appearance_check IS 'Per-official appearance compliance inspections (ADR-0036 §4)';

-- ────────────────────────────────────────────────────────────
-- 3c. appearance_check_detail (§4)
-- ────────────────────────────────────────────────────────────
CREATE TABLE appearance_check_detail (
    appearance_check_detail_id BIGSERIAL  PRIMARY KEY,
    appearance_check_id        BIGINT     NOT NULL REFERENCES appearance_check(appearance_check_id) ON DELETE CASCADE,
    checklist_item_id          INTEGER    NOT NULL REFERENCES appearance_checklist_item(checklist_item_id),
    passed                     BOOLEAN    NOT NULL,
    notes                      TEXT,
    tenant_id                  BIGINT     NOT NULL REFERENCES tenant(tenant_id),
    created_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_check_detail_item
        UNIQUE (appearance_check_id, checklist_item_id)
);

COMMENT ON TABLE appearance_check_detail IS 'Line-item results within an appearance check (ADR-0036 §4)';

-- ────────────────────────────────────────────────────────────
-- 3d. official_travel_origin (§5)
-- ────────────────────────────────────────────────────────────
CREATE TABLE official_travel_origin (
    travel_origin_id        BIGSERIAL      PRIMARY KEY,
    official_id             BIGINT         NOT NULL REFERENCES official(official_id),
    address_id              BIGINT         NOT NULL REFERENCES address(address_id),
    label                   VARCHAR(50)    NOT NULL,
    max_travel_distance_miles NUMERIC(6,1),
    is_default              BOOLEAN        NOT NULL DEFAULT false,
    applies_days            SMALLINT[],
    applies_after_time      TIME,
    applies_before_time     TIME,
    display_order           SMALLINT       NOT NULL DEFAULT 0,
    tenant_id               BIGINT         NOT NULL REFERENCES tenant(tenant_id),
    created_at              TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ    NOT NULL DEFAULT now(),

    -- Non-default origins must have at least one scheduling qualifier
    CONSTRAINT chk_travel_origin_qualifier CHECK (
        is_default = true
        OR applies_days IS NOT NULL
        OR applies_after_time IS NOT NULL
        OR applies_before_time IS NOT NULL
    )
);

-- Exactly one default per official
CREATE UNIQUE INDEX uq_travel_origin_default
    ON official_travel_origin (official_id)
    WHERE is_default = true;

CREATE INDEX idx_travel_origin_official
    ON official_travel_origin (official_id);

COMMENT ON TABLE  official_travel_origin IS 'Multi-address travel origins with day/time scheduling context (ADR-0036 §5)';
COMMENT ON COLUMN official_travel_origin.applies_days IS 'ISO day-of-week numbers (1=Mon…7=Sun); NULL = all days';
COMMENT ON COLUMN official_travel_origin.is_default IS 'Fallback origin when no day/time context matches; exactly one per official';

-- ────────────────────────────────────────────────────────────
-- 3e. official_venue_preference (§6)
-- ────────────────────────────────────────────────────────────
CREATE TABLE official_venue_preference (
    official_venue_pref_id BIGSERIAL    PRIMARY KEY,
    official_id            BIGINT       NOT NULL REFERENCES official(official_id),
    venue_id               BIGINT       NOT NULL REFERENCES venue(venue_id),
    preference_type        VARCHAR(20)  NOT NULL,
    reason                 TEXT,
    tenant_id              BIGINT       NOT NULL REFERENCES tenant(tenant_id),
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT uq_official_venue_pref UNIQUE (official_id, venue_id),
    CONSTRAINT chk_venue_pref_type CHECK (
        preference_type IN ('preferred', 'restricted')
    )
);

COMMENT ON TABLE official_venue_preference IS 'Per-official venue preference or restriction (ADR-0036 §6)';

-- ────────────────────────────────────────────────────────────
-- 3f. official_team_preference (§6)
-- ────────────────────────────────────────────────────────────
CREATE TABLE official_team_preference (
    official_team_pref_id BIGSERIAL    PRIMARY KEY,
    official_id           BIGINT       NOT NULL REFERENCES official(official_id),
    team_id               BIGINT       NOT NULL REFERENCES team(team_id),
    preference_type       VARCHAR(20)  NOT NULL,
    reason                TEXT,
    tenant_id             BIGINT       NOT NULL REFERENCES tenant(tenant_id),
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT uq_official_team_pref UNIQUE (official_id, team_id),
    CONSTRAINT chk_team_pref_type CHECK (
        preference_type IN ('preferred', 'restricted')
    )
);

COMMENT ON TABLE official_team_preference IS 'Per-official team preference or restriction (ADR-0036 §6)';


-- ============================================================
-- 4. ROW-LEVEL SECURITY
-- ============================================================
-- Standard pattern: ENABLE + FORCE + tenant_isolation policy
-- with platform-admin bypass.

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN
        SELECT unnest(ARRAY[
            'certification_type',
            'official_certification',
            'appearance_checklist_item',
            'appearance_check',
            'appearance_check_detail',
            'pay_classification',
            'official_travel_origin',
            'official_venue_preference',
            'official_team_preference'
        ])
    LOOP
        EXECUTE format('ALTER TABLE app.%I ENABLE ROW LEVEL SECURITY', tbl);
        EXECUTE format('ALTER TABLE app.%I FORCE  ROW LEVEL SECURITY', tbl);
        EXECUTE format(
            'CREATE POLICY %I ON app.%I FOR ALL
                USING  (current_setting(''app.is_platform_admin'', true) = ''true''
                        OR tenant_id = current_setting(''app.tenant_id'', true)::BIGINT)
                WITH CHECK (current_setting(''app.is_platform_admin'', true) = ''true''
                            OR tenant_id = current_setting(''app.tenant_id'', true)::BIGINT)',
            tbl || '_tenant_isolation',
            tbl
        );
        RAISE NOTICE 'RLS enabled on app.%', tbl;
    END LOOP;
END;
$$;


-- ============================================================
-- 5. UPDATED_AT TRIGGERS
-- ============================================================
-- Reuses the existing app.set_updated_at() function from V033.

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN
        SELECT unnest(ARRAY[
            'certification_type',
            'official_certification',
            'appearance_checklist_item',
            'appearance_check',
            'appearance_check_detail',
            'pay_classification',
            'official_travel_origin',
            'official_venue_preference',
            'official_team_preference'
        ])
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


-- ============================================================
-- 6. SEED DEFAULT PAY CLASSIFICATION
-- ============================================================
-- Insert a "Standard" classification (rate_modifier = 1.0) for
-- each existing tenant so officials can be assigned immediately.

INSERT INTO pay_classification (classification_name, rate_modifier, tenant_id)
SELECT 'Standard', 1.0000, tenant_id
  FROM tenant;

COMMENT ON TABLE pay_classification IS 'Pay rate multiplier tiers for officials (ADR-0036 §8). Every tenant gets a default Standard (1.0) tier.';
