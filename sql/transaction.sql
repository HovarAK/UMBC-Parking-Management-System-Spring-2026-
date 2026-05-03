-- =====================================================
-- Filename: transaction.sql
-- Project:  UMBC Parking Management System
-- Descr:    Demo Demonstrating how to Prevent Deadlocks using Double Booking.
-- =====================================================
-- =====================================================
-- SECTION 0: SETUP
-- Run this once before the demo.
-- =====================================================
-- Clean up old demo data if this file was run before.
DELETE FROM public.reservations
WHERE
  spot_id = 99;

DELETE FROM public.vehicles
WHERE
  vehicle_id IN (101, 102);

DELETE FROM public.users
WHERE
  user_id IN (101, 102);

DELETE FROM public.spots
WHERE
  spot_id = 99;

DELETE FROM public.lots
WHERE
  lot_id = 99;

DELETE FROM parkingTypes
WHERE
  parking_type_id = 99;

-- Add one fake parking type.
INSERT INTO
  parkingTypes (parking_type_id, code, info)
VALUES
  (99, 'T', 'This is a Demo Parking Space Type');

-- Add one fake parking lot.
INSERT INTO
  lots (lot_id, lot_name, location, is_gated)
VALUES
  (99, 'Demo Lot', 'Test Area', FALSE);

-- Add one fake reservable parking spot.
INSERT INTO
  spots (
    spot_id,
    spot_label,
    parking_type_id,
    current_status,
    is_reservable,
    lot_id
  )
VALUES
  (99, 'T-001', 99, 'Available', TRUE, 99);

-- This adds a fake Person to the user database as a Guest (role_id == 4).
INSERT INTO
  users (user_id, first_name, last_name, email, role_id)
VALUES
  (101, 'James', 'Guest1', 'guest1@umbc.edu', 4);

-- Add fake person 2.
INSERT INTO
  users (user_id, first_name, last_name, email, role_id)
VALUES
  (102, 'Jordan', 'Guest2', 'guest2@umbc.edu', 4);

-- Add vehicle for fake person 1.
INSERT INTO
  vehicles (
    vehicle_id,
    plate_number,
    make,
    model,
    color,
    user_id
  )
VALUES
  (101, 'T001', 'Toyota', 'Corolla', 'Black', 101);

-- Add vehicle for fake person 2.
INSERT INTO
  vehicles (
    vehicle_id,
    plate_number,
    make,
    model,
    color,
    user_id
  )
VALUES
  (102, 'T002', 'Honda', 'Civic', 'Red', 102);

-- =====================================================
-- SECTION 1: CONCURRENCY PROBLEM
-- Problem: Double booking
--
-- Both users try to reserve spot T-001 within the same
--      time interval (9 AM to 11 AM).
--
-- Expected result:
--      Both sessions succeed.
--      This creates TWO reservations for the same spot and same time.
--
-- =====================================================
-- -----------------------------------------------------
-- SECTION 1a: UNSAFE VERSION
-- Description: An event of what occurs when two users reserve a parking
--                  spot at the same time without Two Phase Locking.
--
-- Instructions:
--      1) Run the code within Session 1 in pgAdmin Query Tool.
--      2) Don't close the previous session, and create a new query tool session
--              to run the code in Session 2.
-- -----------------------------------------------------
-- -----------------------------------------------------
-- Session 1:
-- -----------------------------------------------------
/*
BEGIN;

-- Check if the spot is already reserved.
SELECT COUNT(*) AS overlapping_reservations
FROM reservations
WHERE spot_id = 99
AND TIMESTAMP '2026-05-15 11:00:00' <= end_time
AND TIMESTAMP '2026-05-15 09:00:00' >= start_time;

-- This process waits, so that the User can run Section 2 within pgAdmin.
SELECT pg_sleep(15);

-- Guest 1 (James) reserves the Parking Spot w/ id = 99 within Lot 901.
INSERT INTO reservations (
reservation_id,
start_time,
end_time,
status,
user_id,
vehicle_id,
spot_id
)
VALUES (
901,
TIMESTAMP '2026-05-15 09:00:00',
TIMESTAMP '2026-05-15 11:00:00',
'Active',
101,
101,
99
);

COMMIT;
*/
-- -----------------------------------------------------
-- Session 2:
-- -----------------------------------------------------
/*
BEGIN;

-- Session 2 checks whether the spot is already reserved.
-- It will likely see 0 because Session 1 has not inserted yet.
SELECT COUNT(*) AS overlapping_reservations
FROM reservations
WHERE spot_id = 99
AND TIMESTAMP '2026-05-15 09:00:00' <= end_time
AND TIMESTAMP '2026-05-15 11:00:00' >= start_time;

-- Guest 2 (Jordan) reserves the Parking Spot w/ id = 99 within Lot 901.
INSERT INTO reservations (
reservation_id,
start_time,
end_time,
status,
user_id,
vehicle_id,
spot_id
)
VALUES (
902,
TIMESTAMP '2026-05-15 09:00:00',
TIMESTAMP '2026-05-15 11:00:00',
'Active',
102,
102,
99
);

COMMIT;
*/
-- -----------------------------------------------------
-- SECTION 1b: VERIFY DOUBLE BOOKING
-- Descr: Run this after Session 1 and Session 2 both commit.
--          The count should be 2.
-- -----------------------------------------------------
/*
SELECT
spot_id,
start_time,
end_time,
COUNT(*) AS number_of_reservations
FROM reservations
WHERE spot_id = 99
AND start_time = TIMESTAMP '2026-05-15 09:00:00'
AND end_time = TIMESTAMP '2026-05-15 11:00:00'
GROUP BY spot_id, start_time, end_time;

SELECT
reservation_id,
start_time,
end_time,
status,
user_id,
vehicle_id,
spot_id
FROM reservations
WHERE spot_id = 99
AND start_time = TIMESTAMP '2026-05-15 09:00:00'
AND end_time = TIMESTAMP '2026-05-15 11:00:00'
ORDER BY reservation_id;
*/
-- =====================================================
-- SECTION 2: PREVENTING DEADLOCK
-- Solution: SELECT ... FOR UPDATE
--
-- Desired Outcome:
--      The first session locks the spot row.
--      The second session must wait.
--      After the first session commits, the second session checks again
--      and fails because the reservation already exists.
--
-- Both users try to reserve spot T-001 at:
--      2026-05-16 09:00 to 11:00
--
-- Expected result:
--      Session 1 succeeds.
--      Session 2 blocks, then fails.
-- =====================================================
-- -----------------------------------------------------
-- SECTION 2 CLEANUP
-- Reset the database for a clean test.
-- -----------------------------------------------------
/*
DELETE FROM reservations
WHERE spot_id = 99
AND start_time = TIMESTAMP '2026-05-16 09:00:00'
AND end_time = TIMESTAMP '2026-05-16 11:00:00';
*/
-- -----------------------------------------------------
-- Session 1:
-- -----------------------------------------------------
/*
BEGIN;

-- Lock the parking spot row.
-- Any other transaction trying to lock this same spot must wait!!!
SELECT spot_id
FROM spots
WHERE spot_id = 99
FOR UPDATE;

-- Keep the lock open so the blocking behavior is visible.
SELECT pg_sleep(15);

-- Insert reservation for Guest 1 (James).
INSERT INTO reservations (
reservation_id,
start_time,
end_time,
status,
user_id,
vehicle_id,
spot_id
)
VALUES (
903,
TIMESTAMP '2026-05-16 09:00:00',
TIMESTAMP '2026-05-16 11:00:00',
'Active',
101,
101,
99
);

COMMIT;
*/
-- -----------------------------------------------------
-- SECTION 2B: SAFE VERSION - SESSION 2
-- Run this in pgAdmin Query Tool window #2 while Session 1 is sleeping.
--
-- This should BLOCK at SELECT ... FOR UPDATE.
-- After Session 1 commits, this continues.
-- Then it should FAIL with:
--   ERROR: Spot already reserved for that time
-- -----------------------------------------------------
/*
BEGIN;

-- This line blocks until Session 1 commits.
SELECT spot_id
FROM spots
WHERE spot_id = 99
FOR UPDATE;

-- After Session 1 commits, Session 2 checks again.
DO $$
DECLARE
overlap_count INT;
BEGIN
SELECT COUNT(*)
INTO overlap_count
FROM reservations
WHERE spot_id = 99
AND TIMESTAMP '2026-05-16 09:00:00' < end_time
AND TIMESTAMP '2026-05-16 11:00:00' > start_time;

IF overlap_count > 0 THEN
RAISE EXCEPTION 'Spot already reserved for that time';
END IF;
END;
$$;

-- This insert should not run if the DO block fails.
INSERT INTO reservations (
reservation_id,
start_time,
end_time,
status,
user_id,
vehicle_id,
spot_id
)
VALUES (
904,
TIMESTAMP '2026-05-16 09:00:00',
TIMESTAMP '2026-05-16 11:00:00',
'Active',
102,
102,
99
);

COMMIT;

-- If pgAdmin leaves the transaction open after the error, run:
-- ROLLBACK;
*/
-- -----------------------------------------------------
-- SECTION 2b: VERIFY PREVENTION
-- Descr: Run this section of code after running all the code below Section 2a.
--          We expect that the SEARCH query should return 1 reservation.
-- -----------------------------------------------------
/*
SELECT
spot_id,
start_time,
end_time,
COUNT(*) AS number_of_reservations
FROM reservations
WHERE spot_id = 99
AND start_time = TIMESTAMP '2026-05-16 09:00:00'
AND end_time = TIMESTAMP '2026-05-16 11:00:00'
GROUP BY spot_id, start_time, end_time;

SELECT
reservation_id,
start_time,
end_time,
status,
user_id,
vehicle_id,
spot_id
FROM reservations
WHERE spot_id = 99
AND start_time = TIMESTAMP '2026-05-16 09:00:00'
AND end_time = TIMESTAMP '2026-05-16 11:00:00'
ORDER BY reservation_id;
*/
