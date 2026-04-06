-- ============================================================
-- Seed: 350-umpire association, annual plan, no discount
-- ============================================================
-- Scenario: Metro Umpires Association (ID=1) subscribes with
--   350 active officials, annual billing, no discount code.
--
-- Tier 9 (301–350): $0.85/official/month
-- Annual plan: 15% discount
--
-- Math:
--   Monthly base:     350 × $0.85  = $297.50
--   Plan discount:    $297.50 × 15% = $44.63 (ROUND(297.50 * 0.15, 2))
--   Effective monthly: $297.50 − $44.63 = $252.87
--   Annual total:     $252.87 × 12 = $3,034.44
--
-- Run:
--   psql -d contest_lab -U contestgrid_lab_id -f db/seeds/billing-scenario-350-annual.sql
-- ============================================================

SET search_path TO app, public;

BEGIN;

-- ────────────────────────────────────────────────
-- 1. Create 350 officials with active memberships
-- ────────────────────────────────────────────────

-- We already have persons 1-6 and officials 1-4 from V012.
-- Generate persons 7-352 (346 more) and officials 5-350.

-- Helper: bulk-create persons (we need 346 more: IDs 7 through 352)
-- person table requires: tenant_id, person_type_id, email_address, first_name, last_name
INSERT INTO person (person_id, tenant_id, person_type_id, email_address, first_name, last_name)
SELECT
    s.id,
    1,                                                   -- tenant 1 (MUA)
    3,                                                   -- person_type 3 (Official)
    'umpire' || s.id || '@test.contestgrid.local',       -- unique email
    'Umpire',
    'TestOff-' || LPAD(s.id::text, 3, '0')
FROM generate_series(7, 352) AS s(id)
ON CONFLICT (person_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('person', 'person_id'),
  GREATEST((SELECT COALESCE(MAX(person_id), 1) FROM person), 352), true);

-- Create official_config for new officials (IDs 5-350)
INSERT INTO official_config (official_config_id, uniform_number, association_joined_date, contest_schedule_joined_ts)
SELECT
    s.id,
    LPAD(s.id::text, 3, '0'),
    '2025-01-01',
    '2025-01-01 00:00:00+00'
FROM generate_series(5, 350) AS s(id)
ON CONFLICT (official_config_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('official_config', 'official_config_id'),
  GREATEST((SELECT COALESCE(MAX(official_config_id), 1) FROM official_config), 350), true);

-- Create officials (IDs 5-350, linked to persons 9-352 offset, but let's keep it simple: official N → person N+2)
-- Officials 1-4 already exist (persons 1-4). New officials 5-350 → persons 7-352.
INSERT INTO official (official_id, person_id, official_config_id)
SELECT
    s.id,
    s.id + 2,     -- person_id offset (officials 5→person 7, 6→8, ..., 350→352)
    s.id           -- official_config 1:1
FROM generate_series(5, 350) AS s(id)
ON CONFLICT (official_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('official', 'official_id'),
  GREATEST((SELECT COALESCE(MAX(official_id), 1) FROM official), 350), true);

-- Create active memberships for ALL 350 officials → association 1
INSERT INTO official_association_membership
    (official_id, officials_association_id, membership_status_id, joined_at)
SELECT
    s.id,
    1,          -- Metro Umpires Association
    1,          -- Active
    '2025-01-01'
FROM generate_series(1, 350) AS s(id)
ON CONFLICT (official_id, officials_association_id) DO NOTHING;

-- ────────────────────────────────────────────────
-- 2. Create the subscription
-- ────────────────────────────────────────────────

INSERT INTO association_subscription (
    association_subscription_id,
    officials_association_id,
    subscription_plan_id,       -- 2 = Annual
    subscription_tier_id,       -- 9 = Tier 9 (301-350, $0.85)
    subscription_status_id,     -- 1 = Active
    active_official_count,
    bill_amount,                -- 350 × 0.85
    plan_discount_amount,       -- 297.50 × 0.15
    discount_code_amount,       -- no discount code
    effective_bill_amount,      -- 297.50 − 44.63
    current_period_start,
    current_period_end
) VALUES (
    1,
    1,           -- Metro Umpires Association
    2,           -- Annual
    9,           -- Tier 9
    1,           -- Active
    350,
    297.50,      -- 350 × $0.85
    44.63,       -- ROUND(297.50 × 0.15, 2)
    0.00,        -- no discount code
    252.87,      -- 297.50 − 44.63
    '2026-03-09',
    '2027-03-09'
) ON CONFLICT (association_subscription_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('association_subscription', 'association_subscription_id'),
  GREATEST((SELECT COALESCE(MAX(association_subscription_id), 1) FROM association_subscription), 1), true);

-- ────────────────────────────────────────────────
-- 3. Create the invoice
-- ────────────────────────────────────────────────

INSERT INTO invoice (
    invoice_id,
    invoice_number,
    association_subscription_id,
    officials_association_id,
    invoice_status_id,           -- 2 = Sent
    period_start,
    period_end,
    subtotal,                    -- 297.50 × 12
    discount_total,              -- 44.63 × 12
    tax_total,
    total,
    amount_paid,
    amount_due,
    currency,
    due_date,
    sent_at
) VALUES (
    1,
    'INV-2026-000001',
    1,               -- association_subscription
    1,               -- Metro Umpires
    2,               -- Sent
    '2026-03-09',
    '2027-03-09',
    3570.00,         -- 297.50 × 12
    535.56,          -- 44.63 × 12
    0.00,
    3034.44,         -- 3570.00 − 535.56
    0.00,
    3034.44,
    'USD',
    '2026-04-08',    -- 30 days from period start
    '2026-03-09 12:00:00+00'
) ON CONFLICT (invoice_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('invoice', 'invoice_id'),
  GREATEST((SELECT COALESCE(MAX(invoice_id), 1) FROM invoice), 1), true);

-- ────────────────────────────────────────────────
-- 4. Invoice line items
-- ────────────────────────────────────────────────

INSERT INTO invoice_line_item (line_item_id, invoice_id, description, quantity, unit_price, line_total, sort_order) VALUES
    (1, 1, 'Officials subscription – Tier 9 (350 officials × $0.85/mo × 12 months)', 1, 3570.00, 3570.00, 1),
    (2, 1, 'Annual plan discount (15%)',                                               1, -535.56, -535.56, 2)
ON CONFLICT (line_item_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('invoice_line_item', 'line_item_id'),
  GREATEST((SELECT COALESCE(MAX(line_item_id), 1) FROM invoice_line_item), 2), true);

-- ────────────────────────────────────────────────
-- 5. Default billing notification config
-- ────────────────────────────────────────────────

INSERT INTO billing_notification_config
    (officials_association_id, notification_type_id, enabled, days_before_due)
VALUES
    (1, 1, true, 30),   -- Payment Due Reminder, 30 days out
    (1, 1, true, 14),   -- Payment Due Reminder, 14 days out
    (1, 1, true,  7),   -- Payment Due Reminder, 7 days out
    (1, 1, true,  3),   -- Payment Due Reminder, 3 days out
    (1, 1, true,  1),   -- Payment Due Reminder, 1 day out
    (1, 2, true, NULL),  -- Payment Past Due (no days_before — triggered on overdue)
    (1, 3, true, NULL),  -- Payment Received
    (1, 4, true, NULL),  -- Subscription Renewed
    (1, 5, true, NULL)   -- Subscription Cancelled
ON CONFLICT (officials_association_id, notification_type_id, days_before_due) DO NOTHING;

COMMIT;

-- ────────────────────────────────────────────────
-- Verification queries
-- ────────────────────────────────────────────────

\echo '── Active memberships for association 1 ──'
SELECT COUNT(*) AS active_officials
FROM app.official_association_membership
WHERE officials_association_id = 1 AND membership_status_id = 1;

\echo '── Subscription ──'
SELECT association_subscription_id, subscription_plan_id, subscription_tier_id,
       active_official_count, bill_amount, plan_discount_amount,
       effective_bill_amount, current_period_start, current_period_end
FROM app.association_subscription WHERE association_subscription_id = 1;

\echo '── Invoice ──'
SELECT invoice_number, subtotal, discount_total, total, amount_due, due_date
FROM app.invoice WHERE invoice_id = 1;

\echo '── Line items ──'
SELECT description, quantity, unit_price, line_total
FROM app.invoice_line_item WHERE invoice_id = 1 ORDER BY sort_order;
