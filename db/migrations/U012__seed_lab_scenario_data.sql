-- U012__seed_lab_scenario_data.sql
-- Description: Undo V012 seed data. Deletes in reverse FK order.

-- 15. Contest schedule
DELETE FROM contest_schedule WHERE contest_schedule_id IN (1, 2, 3, 4);

-- 14. Contest rates
DELETE FROM contest_rates
WHERE officials_association_id = 1 AND tenant_id = 2 AND sport_id = 1
  AND contest_level_id IN (1, 2);

-- 13. Venue subs & venues
DELETE FROM venue_sub WHERE sub_venue_id IN (1, 2, 3, 4);
DELETE FROM venue WHERE venue_id = 1;

-- 12. Teams
DELETE FROM team WHERE team_id IN (1, 2, 3, 4, 5, 6, 7, 8);

-- 11. Contest structure
DELETE FROM contest_league WHERE contest_league_id IN (1, 2, 3, 4);
DELETE FROM contest_level WHERE contest_level_id IN (1, 2);
DELETE FROM contest_season WHERE contest_season_id IN (1, 2);

-- 10. Tenant config / mappings
DELETE FROM tenant_pay_rate_map WHERE tenant_id IN (1, 2);
DELETE FROM tenant_person_map WHERE tenant_id IN (1, 2);
DELETE FROM tenant_sport_map WHERE tenant_id IN (1, 2);
DELETE FROM tenant_license WHERE tenant_id IN (1, 2);
DELETE FROM tenant_config WHERE tenant_id IN (1, 2);

-- 9. Officials ↔ tenant mapping
DELETE FROM officials_tenant_map WHERE officials_association_id = 1 AND tenant_id = 2;

-- 8. Official slots
DELETE FROM official_slots WHERE official_association_id = 1;

-- 7. Officials & config
DELETE FROM official WHERE official_id IN (1, 2, 3, 4);
DELETE FROM official_config WHERE official_config_id IN (1, 2, 3, 4);

-- 6. Officials association
DELETE FROM officials_association WHERE officials_association_id = 1;

-- 5. Person roles
DELETE FROM person_roles WHERE person_id IN (1, 2, 3, 4, 5, 6);

-- 4. Persons
DELETE FROM person WHERE person_id IN (1, 2, 3, 4, 5, 6);

-- 3. Addresses
DELETE FROM address WHERE address_id IN (1, 2, 3);

-- 2. Tenants
DELETE FROM tenant WHERE tenant_id IN (1, 2);

-- 1. Reference data (leave sports/contest_types — they're reusable)
-- If you want a truly clean slate, uncomment:
-- DELETE FROM contest_type WHERE contest_type_id IN (1, 2, 3);
-- DELETE FROM sport WHERE sport_id IN (1, 2, 3);
