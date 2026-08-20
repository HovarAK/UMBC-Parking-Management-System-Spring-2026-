-- =====================================================
-- queryAll.sql
-- Simple college-level version
-- =====================================================

-- -----------------------------------------------------
-- Query 1
-- Show all users and their role names
-- Uses: JOIN
-- -----------------------------------------------------
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    sr.role_name
FROM users u
JOIN systemRoles sr
    ON u.role_id = sr.role_id
ORDER BY u.user_id;

-- -----------------------------------------------------
-- Query 2
-- Count how many vehicles each user owns
-- Uses: JOIN, GROUP BY
-- -----------------------------------------------------
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    COUNT(v.vehicle_id) AS vehicle_count
FROM users u
LEFT JOIN vehicles v
    ON u.user_id = v.user_id
GROUP BY
    u.user_id, u.first_name, u.last_name
ORDER BY vehicle_count DESC;

-- -----------------------------------------------------
-- Query 3
-- Show all active permits with user information
-- Uses: JOIN
-- -----------------------------------------------------
SELECT
    p.permit_id,
    pt.code AS parking_type_code,
    pt.info AS parking_type_info,
    p.valid_from,
    p.valid_to,
    u.first_name,
    u.last_name
FROM permits p
JOIN users u
    ON p.user_id = u.user_id
JOIN parkingTypes pt
    ON p.parking_type_id = pt.parking_type_id
WHERE CURRENT_DATE BETWEEN p.valid_from AND p.valid_to
ORDER BY p.valid_to;

-- -----------------------------------------------------
-- Query 4
-- Show how many spots are in each lot
-- Uses: JOIN, GROUP BY
-- -----------------------------------------------------
SELECT
    l.lot_id,
    l.lot_name,
    COUNT(s.spot_id) AS total_spots
FROM lots l
LEFT JOIN spots s
    ON l.lot_id = s.lot_id
GROUP BY
    l.lot_id, l.lot_name
ORDER BY l.lot_id;

-- -----------------------------------------------------
-- Query 5
-- Show unpaid ticket totals by user
-- Uses: JOIN, GROUP BY
-- -----------------------------------------------------
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    COUNT(t.ticket_id) AS unpaid_tickets,
    SUM(t.fine_amount) AS total_unpaid
FROM users u
JOIN tickets t
    ON u.user_id = t.issued_to_user_id
WHERE t.has_paid = FALSE
GROUP BY
    u.user_id, u.first_name, u.last_name
ORDER BY total_unpaid DESC;

-- -----------------------------------------------------
-- Query 6
-- Users who own more than one vehicle
-- Uses: subquery
-- -----------------------------------------------------
SELECT
    u.user_id,
    u.first_name,
    u.last_name
FROM users u
WHERE u.user_id IN (
    SELECT v.user_id
    FROM vehicles v
    GROUP BY v.user_id
    HAVING COUNT(v.vehicle_id) > 1
)
ORDER BY u.user_id;

-- -----------------------------------------------------
-- Query 7  [EXPENSIVE]
-- Show full parking session details
-- Uses: many JOINs
-- -----------------------------------------------------
SELECT
    ps.session_id,
    ps.start_time,
    ps.end_time,
    ps.session_status,
    u.first_name,
    u.last_name,
    v.plate_number,
    s.spot_label,
    l.lot_name,
    r.status AS reservation_status,
    pt.code AS permit_parking_type_code
FROM parkingSessions ps
JOIN users u
    ON ps.user_id = u.user_id
JOIN vehicles v
    ON ps.vehicle_id = v.vehicle_id
JOIN spots s
    ON ps.spot_id = s.spot_id
JOIN lots l
    ON s.lot_id = l.lot_id
LEFT JOIN reservations r
    ON ps.reservation_id = r.reservation_id
LEFT JOIN permits p
    ON ps.permit_id = p.permit_id
LEFT JOIN parkingTypes pt
    ON p.parking_type_id = pt.parking_type_id
ORDER BY ps.start_time DESC;

-- -----------------------------------------------------
-- Query 8  [EXPENSIVE]
-- Count tickets by lot and violation type
-- Uses: JOIN, GROUP BY
-- -----------------------------------------------------
SELECT
    l.lot_name,
    t.violation_type,
    COUNT(t.ticket_id) AS ticket_count,
    SUM(t.fine_amount) AS total_fines
FROM tickets t
JOIN spots s
    ON t.spot_id = s.spot_id
JOIN lots l
    ON s.lot_id = l.lot_id
GROUP BY
    l.lot_name, t.violation_type
ORDER BY ticket_count DESC, total_fines DESC;

-- -----------------------------------------------------
-- Query 9  [EXPENSIVE]
-- Show sessions with no permit or expired permit
-- Uses: JOIN, subquery
-- -----------------------------------------------------
SELECT
    ps.session_id,
    ps.user_id,
    ps.vehicle_id,
    ps.spot_id,
    ps.start_time,
    ps.permit_id
FROM parkingSessions ps
LEFT JOIN permits p
    ON ps.permit_id = p.permit_id
WHERE ps.permit_id IS NULL
   OR DATE(ps.start_time) < p.valid_from
   OR DATE(ps.start_time) > p.valid_to
ORDER BY ps.start_time DESC;

-- -----------------------------------------------------
-- Query 10
-- Show spots that have never been used in a reservation
-- Uses: subquery
-- -----------------------------------------------------
SELECT
    s.spot_id,
    s.spot_label,
    s.current_status,
    l.lot_name
FROM spots s
JOIN lots l
    ON s.lot_id = l.lot_id
WHERE s.spot_id NOT IN (
    SELECT r.spot_id
    FROM reservations r
)
ORDER BY l.lot_name, s.spot_label;
