-- Undo V014: Drop payment tables
SET search_path TO app, public;

DROP TABLE IF EXISTS payment CASCADE;
DROP TABLE IF EXISTS payment_type CASCADE;
DROP TABLE IF EXISTS payment_status CASCADE;
