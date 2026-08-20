-- =====================================================
-- Filename: transaction.sql
-- Project:  UMBC Parking Management System
-- Descr:    Demonstrates that the reservations_spot_id_tsrange_excl
--           EXCLUDE constraint (see createDDL.sql) prevents
--           double-booking a spot at the database level -- even when
--           the caller uses the exact same naive "check for overlap,
--           then insert" pattern that used to be unsafe, with no
--           manual locking (no SELECT ... FOR UPDATE, no
--           application-level mutex).
--
--           Before this constraint existed, two sessions running that
--           pattern concurrently could both pass their overlap check
--           (each seeing a stale, pre-commit view of the table) and
--           both insert, producing two reservations for the same spot
--           and the same time. The EXCLUDE constraint makes that
--           outcome impossible: Postgres enforces it the same way it
--           enforces UNIQUE -- whichever of two conflicting concurrent
--           inserts commits second is rejected outright.
-- =====================================================
-- =====================================================
-- SECTION 0: SETUP
-- Run this once before the demo. Safe to re-run.
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
-- SECTION 1: BASELINE -- ONE SESSION, TWO OVERLAPPING INSERTS
-- No second session needed for this part. Run it as one block in
-- pgAdmin or psql to see the constraint reject an overlapping
-- reservation immediately, inside a single transaction.
-- =====================================================
/*
BEGIN;

INSERT INTO reservations (
  reservation_id, start_time, end_time, status, user_id, vehicle_id, spot_id
) VALUES (
  801, TIMESTAMP '2026-05-14 09:00:00', TIMESTAMP '2026-05-14 11:00:00',
  'Active', 101, 101, 99
);

-- Overlaps the row above. Postgres can see the first row was inserted
-- in this same transaction, so this fails immediately.
INSERT INTO reservations (
  reservation_id, start_time, end_time, status, user_id, vehicle_id, spot_id
) VALUES (
  802, TIMESTAMP '2026-05-14 10:00:00', TIMESTAMP '2026-05-14 12:00:00',
  'Active', 102, 102, 99
);
-- Expected: ERROR: conflicting key value violates exclusion constraint
--   "reservations_spot_id_tsrange_excl"

ROLLBACK;
*/

-- =====================================================
-- SECTION 2: THE REAL TEST -- TWO CONCURRENT SESSIONS,
-- NO MANUAL LOCKING
--
-- This reproduces the exact scenario that used to cause double
-- booking before the EXCLUDE constraint existed: both sessions run
-- the SAME naive "check for overlap, then insert" pattern, with no
-- SELECT ... FOR UPDATE and no other manual locking.
--
-- Both sessions try to reserve spot T-001 (spot_id 99) for
-- 2026-05-15 09:00 to 11:00.
--
-- Expected result:
--   Exactly ONE session's reservation is committed.
--   The other session's overlap check still reports 0 (a genuinely
--   stale read -- the winning session had not committed yet when the
--   loser checked) but its INSERT is rejected with a real
--   exclusion_violation instead of silently succeeding. Whichever
--   session commits first wins; that is expected and fine -- the
--   point is that it is never both.
--
-- Instructions:
--      1) Run the Session 1 block in a pgAdmin Query Tool tab.
--      2) While Session 1 is inside pg_sleep(15), open a second Query
--              Tool tab and run the Session 2 block.
--      3) Run SECTION 2 VERIFY after both sessions have finished.
-- =====================================================
-- -----------------------------------------------------
-- Session 1:
-- -----------------------------------------------------
/*
BEGIN;

-- Naive overlap check -- no locking. This is exactly the pattern
-- that used to be unsafe.
SELECT COUNT(*) AS overlapping_reservations
FROM reservations
WHERE spot_id = 99
  AND status <> 'Cancelled'
  AND TIMESTAMP '2026-05-15 11:00:00' > start_time
  AND TIMESTAMP '2026-05-15 09:00:00' < end_time;

-- Give Session 2 time to run its own stale overlap check before
-- Session 1 commits.
SELECT pg_sleep(15);

INSERT INTO reservations (
  reservation_id, start_time, end_time, status, user_id, vehicle_id, spot_id
) VALUES (
  901, TIMESTAMP '2026-05-15 09:00:00', TIMESTAMP '2026-05-15 11:00:00',
  'Active', 101, 101, 99
);

COMMIT;
*/
-- -----------------------------------------------------
-- Session 2:
-- Run this while Session 1 is inside pg_sleep(15).
-- -----------------------------------------------------
/*
BEGIN;

-- This overlap check will report 0 -- Session 1 has not committed
-- yet, so this is a genuinely stale read, same as it would have been
-- before the EXCLUDE constraint existed.
SELECT COUNT(*) AS overlapping_reservations
FROM reservations
WHERE spot_id = 99
  AND status <> 'Cancelled'
  AND TIMESTAMP '2026-05-15 09:00:00' < end_time
  AND TIMESTAMP '2026-05-15 11:00:00' > start_time;

-- This INSERT is what actually gets stopped: it either commits first
-- (if this session reaches it before Session 1 commits), or it
-- blocks until Session 1 finishes and then fails with
-- exclusion_violation if Session 1 committed first.
INSERT INTO reservations (
  reservation_id, start_time, end_time, status, user_id, vehicle_id, spot_id
) VALUES (
  902, TIMESTAMP '2026-05-15 09:00:00', TIMESTAMP '2026-05-15 11:00:00',
  'Active', 102, 102, 99
);

COMMIT;

-- If this session errors out, pgAdmin may leave the transaction open.
-- Run ROLLBACK; if needed.
*/
-- -----------------------------------------------------
-- SECTION 2 VERIFY
-- Descr: Run this after both Session 1 and Session 2 have finished
--        (one committed, the other should have errored out).
--        The count should be 1, never 2.
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
-- SECTION 3: SAME PROTECTION THROUGH make_reservation()
--
-- Confirms that a caller using the actual application entry point
-- (make_reservation(), rather than a raw INSERT) gets the same
-- protection, and that the losing call sees the friendly application
-- error message ('Spot already reserved for that time') instead of a
-- raw Postgres exclusion_violation -- see the EXCEPTION block inside
-- make_reservation() in createDDL.sql.
--
-- Both calls try to reserve spot T-001 for 2026-05-16 09:00 to 11:00.
-- Run Session 1's call, then Session 2's call (a second pgAdmin tab
-- is optional here since neither call sleeps, but using one still
-- works).
-- =====================================================
-- -----------------------------------------------------
-- SECTION 3 CLEANUP
-- Reset the database for a clean re-run of this section.
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
SELECT make_reservation(
  TIMESTAMP '2026-05-16 09:00:00',
  TIMESTAMP '2026-05-16 11:00:00',
  'Active',
  101,
  101,
  99
);
*/
-- -----------------------------------------------------
-- Session 2:
-- -----------------------------------------------------
/*
SELECT make_reservation(
  TIMESTAMP '2026-05-16 09:00:00',
  TIMESTAMP '2026-05-16 11:00:00',
  'Active',
  102,
  102,
  99
);
-- Expected: ERROR: Spot already reserved for that time
*/
