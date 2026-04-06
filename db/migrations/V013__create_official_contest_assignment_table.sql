-- V013__create_official_contest_assignment_table.sql
-- Description: Track official-to-contest assignments for scheduling

-- Assignment status reference table
CREATE TABLE assignment_status (
  assignment_status_id SERIAL PRIMARY KEY,
  assignment_status_name VARCHAR(50) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE assignment_status IS 'Lookup table for official assignment statuses';

INSERT INTO assignment_status (assignment_status_id, assignment_status_name) VALUES
  (1, 'Pending'),
  (2, 'Confirmed'),
  (3, 'Declined'),
  (4, 'Cancelled'),
  (5, 'Completed')
ON CONFLICT (assignment_status_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('assignment_status', 'assignment_status_id'),
  GREATEST((SELECT COALESCE(MAX(assignment_status_id), 1) FROM assignment_status), 5), true);

-- Official contest assignment table
CREATE TABLE official_contest_assignment (
  assignment_id BIGSERIAL PRIMARY KEY,
  contest_schedule_id BIGINT NOT NULL REFERENCES contest_schedule(contest_schedule_id) ON DELETE CASCADE,
  official_id BIGINT NOT NULL REFERENCES official(official_id) ON DELETE CASCADE,
  assignment_status_id INT NOT NULL DEFAULT 1 REFERENCES assignment_status(assignment_status_id) ON DELETE RESTRICT,
  position_number INT NOT NULL DEFAULT 1,
  assigned_at TIMESTAMPTZ DEFAULT now(),
  confirmed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (contest_schedule_id, official_id)
);

CREATE INDEX idx_oca_contest ON official_contest_assignment(contest_schedule_id);
CREATE INDEX idx_oca_official ON official_contest_assignment(official_id);
CREATE INDEX idx_oca_status ON official_contest_assignment(assignment_status_id);
CREATE INDEX idx_oca_assigned_at ON official_contest_assignment(assigned_at);

COMMENT ON TABLE official_contest_assignment IS 'Maps officials to contest schedule entries for game assignments';
COMMENT ON COLUMN official_contest_assignment.position_number IS 'Position order (1=plate umpire, 2=base umpire, etc.)';
COMMENT ON COLUMN official_contest_assignment.confirmed_at IS 'Timestamp when the official confirmed the assignment';
