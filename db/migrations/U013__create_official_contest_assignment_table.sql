-- U013__create_official_contest_assignment_table.sql
-- Undo: Drop official_contest_assignment table and assignment_status reference

DROP TABLE IF EXISTS official_contest_assignment CASCADE;
DROP TABLE IF EXISTS assignment_status CASCADE;
