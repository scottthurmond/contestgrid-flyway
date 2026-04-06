-- ============================================================================
-- V024: Force Row-Level Security on all RLS-enabled tables
--
-- The contestgrid_lab_id user owns these tables and bypasses RLS by default.
-- FORCE ROW LEVEL SECURITY ensures the owner must also satisfy policies.
-- Without this, RLS policies have no effect for our application connection.
-- ============================================================================

ALTER TABLE app.address                         FORCE ROW LEVEL SECURITY;
ALTER TABLE app.bookings                        FORCE ROW LEVEL SECURITY;
ALTER TABLE app.contest_league                  FORCE ROW LEVEL SECURITY;
ALTER TABLE app.contest_level                   FORCE ROW LEVEL SECURITY;
ALTER TABLE app.contest_rates                   FORCE ROW LEVEL SECURITY;
ALTER TABLE app.contest_schedule                FORCE ROW LEVEL SECURITY;
ALTER TABLE app.contest_season                  FORCE ROW LEVEL SECURITY;
ALTER TABLE app.official                        FORCE ROW LEVEL SECURITY;
ALTER TABLE app.official_association_membership  FORCE ROW LEVEL SECURITY;
ALTER TABLE app.official_config                 FORCE ROW LEVEL SECURITY;
ALTER TABLE app.official_contest_assignment     FORCE ROW LEVEL SECURITY;
ALTER TABLE app.officials_association           FORCE ROW LEVEL SECURITY;
ALTER TABLE app.payment                         FORCE ROW LEVEL SECURITY;
ALTER TABLE app.person                          FORCE ROW LEVEL SECURITY;
ALTER TABLE app.phone                           FORCE ROW LEVEL SECURITY;
ALTER TABLE app.team                            FORCE ROW LEVEL SECURITY;
ALTER TABLE app.tenant_config                   FORCE ROW LEVEL SECURITY;
ALTER TABLE app.tenant_person_map               FORCE ROW LEVEL SECURITY;
ALTER TABLE app.venue                           FORCE ROW LEVEL SECURITY;
ALTER TABLE app.venue_sub                       FORCE ROW LEVEL SECURITY;
