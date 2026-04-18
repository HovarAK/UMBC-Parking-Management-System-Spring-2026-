-- =====================================================
-- loadAll.sql
-- UMBC-inspired sample data
-- 10 rows for each table except systemRoles and parkingTypes
-- =====================================================

-- -----------------------------------------------------
-- systemRoles
-- -----------------------------------------------------
INSERT INTO systemRoles (role_name)
VALUES
  ('Admin'),
  ('Enforcement Officer'),
  ('User'),
  ('Guest');

-- -----------------------------------------------------
-- users (10)
-- -----------------------------------------------------
INSERT INTO users (first_name, last_name, email, role_id)
VALUES
  ('Alyssa', 'Brown', 'alyssa.brown@umbc-example.edu', 1),
  ('Brandon', 'Carter', 'brandon.carter@umbc-example.edu', 2),
  ('Chloe', 'Davis', 'chloe.davis@umbc-example.edu', 2),
  ('Daniel', 'Evans', 'daniel.evans@umbc-example.edu', 3),
  ('Elena', 'Flores', 'elena.flores@umbc-example.edu', 3),
  ('Farah', 'Green', 'farah.green@umbc-example.edu', 3),
  ('Gavin', 'Harris', 'gavin.harris@umbc-example.edu', 3),
  ('Hana', 'Iqbal', 'hana.iqbal@umbc-example.edu', 3),
  ('Isaac', 'Johnson', 'isaac.johnson@umbc-example.edu', 3),
  ('Julia', 'Khan', 'julia.khan@umbc-example.edu', 4);

-- -----------------------------------------------------
-- vehicles (10)
-- -----------------------------------------------------
INSERT INTO vehicles (plate_number, make, model, color, user_id)
VALUES
  ('UMBC101', 'Toyota', 'Camry', 'Blue', 1),
  ('UMBC102', 'Honda', 'Civic', 'Red', 2),
  ('UMBC103', 'Ford', 'Escape', 'White', 3),
  ('UMBC104', 'Tesla', 'Model 3', 'Black', 4),
  ('UMBC105', 'Nissan', 'Altima', 'Gray', 5),
  ('UMBC106', 'Chevrolet', 'Malibu', 'Silver', 6),
  ('UMBC107', 'Hyundai', 'Elantra', 'Blue', 7),
  ('UMBC108', 'Kia', 'Soul', 'Green', 8),
  ('UMBC109', 'Subaru', 'Crosstrek', 'Orange', 9),
  ('UMBC110', 'Mazda', 'CX-5', 'Black', 10);

-- -----------------------------------------------------
-- parkingTypes
-- UMBC-style parking/permit groups
-- -----------------------------------------------------
INSERT INTO parkingTypes (code, info)
VALUES
  ('A', 'Commuter Student'),
  ('B', 'Walker Avenue Apartments'),
  ('C', 'Resident Student'),
  ('D', 'Faculty/Staff'),
  ('E', 'Gated Faculty/Staff'),
  ('F', 'First-Year Resident'),
  ('VIS', 'Visitor Pay-to-Park');

-- -----------------------------------------------------
-- lots (10)
-- UMBC-inspired lot names
-- -----------------------------------------------------
INSERT INTO lots (lot_name, location, is_gated)
VALUES
  ('Administration Drive Garage', 'Administration Drive', FALSE),
  ('Commons Garage', 'Commons Drive', FALSE),
  ('Walker Avenue Garage', 'Walker Avenue', FALSE),
  ('Lot 7 Walker Avenue', 'Walker Avenue', FALSE),
  ('Lot 9', 'Central Campus', FALSE),
  ('Stadium Lot', 'Retriever Athletics Complex', FALSE),
  ('Lot 24', 'Chesapeake Arena Area', FALSE),
  ('Satellite Lot 1', 'South Campus', FALSE),
  ('Satellite Lot 2', 'South Campus', FALSE),
  ('Walker Avenue Apartments Lot', 'Walker Avenue Apartments', FALSE);

-- -----------------------------------------------------
-- spots (10)
-- note: parking_type_id references parkingTypes
-- -----------------------------------------------------
INSERT INTO spots (
  spot_label,
  parking_type_id,
  current_status,
  is_reservable,
  lot_id
)
VALUES
  ('ADG-V01', 7, 'Available', FALSE, 1),
  ('CG-V01', 7, 'Occupied', FALSE, 2),
  ('WAG-V01', 7, 'Available', FALSE, 3),
  ('L7-V01', 7, 'Available', FALSE, 4),
  ('L9-V01', 7, 'Occupied', FALSE, 5),
  ('STAD-A01', 1, 'Available', TRUE, 6),
  ('L24-D01', 4, 'Reserved', TRUE, 7),
  ('SAT1-F01', 6, 'Available', TRUE, 8),
  ('SAT2-F01', 6, 'Occupied', TRUE, 9),
  ('WAA-B01', 2, 'Reserved', TRUE, 10);

-- -----------------------------------------------------
-- permits (10)
-- mix of active and expired permits
-- assumes permit_type allows UMBC-style values
-- -----------------------------------------------------
INSERT INTO permits (
  permit_type,
  valid_from,
  valid_to,
  user_id
)
VALUES
  ('E',       '2025-08-15', '2026-08-14', 1),   -- active admin/employee style
  ('D',       '2025-08-15', '2026-08-14', 2),   -- active enforcement officer
  ('D',       '2024-08-15', '2025-08-14', 3),   -- expired employee
  ('A',       '2025-08-15', '2026-08-14', 4),   -- active commuter
  ('A',       '2024-08-15', '2025-08-14', 5),   -- expired commuter
  ('C',       '2025-08-15', '2026-08-14', 6),   -- active resident
  ('B',       '2025-08-15', '2026-08-14', 7),   -- active walker apartments
  ('F',       '2025-08-15', '2026-08-14', 8),   -- active first-year resident
  ('VISITOR', '2026-04-18', '2026-04-18', 9),   -- one-day visitor
  ('DAILY',   '2026-04-01', '2026-04-01', 10);  -- expired daily permit

-- -----------------------------------------------------
-- reservations (10)
-- valid rows only, so the file loads cleanly
-- -----------------------------------------------------
INSERT INTO reservations (
  start_time,
  end_time,
  status,
  user_id,
  vehicle_id,
  spot_id
)
VALUES
  ('2026-04-14 08:00', '2026-04-14 10:00', 'Active',    4, 4, 6),
  ('2026-04-14 10:30', '2026-04-14 12:00', 'Completed', 1, 1, 7),
  ('2026-04-15 08:00', '2026-04-15 10:00', 'Pending',   8, 8, 8),
  ('2026-04-15 10:30', '2026-04-15 12:30', 'Active',    7, 7, 10),
  ('2026-04-16 09:00', '2026-04-16 11:00', 'Cancelled', 6, 6, 6),
  ('2026-04-16 12:00', '2026-04-16 14:00', 'Completed', 9, 9, 1),
  ('2026-04-17 08:30', '2026-04-17 10:30', 'Active',    2, 2, 7),
  ('2026-04-17 11:00', '2026-04-17 13:00', 'Pending',   5, 5, 8),
  ('2026-04-18 09:00', '2026-04-18 11:00', 'Active',   10, 10, 3),
  ('2026-04-18 12:00', '2026-04-18 14:00', 'Completed', 3, 3, 6);

-- -----------------------------------------------------
-- parkingSessions (10)
-- includes vehicle_id now
-- includes some NULL permit_id / reservation_id
-- -----------------------------------------------------
INSERT INTO parkingSessions (
  start_time,
  end_time,
  session_status,
  user_id,
  vehicle_id,
  spot_id,
  reservation_id,
  permit_id
)
VALUES
  ('2026-04-14 08:05', '2026-04-14 09:40', 'Completed', 4, 4, 6, 1, 4),
  ('2026-04-14 10:35', '2026-04-14 11:55', 'Completed', 1, 1, 7, 2, 1),
  ('2026-04-15 08:05', '2026-04-15 09:45', 'Active',    8, 8, 8, 3, 8),
  ('2026-04-15 10:35', '2026-04-15 12:05', 'Active',    7, 7, 10, 4, 7),
  ('2026-04-16 09:05', '2026-04-16 10:50', 'Cancelled', 6, 6, 6, 5, 6),
  ('2026-04-16 12:05', '2026-04-16 13:20', 'Completed', 9, 9, 1, 6, 9),
  ('2026-04-17 08:35', '2026-04-17 10:20', 'Active',    2, 2, 7, 7, 2),
  ('2026-04-17 11:05', '2026-04-17 12:40', 'Active',    5, 5, 8, 8, 5),   -- expired permit
  ('2026-04-18 09:05', '2026-04-18 10:45', 'Active',   10, 10, 3, 9, NULL), -- no permit
  ('2026-04-18 12:05', '2026-04-18 13:50', 'Completed', 3, 3, 6, NULL, 3);  -- no reservation + expired permit

-- -----------------------------------------------------
-- tickets (10)
-- mix of paid/unpaid and active/expired/no-permit cases
-- -----------------------------------------------------
INSERT INTO tickets (
  created_at,
  violation_type,
  fine_amount,
  has_paid,
  issued_to_user_id,
  issued_by_user_id,
  spot_id,
  vehicle_id,
  permit_id,
  session_id
)
VALUES
  ('2026-04-14 09:45', 'Overtime',          30.00, TRUE,  4, 2, 6, 4, 4, 1),
  ('2026-04-14 12:00', 'Unauthorized Spot', 40.00, FALSE, 1, 2, 7, 1, 1, 2),
  ('2026-04-15 10:00', 'Overtime',          30.00, FALSE, 8, 3, 8, 8, 8, 3),
  ('2026-04-15 12:10', 'Unauthorized Spot', 40.00, TRUE,  7, 2, 10, 7, 7, 4),
  ('2026-04-16 11:00', 'Unauthorized Spot', 40.00, FALSE, 6, 3, 6, 6, 6, 5),
  ('2026-04-16 13:30', 'Unauthorized Spot', 40.00, TRUE,  9, 2, 1, 9, 9, 6),
  ('2026-04-17 10:30', 'Overtime',          30.00, FALSE, 2, 3, 7, 2, 2, 7),
  ('2026-04-17 12:45', 'Expired Permit',    50.00, FALSE, 5, 2, 8, 5, 5, 8),
  ('2026-04-18 10:50', 'No Permit',         75.00, FALSE, 10, 3, 3, 10, NULL, 9),
  ('2026-04-18 14:00', 'Expired Permit',    50.00, TRUE,  3, 2, 6, 3, 3, 10);

-- -----------------------------------------------------
-- sensorEvents (10)
-- event_type and sensor_value match your CHECK constraints
-- -----------------------------------------------------
INSERT INTO sensorEvents (
  spot_id,
  event_time,
  event_type,
  sensor_value
)
VALUES
  (1,  '2026-04-14 07:55', 'OCCUPIED', 'ON'),
  (1,  '2026-04-14 10:05', 'VACANT',   'OFF'),
  (6,  '2026-04-14 08:00', 'OCCUPIED', 'ON'),
  (7,  '2026-04-14 10:25', 'RESERVED', 'ON'),
  (8,  '2026-04-15 07:50', 'OCCUPIED', 'ON'),
  (8,  '2026-04-15 10:05', 'VACANT',   'OFF'),
  (10, '2026-04-15 10:20', 'RESERVED', 'ON'),
  (3,  '2026-04-18 08:55', 'OCCUPIED', 'ON'),
  (3,  '2026-04-18 10:50', 'VACANT',   'OFF'),
  (6,  '2026-04-18 12:00', 'OCCUPIED', 'ON');
