-- V012__seed_lab_scenario_data.sql
-- Description: Seed a realistic scenario for local development and proc API testing.
-- Scenario: "Metro Umpires Association" manages baseball officials for
--           "Gwinnett Youth Baseball" league. Spring 2026 season with 4 teams,
--           2 levels, 4 officials, contests at "Bear Creek Park".
-- Idempotent: Uses ON CONFLICT / explicit IDs with sequence resets.
-- Depends on: V001 (reference data), V002-V010 (schema)
-- ============================================================================

-- ============================================================================
-- 1. SPORTS & CONTEST TYPES (reference data, shared across tenants)
-- ============================================================================
INSERT INTO sport (sport_id, sport_name) VALUES
  (1, 'Baseball'),
  (2, 'Softball'),
  (3, 'Basketball')
ON CONFLICT (sport_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('sport', 'sport_id'),
  GREATEST((SELECT COALESCE(MAX(sport_id), 1) FROM sport), 3), true);

INSERT INTO contest_type (contest_type_id, contest_type_name) VALUES
  (1, 'Regular Season'),
  (2, 'Playoff'),
  (3, 'Tournament')
ON CONFLICT (contest_type_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('contest_type', 'contest_type_id'),
  GREATEST((SELECT COALESCE(MAX(contest_type_id), 1) FROM contest_type), 3), true);

-- ============================================================================
-- 2. TENANTS
-- ============================================================================
-- Tenant 1: Officials Association (the assigner org)
-- Tenant 2: Sports League (the customer org that books officials)
INSERT INTO tenant (tenant_id, tenant_name, tenant_abbreviation, tenant_type_id, tenant_sub_domain) VALUES
  (1, 'Metro Umpires Association', 'MUA', 1, 'metro-umpires'),
  (2, 'Gwinnett Youth Baseball',  'GYB', 2, 'gwinnett-yb')
ON CONFLICT (tenant_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('tenant', 'tenant_id'),
  GREATEST((SELECT COALESCE(MAX(tenant_id), 1) FROM tenant), 2), true);

-- ============================================================================
-- 3. ADDRESSES
-- ============================================================================
INSERT INTO address (address_id, tenant_id, address_1, city, state, postal_code, country_code) VALUES
  (1, 1, '100 Umpire Drive',     'Lawrenceville', 'GA', '30046', 'US'),
  (2, 2, '200 Baseball Way',     'Dacula',        'GA', '30019', 'US'),
  (3, 2, '400 Bear Creek Road',  'Dacula',        'GA', '30019', 'US')
ON CONFLICT (address_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('address', 'address_id'),
  GREATEST((SELECT COALESCE(MAX(address_id), 1) FROM address), 3), true);

-- ============================================================================
-- 4. PERSONS (officials + league contact)
-- ============================================================================
-- person_type: 1=Payer, 2=Contact, 3=Official
INSERT INTO person (person_id, tenant_id, person_type_id, email_address, first_name, last_name) VALUES
  -- Four officials (belong to association tenant 1)
  (1, 1, 3, 'john.smith@metro-umps.test',   'John',    'Smith'),
  (2, 1, 3, 'mike.jones@metro-umps.test',   'Mike',    'Jones'),
  (3, 1, 3, 'sarah.davis@metro-umps.test',  'Sarah',   'Davis'),
  (4, 1, 3, 'chris.wilson@metro-umps.test', 'Chris',   'Wilson'),
  -- League admin contact (belongs to league tenant 2)
  (5, 2, 2, 'admin@gwinnett-yb.test',       'Pat',     'Johnson'),
  -- Payer contact (belongs to league tenant 2)
  (6, 2, 1, 'treasurer@gwinnett-yb.test',   'Robin',   'Taylor')
ON CONFLICT (person_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('person', 'person_id'),
  GREATEST((SELECT COALESCE(MAX(person_id), 1) FROM person), 6), true);

-- ============================================================================
-- 5. PERSON ROLES
-- ============================================================================
-- roles: 1=Primary Assigner Admin, 2=Secondary Assigner Admin,
--        3=League Director, 4=Coach, 5=Official
INSERT INTO person_roles (person_id, role_id) VALUES
  (1, 5), (2, 5), (3, 5), (4, 5),   -- all 4 are officials
  (1, 1),                             -- John is also primary assigner admin
  (5, 3),                             -- Pat is league director
  (6, 3)                              -- Robin is also league director
ON CONFLICT (person_id, role_id) DO NOTHING;

-- ============================================================================
-- 6. OFFICIALS ASSOCIATION
-- ============================================================================
INSERT INTO officials_association (officials_association_id, officials_association_name, officials_association_abbreviation, address_id) VALUES
  (1, 'Metro Umpires Association', 'MUA', 1)
ON CONFLICT (officials_association_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('officials_association', 'officials_association_id'),
  GREATEST((SELECT COALESCE(MAX(officials_association_id), 1) FROM officials_association), 1), true);

-- ============================================================================
-- 7. OFFICIAL CONFIG + OFFICIALS
-- ============================================================================
INSERT INTO official_config (official_config_id, uniform_number, association_joined_date, contest_schedule_joined_ts) VALUES
  (1, '12', '2020-03-15', '2020-03-15 00:00:00+00'),
  (2, '24', '2021-01-10', '2021-01-10 00:00:00+00'),
  (3, '36', '2022-06-01', '2022-06-01 00:00:00+00'),
  (4, '48', '2023-02-20', '2023-02-20 00:00:00+00')
ON CONFLICT (official_config_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('official_config', 'official_config_id'),
  GREATEST((SELECT COALESCE(MAX(official_config_id), 1) FROM official_config), 4), true);

INSERT INTO official (official_id, person_id, official_config_id) VALUES
  (1, 1, 1),  -- John
  (2, 2, 2),  -- Mike
  (3, 3, 3),  -- Sarah
  (4, 4, 4)   -- Chris
ON CONFLICT (official_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('official', 'official_id'),
  GREATEST((SELECT COALESCE(MAX(official_id), 1) FROM official), 4), true);

-- ============================================================================
-- 8. OFFICIAL SLOTS (role names per association/sport)
-- ============================================================================
INSERT INTO official_slots (official_association_id, slot_name, sport_id) VALUES
  (1, 'Home Plate Umpire', 1),
  (1, 'Base Umpire',       2)   -- softball uses same association
ON CONFLICT (official_association_id, sport_id) DO NOTHING;

-- ============================================================================
-- 9. OFFICIALS ↔ TENANT MAPPING
-- ============================================================================
INSERT INTO officials_tenant_map (officials_association_id, tenant_id, sport_id) VALUES
  (1, 2, 1)   -- MUA works with GYB for baseball
ON CONFLICT (officials_association_id, tenant_id, sport_id) DO NOTHING;

-- ============================================================================
-- 10. TENANT CONFIGURATION
-- ============================================================================
INSERT INTO tenant_config (tenant_id, contest_status_id, contest_type_id) VALUES
  (1, 1, 1),  -- MUA: default Normal status, Regular Season type
  (2, 1, 1)   -- GYB: default Normal status, Regular Season type
ON CONFLICT (tenant_id) DO NOTHING;

INSERT INTO tenant_license (tenant_id, number_of_licenses, price) VALUES
  (1, 50, 0.00),     -- association: free tier
  (2, 100, 29.99)    -- league: paid tier
ON CONFLICT (tenant_id) DO NOTHING;

INSERT INTO tenant_sport_map (tenant_id, sport_id) VALUES
  (1, 1),  -- MUA offers baseball
  (1, 2),  -- MUA offers softball
  (2, 1)   -- GYB plays baseball
ON CONFLICT (tenant_id, sport_id) DO NOTHING;

INSERT INTO tenant_person_map (tenant_id, person_id) VALUES
  (1, 1), (1, 2), (1, 3), (1, 4),  -- officials belong to association
  (2, 5), (2, 6)                     -- contacts belong to league
ON CONFLICT (tenant_id, person_id) DO NOTHING;

INSERT INTO tenant_pay_rate_map (tenant_id, rate_id) VALUES
  (2, 1)   -- GYB uses rate plan 1
ON CONFLICT (tenant_id) DO NOTHING;

-- ============================================================================
-- 11. CONTEST STRUCTURE (season → level → league)
-- ============================================================================
INSERT INTO contest_season (contest_season_id, tenant_id, contest_season_name, contest_season_start_date, contest_season_end_date) VALUES
  (1, 2, 'Spring 2026', '2026-03-01', '2026-06-30'),
  (2, 2, 'Fall 2026',   '2026-08-01', '2026-11-30')
ON CONFLICT (contest_season_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('contest_season', 'contest_season_id'),
  GREATEST((SELECT COALESCE(MAX(contest_season_id), 1) FROM contest_season), 2), true);

INSERT INTO contest_level (contest_level_id, tenant_id, officials_association_id, contest_level_name) VALUES
  (1, 2, 1, 'Rec'),
  (2, 2, 1, 'Travel')
ON CONFLICT (contest_level_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('contest_level', 'contest_level_id'),
  GREATEST((SELECT COALESCE(MAX(contest_level_id), 1) FROM contest_level), 2), true);

INSERT INTO contest_league (contest_league_id, tenant_id, officials_association_id, contest_level_id, contest_league_name, default_time_limit) VALUES
  (1, 2, 1, 1, 'Rec 10U Baseball',    90),
  (2, 2, 1, 1, 'Rec 12U Baseball',    90),
  (3, 2, 1, 2, 'Travel 10U Baseball',  0),
  (4, 2, 1, 2, 'Travel 12U Baseball',  0)
ON CONFLICT (contest_league_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('contest_league', 'contest_league_id'),
  GREATEST((SELECT COALESCE(MAX(contest_league_id), 1) FROM contest_league), 4), true);

-- ============================================================================
-- 12. TEAMS (2 per league = 8 total)
-- ============================================================================
INSERT INTO team (team_id, tenant_id, contest_league_id, contest_level_id, team_name) VALUES
  (1,  2, 1, 1, 'Rec 10U Eagles'),
  (2,  2, 1, 1, 'Rec 10U Hawks'),
  (3,  2, 2, 1, 'Rec 12U Tigers'),
  (4,  2, 2, 1, 'Rec 12U Bears'),
  (5,  2, 3, 2, 'Travel 10U Storm'),
  (6,  2, 3, 2, 'Travel 10U Lightning'),
  (7,  2, 4, 2, 'Travel 12U Vipers'),
  (8,  2, 4, 2, 'Travel 12U Cobras')
ON CONFLICT (team_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('team', 'team_id'),
  GREATEST((SELECT COALESCE(MAX(team_id), 1) FROM team), 8), true);

-- ============================================================================
-- 13. VENUES & SUB-VENUES
-- ============================================================================
INSERT INTO venue (venue_id, tenant_id, venue_address_id, officials_association_id, venue_name) VALUES
  (1, 2, 3, 1, 'Bear Creek Park')
ON CONFLICT (venue_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('venue', 'venue_id'),
  GREATEST((SELECT COALESCE(MAX(venue_id), 1) FROM venue), 1), true);

INSERT INTO venue_sub (sub_venue_id, venue_id, sub_venue_name, sub_venue_desc) VALUES
  (1, 1, 'Field 1', 'Main diamond – full size'),
  (2, 1, 'Field 2', 'Southeast diamond – 60-foot bases'),
  (3, 1, 'Field 3', 'Northwest diamond – 50-foot bases'),
  (4, 1, 'Field 4', 'Practice field – no mound')
ON CONFLICT (sub_venue_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('venue_sub', 'sub_venue_id'),
  GREATEST((SELECT COALESCE(MAX(sub_venue_id), 1) FROM venue_sub), 4), true);

-- ============================================================================
-- 14. CONTEST RATES (billing)
-- ============================================================================
-- Rec games: $100 bill, $50/umpire, 1 official
-- Travel games: $150 bill, $65/umpire, 2 officials
INSERT INTO contest_rates (officials_association_id, tenant_id, sport_id, contest_level_id, contest_league_id, contest_num_officials_contracted, contest_bill_amount, contest_umpire_rate) VALUES
  (1, 2, 1, 1, NULL, 1, 100.00, 50.00),
  (1, 2, 1, 2, NULL, 2, 150.00, 65.00)
ON CONFLICT (officials_association_id, tenant_id, sport_id, contest_level_id) DO NOTHING;

-- ============================================================================
-- 15. CONTEST SCHEDULE (sample games for proc API testing)
-- ============================================================================
-- 4 games: 2 Rec (1 umpire each), 2 Travel (2 umpires each) = 6 official slots
INSERT INTO contest_schedule (contest_schedule_id, tenant_id, officials_association_id, sport_id, contest_status_id, contest_type_id, contest_level_id, contest_league_id, venue_id, sub_venue_id, contest_start_date, contest_start_time, home_team_id, visiting_team_id, number_officials_required) VALUES
  (1, 2, 1, 1, 1, 1, 1, 1, 1, 1, '2026-04-05', '09:00', 1, 2, 1),  -- Rec 10U: Eagles vs Hawks, Field 1
  (2, 2, 1, 1, 1, 1, 1, 2, 1, 2, '2026-04-05', '11:00', 3, 4, 1),  -- Rec 12U: Tigers vs Bears, Field 2
  (3, 2, 1, 1, 1, 1, 2, 3, 1, 1, '2026-04-05', '14:00', 5, 6, 2),  -- Travel 10U: Storm vs Lightning, Field 1
  (4, 2, 1, 1, 1, 1, 2, 4, 1, 3, '2026-04-05', '16:00', 7, 8, 2)   -- Travel 12U: Vipers vs Cobras, Field 3
ON CONFLICT (contest_schedule_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('contest_schedule', 'contest_schedule_id'),
  GREATEST((SELECT COALESCE(MAX(contest_schedule_id), 1) FROM contest_schedule), 4), true);

-- ============================================================================
-- Done!  Verify with:
--   SELECT count(*) AS tenants FROM tenant;             -- expect ≥ 2
--   SELECT count(*) AS persons FROM person;             -- expect ≥ 6
--   SELECT count(*) AS officials FROM official;         -- expect ≥ 4
--   SELECT count(*) AS teams FROM team;                 -- expect ≥ 8
--   SELECT count(*) AS contests FROM contest_schedule;  -- expect ≥ 4
-- ============================================================================
