-- V029: Add tenant_id + RLS to 14 enum/lookup tables
-- Strategy: assign existing rows to tenant 1, duplicate for all other tenants,
-- update child table FKs to point to the correct tenant-specific copy.

-- Enable platform admin bypass for this migration
SELECT set_config('app.is_platform_admin', 'true', true);

------------------------------------------------------------
-- PART A: Add tenant_id columns and assign existing rows to tenant 1
------------------------------------------------------------

ALTER TABLE app.assignment_status ADD COLUMN tenant_id BIGINT;
UPDATE app.assignment_status SET tenant_id = 1;

ALTER TABLE app.contest_status ADD COLUMN tenant_id BIGINT;
UPDATE app.contest_status SET tenant_id = 1;

ALTER TABLE app.contest_type ADD COLUMN tenant_id BIGINT;
UPDATE app.contest_type SET tenant_id = 1;

ALTER TABLE app.invoice_payment_type ADD COLUMN tenant_id BIGINT;
UPDATE app.invoice_payment_type SET tenant_id = 1;

ALTER TABLE app.invoice_status ADD COLUMN tenant_id BIGINT;
UPDATE app.invoice_status SET tenant_id = 1;

ALTER TABLE app.membership_status ADD COLUMN tenant_id BIGINT;
UPDATE app.membership_status SET tenant_id = 1;

ALTER TABLE app.notification_status ADD COLUMN tenant_id BIGINT;
UPDATE app.notification_status SET tenant_id = 1;

ALTER TABLE app.notification_type ADD COLUMN tenant_id BIGINT;
UPDATE app.notification_type SET tenant_id = 1;

ALTER TABLE app.payment_status ADD COLUMN tenant_id BIGINT;
UPDATE app.payment_status SET tenant_id = 1;

ALTER TABLE app.payment_type ADD COLUMN tenant_id BIGINT;
UPDATE app.payment_type SET tenant_id = 1;

ALTER TABLE app.person_type ADD COLUMN tenant_id BIGINT;
UPDATE app.person_type SET tenant_id = 1;

ALTER TABLE app.roles ADD COLUMN tenant_id BIGINT;
UPDATE app.roles SET tenant_id = 1;

ALTER TABLE app.sport ADD COLUMN tenant_id BIGINT;
UPDATE app.sport SET tenant_id = 1;

ALTER TABLE app.tenant_type ADD COLUMN tenant_id BIGINT;
UPDATE app.tenant_type SET tenant_id = 1;

------------------------------------------------------------
-- PART B: Reset sequences to avoid PK conflicts during duplication
------------------------------------------------------------

SELECT setval(pg_get_serial_sequence('app.assignment_status', 'assignment_status_id'),
              (SELECT MAX(assignment_status_id) FROM app.assignment_status));
SELECT setval(pg_get_serial_sequence('app.contest_status', 'contest_status_id'),
              (SELECT MAX(contest_status_id) FROM app.contest_status));
SELECT setval(pg_get_serial_sequence('app.contest_type', 'contest_type_id'),
              (SELECT MAX(contest_type_id) FROM app.contest_type));
SELECT setval(pg_get_serial_sequence('app.invoice_payment_type', 'invoice_payment_type_id'),
              (SELECT MAX(invoice_payment_type_id) FROM app.invoice_payment_type));
SELECT setval(pg_get_serial_sequence('app.invoice_status', 'invoice_status_id'),
              (SELECT MAX(invoice_status_id) FROM app.invoice_status));
SELECT setval(pg_get_serial_sequence('app.membership_status', 'membership_status_id'),
              (SELECT MAX(membership_status_id) FROM app.membership_status));
SELECT setval(pg_get_serial_sequence('app.notification_status', 'notification_status_id'),
              (SELECT MAX(notification_status_id) FROM app.notification_status));
SELECT setval(pg_get_serial_sequence('app.notification_type', 'notification_type_id'),
              (SELECT MAX(notification_type_id) FROM app.notification_type));
SELECT setval(pg_get_serial_sequence('app.payment_status', 'payment_status_id'),
              (SELECT MAX(payment_status_id) FROM app.payment_status));
SELECT setval(pg_get_serial_sequence('app.payment_type', 'payment_type_id'),
              (SELECT MAX(payment_type_id) FROM app.payment_type));
SELECT setval(pg_get_serial_sequence('app.person_type', 'person_type_id'),
              (SELECT MAX(person_type_id) FROM app.person_type));
SELECT setval(pg_get_serial_sequence('app.roles', 'role_id'),
              (SELECT MAX(role_id) FROM app.roles));
SELECT setval(pg_get_serial_sequence('app.sport', 'sport_id'),
              (SELECT MAX(sport_id) FROM app.sport));
SELECT setval(pg_get_serial_sequence('app.tenant_type', 'tenant_type_id'),
              (SELECT MAX(tenant_type_id) FROM app.tenant_type));

------------------------------------------------------------
-- PART B2: Drop old unique constraints on name, add composite (name, tenant_id)
-- Must happen BEFORE duplication to allow duplicate names across tenants
------------------------------------------------------------

ALTER TABLE app.assignment_status DROP CONSTRAINT IF EXISTS assignment_status_assignment_status_name_key;
ALTER TABLE app.assignment_status ADD CONSTRAINT assignment_status_name_tenant_uq UNIQUE (assignment_status_name, tenant_id);

ALTER TABLE app.contest_status DROP CONSTRAINT IF EXISTS contest_status_contest_status_name_key;
ALTER TABLE app.contest_status ADD CONSTRAINT contest_status_name_tenant_uq UNIQUE (contest_status_name, tenant_id);

ALTER TABLE app.contest_type DROP CONSTRAINT IF EXISTS contest_type_contest_type_name_key;
ALTER TABLE app.contest_type ADD CONSTRAINT contest_type_name_tenant_uq UNIQUE (contest_type_name, tenant_id);

ALTER TABLE app.invoice_payment_type DROP CONSTRAINT IF EXISTS invoice_payment_type_invoice_payment_type_name_key;
ALTER TABLE app.invoice_payment_type ADD CONSTRAINT invoice_payment_type_name_tenant_uq UNIQUE (invoice_payment_type_name, tenant_id);

ALTER TABLE app.invoice_status DROP CONSTRAINT IF EXISTS invoice_status_invoice_status_name_key;
ALTER TABLE app.invoice_status ADD CONSTRAINT invoice_status_name_tenant_uq UNIQUE (invoice_status_name, tenant_id);

ALTER TABLE app.membership_status DROP CONSTRAINT IF EXISTS membership_status_membership_status_name_key;
ALTER TABLE app.membership_status ADD CONSTRAINT membership_status_name_tenant_uq UNIQUE (membership_status_name, tenant_id);

ALTER TABLE app.notification_status DROP CONSTRAINT IF EXISTS notification_status_notification_status_name_key;
ALTER TABLE app.notification_status ADD CONSTRAINT notification_status_name_tenant_uq UNIQUE (notification_status_name, tenant_id);

ALTER TABLE app.notification_type DROP CONSTRAINT IF EXISTS notification_type_notification_type_name_key;
ALTER TABLE app.notification_type ADD CONSTRAINT notification_type_name_tenant_uq UNIQUE (notification_type_name, tenant_id);

ALTER TABLE app.payment_status DROP CONSTRAINT IF EXISTS payment_status_payment_status_name_key;
ALTER TABLE app.payment_status ADD CONSTRAINT payment_status_name_tenant_uq UNIQUE (payment_status_name, tenant_id);

ALTER TABLE app.payment_type DROP CONSTRAINT IF EXISTS payment_type_payment_type_name_key;
ALTER TABLE app.payment_type ADD CONSTRAINT payment_type_name_tenant_uq UNIQUE (payment_type_name, tenant_id);

ALTER TABLE app.person_type DROP CONSTRAINT IF EXISTS person_type_person_type_description_key;
ALTER TABLE app.person_type ADD CONSTRAINT person_type_desc_tenant_uq UNIQUE (person_type_description, tenant_id);

ALTER TABLE app.roles DROP CONSTRAINT IF EXISTS roles_role_description_key;
ALTER TABLE app.roles ADD CONSTRAINT roles_desc_tenant_uq UNIQUE (role_description, tenant_id);

ALTER TABLE app.sport DROP CONSTRAINT IF EXISTS sport_sport_name_key;
ALTER TABLE app.sport ADD CONSTRAINT sport_name_tenant_uq UNIQUE (sport_name, tenant_id);

ALTER TABLE app.tenant_type DROP CONSTRAINT IF EXISTS tenant_type_tenant_type_name_key;
ALTER TABLE app.tenant_type ADD CONSTRAINT tenant_type_name_tenant_uq UNIQUE (tenant_type_name, tenant_id);

------------------------------------------------------------
-- PART C: Duplicate enum rows for all tenants != 1
------------------------------------------------------------

-- assignment_status (cols: assignment_status_name, created_at, updated_at)
INSERT INTO app.assignment_status (assignment_status_name, tenant_id, created_at, updated_at)
SELECT a.assignment_status_name, t.tenant_id, NOW(), NOW()
FROM app.assignment_status a CROSS JOIN app.tenant t
WHERE a.tenant_id = 1 AND t.tenant_id != 1;

-- contest_status (cols: contest_status_name, created_at, updated_at)
INSERT INTO app.contest_status (contest_status_name, tenant_id, created_at, updated_at)
SELECT c.contest_status_name, t.tenant_id, NOW(), NOW()
FROM app.contest_status c CROSS JOIN app.tenant t
WHERE c.tenant_id = 1 AND t.tenant_id != 1;

-- contest_type (cols: contest_type_name, created_at, updated_at)
INSERT INTO app.contest_type (contest_type_name, tenant_id, created_at, updated_at)
SELECT c.contest_type_name, t.tenant_id, NOW(), NOW()
FROM app.contest_type c CROSS JOIN app.tenant t
WHERE c.tenant_id = 1 AND t.tenant_id != 1;

-- invoice_payment_type (cols: invoice_payment_type_name, created_at)
INSERT INTO app.invoice_payment_type (invoice_payment_type_name, tenant_id, created_at)
SELECT i.invoice_payment_type_name, t.tenant_id, NOW()
FROM app.invoice_payment_type i CROSS JOIN app.tenant t
WHERE i.tenant_id = 1 AND t.tenant_id != 1;

-- invoice_status (cols: invoice_status_name, created_at)
INSERT INTO app.invoice_status (invoice_status_name, tenant_id, created_at)
SELECT i.invoice_status_name, t.tenant_id, NOW()
FROM app.invoice_status i CROSS JOIN app.tenant t
WHERE i.tenant_id = 1 AND t.tenant_id != 1;

-- membership_status (cols: membership_status_name, created_at)
INSERT INTO app.membership_status (membership_status_name, tenant_id, created_at)
SELECT m.membership_status_name, t.tenant_id, NOW()
FROM app.membership_status m CROSS JOIN app.tenant t
WHERE m.tenant_id = 1 AND t.tenant_id != 1;

-- notification_status (cols: notification_status_name, created_at)
INSERT INTO app.notification_status (notification_status_name, tenant_id, created_at)
SELECT n.notification_status_name, t.tenant_id, NOW()
FROM app.notification_status n CROSS JOIN app.tenant t
WHERE n.tenant_id = 1 AND t.tenant_id != 1;

-- notification_type (cols: notification_type_name, created_at)
INSERT INTO app.notification_type (notification_type_name, tenant_id, created_at)
SELECT n.notification_type_name, t.tenant_id, NOW()
FROM app.notification_type n CROSS JOIN app.tenant t
WHERE n.tenant_id = 1 AND t.tenant_id != 1;

-- payment_status (cols: payment_status_name, created_at)
INSERT INTO app.payment_status (payment_status_name, tenant_id, created_at)
SELECT p.payment_status_name, t.tenant_id, NOW()
FROM app.payment_status p CROSS JOIN app.tenant t
WHERE p.tenant_id = 1 AND t.tenant_id != 1;

-- payment_type (cols: payment_type_name, created_at)
INSERT INTO app.payment_type (payment_type_name, tenant_id, created_at)
SELECT p.payment_type_name, t.tenant_id, NOW()
FROM app.payment_type p CROSS JOIN app.tenant t
WHERE p.tenant_id = 1 AND t.tenant_id != 1;

-- person_type (cols: person_type_description, created_at, updated_at)
INSERT INTO app.person_type (person_type_description, tenant_id, created_at, updated_at)
SELECT p.person_type_description, t.tenant_id, NOW(), NOW()
FROM app.person_type p CROSS JOIN app.tenant t
WHERE p.tenant_id = 1 AND t.tenant_id != 1;

-- roles (cols: role_description, created_at, updated_at)
INSERT INTO app.roles (role_description, tenant_id, created_at, updated_at)
SELECT r.role_description, t.tenant_id, NOW(), NOW()
FROM app.roles r CROSS JOIN app.tenant t
WHERE r.tenant_id = 1 AND t.tenant_id != 1;

-- sport (cols: sport_name, created_at, updated_at)
INSERT INTO app.sport (sport_name, tenant_id, created_at, updated_at)
SELECT s.sport_name, t.tenant_id, NOW(), NOW()
FROM app.sport s CROSS JOIN app.tenant t
WHERE s.tenant_id = 1 AND t.tenant_id != 1;

-- tenant_type (cols: tenant_type_name, created_at, updated_at)
INSERT INTO app.tenant_type (tenant_type_name, tenant_id, created_at, updated_at)
SELECT tt.tenant_type_name, t.tenant_id, NOW(), NOW()
FROM app.tenant_type tt CROSS JOIN app.tenant t
WHERE tt.tenant_id = 1 AND t.tenant_id != 1;

------------------------------------------------------------
-- PART D: Update child table FKs to point to tenant-specific copies
-- Pattern: UPDATE child SET fk = new_enum.id
--          FROM new_enum JOIN old_enum ON name match
--          WHERE child.fk = old_enum.id AND child.tenant_id = new_enum.tenant_id
------------------------------------------------------------

-- assignment_status → official_contest_assignment.assignment_status_id
UPDATE app.official_contest_assignment oca
  SET assignment_status_id = ns.assignment_status_id
  FROM app.assignment_status ns
  JOIN app.assignment_status os ON os.assignment_status_name = ns.assignment_status_name AND os.tenant_id = 1
  WHERE oca.assignment_status_id = os.assignment_status_id
    AND oca.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- contest_status → contest_schedule.contest_status_id
UPDATE app.contest_schedule cs
  SET contest_status_id = ns.contest_status_id
  FROM app.contest_status ns
  JOIN app.contest_status os ON os.contest_status_name = ns.contest_status_name AND os.tenant_id = 1
  WHERE cs.contest_status_id = os.contest_status_id
    AND cs.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- contest_status → tenant_config.contest_status_id
UPDATE app.tenant_config tc
  SET contest_status_id = ns.contest_status_id
  FROM app.contest_status ns
  JOIN app.contest_status os ON os.contest_status_name = ns.contest_status_name AND os.tenant_id = 1
  WHERE tc.contest_status_id = os.contest_status_id
    AND tc.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- contest_type → contest_schedule.contest_type_id
UPDATE app.contest_schedule cs
  SET contest_type_id = ns.contest_type_id
  FROM app.contest_type ns
  JOIN app.contest_type os ON os.contest_type_name = ns.contest_type_name AND os.tenant_id = 1
  WHERE cs.contest_type_id = os.contest_type_id
    AND cs.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- contest_type → tenant_config.contest_type_id
UPDATE app.tenant_config tc
  SET contest_type_id = ns.contest_type_id
  FROM app.contest_type ns
  JOIN app.contest_type os ON os.contest_type_name = ns.contest_type_name AND os.tenant_id = 1
  WHERE tc.contest_type_id = os.contest_type_id
    AND tc.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- invoice_payment_type → invoice_payment.invoice_payment_type_id
UPDATE app.invoice_payment ip
  SET invoice_payment_type_id = ns.invoice_payment_type_id
  FROM app.invoice_payment_type ns
  JOIN app.invoice_payment_type os ON os.invoice_payment_type_name = ns.invoice_payment_type_name AND os.tenant_id = 1
  WHERE ip.invoice_payment_type_id = os.invoice_payment_type_id
    AND ip.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- invoice_status → invoice.invoice_status_id
UPDATE app.invoice inv
  SET invoice_status_id = ns.invoice_status_id
  FROM app.invoice_status ns
  JOIN app.invoice_status os ON os.invoice_status_name = ns.invoice_status_name AND os.tenant_id = 1
  WHERE inv.invoice_status_id = os.invoice_status_id
    AND inv.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- membership_status → official_association_membership.membership_status_id
UPDATE app.official_association_membership oam
  SET membership_status_id = ns.membership_status_id
  FROM app.membership_status ns
  JOIN app.membership_status os ON os.membership_status_name = ns.membership_status_name AND os.tenant_id = 1
  WHERE oam.membership_status_id = os.membership_status_id
    AND oam.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- notification_status → billing_notification_log.notification_status_id
UPDATE app.billing_notification_log bnl
  SET notification_status_id = ns.notification_status_id
  FROM app.notification_status ns
  JOIN app.notification_status os ON os.notification_status_name = ns.notification_status_name AND os.tenant_id = 1
  WHERE bnl.notification_status_id = os.notification_status_id
    AND bnl.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- notification_type → billing_notification_config.notification_type_id
UPDATE app.billing_notification_config bnc
  SET notification_type_id = ns.notification_type_id
  FROM app.notification_type ns
  JOIN app.notification_type os ON os.notification_type_name = ns.notification_type_name AND os.tenant_id = 1
  WHERE bnc.notification_type_id = os.notification_type_id
    AND bnc.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- notification_type → billing_notification_log.notification_type_id
UPDATE app.billing_notification_log bnl
  SET notification_type_id = ns.notification_type_id
  FROM app.notification_type ns
  JOIN app.notification_type os ON os.notification_type_name = ns.notification_type_name AND os.tenant_id = 1
  WHERE bnl.notification_type_id = os.notification_type_id
    AND bnl.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- payment_status → payment.payment_status_id
UPDATE app.payment p
  SET payment_status_id = ns.payment_status_id
  FROM app.payment_status ns
  JOIN app.payment_status os ON os.payment_status_name = ns.payment_status_name AND os.tenant_id = 1
  WHERE p.payment_status_id = os.payment_status_id
    AND p.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- payment_type → payment.payment_type_id
UPDATE app.payment p
  SET payment_type_id = ns.payment_type_id
  FROM app.payment_type ns
  JOIN app.payment_type os ON os.payment_type_name = ns.payment_type_name AND os.tenant_id = 1
  WHERE p.payment_type_id = os.payment_type_id
    AND p.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- person_type → person.person_type_id
UPDATE app.person pe
  SET person_type_id = ns.person_type_id
  FROM app.person_type ns
  JOIN app.person_type os ON os.person_type_description = ns.person_type_description AND os.tenant_id = 1
  WHERE pe.person_type_id = os.person_type_id
    AND pe.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- roles → person_roles.role_id
UPDATE app.person_roles pr
  SET role_id = ns.role_id
  FROM app.roles ns
  JOIN app.roles os ON os.role_description = ns.role_description AND os.tenant_id = 1
  WHERE pr.role_id = os.role_id
    AND pr.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- sport → contest_rates.sport_id
UPDATE app.contest_rates cr
  SET sport_id = ns.sport_id
  FROM app.sport ns
  JOIN app.sport os ON os.sport_name = ns.sport_name AND os.tenant_id = 1
  WHERE cr.sport_id = os.sport_id
    AND cr.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- sport → contest_schedule.sport_id
UPDATE app.contest_schedule cs
  SET sport_id = ns.sport_id
  FROM app.sport ns
  JOIN app.sport os ON os.sport_name = ns.sport_name AND os.tenant_id = 1
  WHERE cs.sport_id = os.sport_id
    AND cs.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- sport → official_slots.sport_id
UPDATE app.official_slots ofs
  SET sport_id = ns.sport_id
  FROM app.sport ns
  JOIN app.sport os ON os.sport_name = ns.sport_name AND os.tenant_id = 1
  WHERE ofs.sport_id = os.sport_id
    AND ofs.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- sport → officials_tenant_map.sport_id
UPDATE app.officials_tenant_map otm
  SET sport_id = ns.sport_id
  FROM app.sport ns
  JOIN app.sport os ON os.sport_name = ns.sport_name AND os.tenant_id = 1
  WHERE otm.sport_id = os.sport_id
    AND otm.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- sport → tenant_sport_map.sport_id
UPDATE app.tenant_sport_map tsm
  SET sport_id = ns.sport_id
  FROM app.sport ns
  JOIN app.sport os ON os.sport_name = ns.sport_name AND os.tenant_id = 1
  WHERE tsm.sport_id = os.sport_id
    AND tsm.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

-- tenant_type → tenant.tenant_type_id
UPDATE app.tenant ten
  SET tenant_type_id = ns.tenant_type_id
  FROM app.tenant_type ns
  JOIN app.tenant_type os ON os.tenant_type_name = ns.tenant_type_name AND os.tenant_id = 1
  WHERE ten.tenant_type_id = os.tenant_type_id
    AND ten.tenant_id = ns.tenant_id
    AND ns.tenant_id != 1;

------------------------------------------------------------
-- PART E: Set NOT NULL, add FK to tenant, enable RLS
------------------------------------------------------------

-- assignment_status
ALTER TABLE app.assignment_status ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.assignment_status ADD CONSTRAINT fk_assignment_status_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);
ALTER TABLE app.assignment_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.assignment_status FORCE ROW LEVEL SECURITY;
CREATE POLICY assignment_status_tenant_isolation ON app.assignment_status FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- contest_status
ALTER TABLE app.contest_status ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.contest_status ADD CONSTRAINT fk_contest_status_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);
ALTER TABLE app.contest_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.contest_status FORCE ROW LEVEL SECURITY;
CREATE POLICY contest_status_tenant_isolation ON app.contest_status FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- contest_type
ALTER TABLE app.contest_type ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.contest_type ADD CONSTRAINT fk_contest_type_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);
ALTER TABLE app.contest_type ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.contest_type FORCE ROW LEVEL SECURITY;
CREATE POLICY contest_type_tenant_isolation ON app.contest_type FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- invoice_payment_type
ALTER TABLE app.invoice_payment_type ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.invoice_payment_type ADD CONSTRAINT fk_invoice_payment_type_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);
ALTER TABLE app.invoice_payment_type ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.invoice_payment_type FORCE ROW LEVEL SECURITY;
CREATE POLICY invoice_payment_type_tenant_isolation ON app.invoice_payment_type FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- invoice_status
ALTER TABLE app.invoice_status ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.invoice_status ADD CONSTRAINT fk_invoice_status_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);
ALTER TABLE app.invoice_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.invoice_status FORCE ROW LEVEL SECURITY;
CREATE POLICY invoice_status_tenant_isolation ON app.invoice_status FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- membership_status
ALTER TABLE app.membership_status ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.membership_status ADD CONSTRAINT fk_membership_status_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);
ALTER TABLE app.membership_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.membership_status FORCE ROW LEVEL SECURITY;
CREATE POLICY membership_status_tenant_isolation ON app.membership_status FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- notification_status
ALTER TABLE app.notification_status ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.notification_status ADD CONSTRAINT fk_notification_status_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);
ALTER TABLE app.notification_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.notification_status FORCE ROW LEVEL SECURITY;
CREATE POLICY notification_status_tenant_isolation ON app.notification_status FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- notification_type
ALTER TABLE app.notification_type ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.notification_type ADD CONSTRAINT fk_notification_type_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);
ALTER TABLE app.notification_type ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.notification_type FORCE ROW LEVEL SECURITY;
CREATE POLICY notification_type_tenant_isolation ON app.notification_type FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- payment_status
ALTER TABLE app.payment_status ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.payment_status ADD CONSTRAINT fk_payment_status_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);
ALTER TABLE app.payment_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.payment_status FORCE ROW LEVEL SECURITY;
CREATE POLICY payment_status_tenant_isolation ON app.payment_status FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- payment_type
ALTER TABLE app.payment_type ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.payment_type ADD CONSTRAINT fk_payment_type_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);
ALTER TABLE app.payment_type ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.payment_type FORCE ROW LEVEL SECURITY;
CREATE POLICY payment_type_tenant_isolation ON app.payment_type FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- person_type
ALTER TABLE app.person_type ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.person_type ADD CONSTRAINT fk_person_type_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);
ALTER TABLE app.person_type ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.person_type FORCE ROW LEVEL SECURITY;
CREATE POLICY person_type_tenant_isolation ON app.person_type FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- roles
ALTER TABLE app.roles ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.roles ADD CONSTRAINT fk_roles_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);
ALTER TABLE app.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.roles FORCE ROW LEVEL SECURITY;
CREATE POLICY roles_tenant_isolation ON app.roles FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- sport
ALTER TABLE app.sport ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.sport ADD CONSTRAINT fk_sport_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);
ALTER TABLE app.sport ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.sport FORCE ROW LEVEL SECURITY;
CREATE POLICY sport_tenant_isolation ON app.sport FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);

-- tenant_type
ALTER TABLE app.tenant_type ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE app.tenant_type ADD CONSTRAINT fk_tenant_type_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenant(tenant_id);
ALTER TABLE app.tenant_type ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.tenant_type FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_type_tenant_isolation ON app.tenant_type FOR ALL
  USING (current_setting('app.is_platform_admin', true) = 'true'
         OR tenant_id = current_setting('app.tenant_id', true)::BIGINT)
  WITH CHECK (current_setting('app.is_platform_admin', true) = 'true'
              OR tenant_id = current_setting('app.tenant_id', true)::BIGINT);
