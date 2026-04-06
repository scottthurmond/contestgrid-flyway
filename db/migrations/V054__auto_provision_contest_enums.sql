-- V054: Auto-provision default contest_type and contest_status rows for new tenants
-- Also adds contest-statuses to BFF proxy (handled at app level, not DB)

-- Function: seed default contest_type rows for a new tenant
CREATE OR REPLACE FUNCTION app.provision_contest_types()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO app.contest_type (tenant_id, contest_type_name)
  VALUES
    (NEW.tenant_id, 'Regular Season'),
    (NEW.tenant_id, 'Playoff'),
    (NEW.tenant_id, 'Tournament');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: seed default contest_status rows for a new tenant
CREATE OR REPLACE FUNCTION app.provision_contest_statuses()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO app.contest_status (tenant_id, contest_status_name)
  VALUES
    (NEW.tenant_id, 'Normal'),
    (NEW.tenant_id, 'Cancelled'),
    (NEW.tenant_id, 'Rainout'),
    (NEW.tenant_id, 'Forfeit'),
    (NEW.tenant_id, 'Suspended');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers on tenant insert
CREATE TRIGGER trg_provision_contest_types
  AFTER INSERT ON app.tenant
  FOR EACH ROW
  EXECUTE FUNCTION app.provision_contest_types();

CREATE TRIGGER trg_provision_contest_statuses
  AFTER INSERT ON app.tenant
  FOR EACH ROW
  EXECUTE FUNCTION app.provision_contest_statuses();
