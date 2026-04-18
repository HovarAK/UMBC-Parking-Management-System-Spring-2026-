-- =====================================================
-- Drop views, triggers, functions/procedures, and tables
-- in reverse dependency order
-- =====================================================

-- Drop views
DROP VIEW IF EXISTS OverduePayments CASCADE;
DROP VIEW IF EXISTS CurrentLotAvailability CASCADE;
DROP VIEW IF EXISTS CurrentActivePermits CASCADE;

-- Drop trigger
DROP TRIGGER IF EXISTS trg_sensor_update ON sensorEvents;

-- Drop functions / procedures
DROP FUNCTION IF EXISTS update_spot_status() CASCADE;
DROP PROCEDURE IF EXISTS auto_ticket_violations(INT) CASCADE;
DROP PROCEDURE IF EXISTS delete_reservation(INT) CASCADE;
DROP FUNCTION IF EXISTS make_reservation(TIMESTAMP, TIMESTAMP, VARCHAR, INT, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS issue_permit(INT, VARCHAR, DATE, DATE) CASCADE;

-- Drop tables in reverse order of creation
DROP TABLE IF EXISTS sensorEvents CASCADE;
DROP TABLE IF EXISTS tickets CASCADE;
DROP TABLE IF EXISTS parkingSessions CASCADE;
DROP TABLE IF EXISTS reservations CASCADE;
DROP TABLE IF EXISTS permits CASCADE;
DROP TABLE IF EXISTS spots CASCADE;
DROP TABLE IF EXISTS lots CASCADE;
DROP TABLE IF EXISTS parkingTypes CASCADE;
DROP TABLE IF EXISTS vehicles CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS systemRoles CASCADE;
