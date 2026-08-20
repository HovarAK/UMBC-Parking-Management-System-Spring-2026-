-- =====================================================
-- TABLES
-- =====================================================

-- Create the systemRoles table to define different roles in the system.
CREATE TABLE systemRoles(
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL
);

-- Create the users table to store user account information.
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    role_id INT NOT NULL,
    FOREIGN KEY (role_id) REFERENCES systemRoles(role_id)
);

-- Create the vehicles table to store information about vehicles owned by users. Each vehicle is linked to a user and has attributes such as plate number, make, model, and color.
CREATE TABLE vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    plate_number VARCHAR(20) UNIQUE NOT NULL,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    color VARCHAR(30) NOT NULL,
    user_id INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Parking Related Tables
-- -------------------------------------------------------------------
-- Parking types define different categories of parking (e.g., general, handicapped, electric vehicle) and are linked to lots. They have attributes to indicate the type of parking and any specific requirements or restrictions.
CREATE TABLE parkingTypes (
    parking_type_id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    info VARCHAR(100) NOT NULL
);

-- Lots represent parking areas and are linked to a specific parking type. They have attributes to indicate their location, whether they are gated, and their total capacity.
CREATE TABLE lots (
    lot_id SERIAL PRIMARY KEY,
    lot_name VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    is_gated BOOLEAN NOT NULL
);

-- Spots represent individual parking spaces within a lot and are linked to the lot they belong to. They have attributes to indicate their type, current status, and whether they can be reserved.
CREATE TABLE spots (
    spot_id SERIAL PRIMARY KEY,
    spot_label VARCHAR(50) NOT NULL,
    parking_type_id INT NOT NULL,
    current_status VARCHAR(20) NOT NULL
	CHECK (current_status IN ('Available', 'Occupied', 'Reserved')),
    is_reservable BOOLEAN NOT NULL,
    lot_id INT NOT NULL,
    FOREIGN KEY (lot_id) REFERENCES lots(lot_id),
    FOREIGN KEY (parking_type_id) REFERENCES parkingTypes(parking_type_id),
    UNIQUE (lot_id, spot_label)
);

-- Reservation and Permit Related Tables
-- -------------------------------------------------------------------
-- Permits can be issued to users for specific parking privileges and are linked to parking sessions and reservations.
-- permit_type is a foreign key into parkingTypes rather than free text, so a
-- permit's type shares the same enforced vocabulary as the spots it grants
-- access to (see the spots table) instead of drifting into its own set of
-- ad hoc strings.
CREATE TABLE permits (
    permit_id SERIAL PRIMARY KEY,
    parking_type_id INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL,
    user_id INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (parking_type_id) REFERENCES parkingTypes(parking_type_id),
    CHECK (valid_to >= valid_from)
);

-- Reservations can be made for specific time slots and are linked to users, vehicles, and parking spots. They can also be associated with parking sessions and permits.
CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL
    	CHECK (status IN ('Pending', 'Active', 'Cancelled', 'Completed')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    spot_id INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
    FOREIGN KEY (spot_id) REFERENCES spots(spot_id),
    CHECK (end_time >= start_time)
);

-- Parking sessions represent the actual parking events and are linked to users, vehicles, parking spots, reservations, and permits. They track the start and end times of parking, as well as the status of the session.
CREATE TABLE parkingSessions (
    session_id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    session_status VARCHAR(20) NOT NULL
	CHECK (session_status IN ('Active', 'Completed', 'Cancelled')),
    user_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    spot_id INT NOT NULL,
    reservation_id INT NULL,
    permit_id INT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
    FOREIGN KEY (spot_id) REFERENCES spots(spot_id),
    FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id),
    FOREIGN KEY (permit_id) REFERENCES permits(permit_id),
    CHECK (end_time >= start_time)
);

-- Ticketing Related Tables
CREATE TABLE tickets (
    ticket_id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    violation_type VARCHAR(100) NOT NULL
	CHECK (violation_type IN ('No Permit', 'Expired Permit', 
				  'Unauthorized Spot', 'Overtime')),
    fine_amount DECIMAL(10, 2) NOT NULL,
    has_paid BOOLEAN NOT NULL DEFAULT FALSE,
    issued_to_user_id INT NOT NULL,
    issued_by_user_id INT NOT NULL,
    spot_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    permit_id INT NULL,
    session_id INT NULL,
    FOREIGN KEY (issued_to_user_id) REFERENCES users(user_id),
    FOREIGN KEY (issued_by_user_id) REFERENCES users(user_id),
    FOREIGN KEY (spot_id) REFERENCES spots(spot_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
    FOREIGN KEY (permit_id) REFERENCES permits(permit_id),
    FOREIGN KEY (session_id) REFERENCES parkingSessions(session_id)
);

-- Table that represents triggers of the Sensors
CREATE TABLE IF NOT EXISTS sensorEvents (
    event_id SERIAL PRIMARY KEY,
    spot_id INT NOT NULL,
    event_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    event_type VARCHAR(30) NOT NULL
        CHECK (event_type IN ('OCCUPIED', 'VACANT', 'RESERVED')),    
    sensor_value VARCHAR(5) NOT NULL
	CHECK (sensor_value IN ('ON', 'OFF')),
    FOREIGN KEY (spot_id) REFERENCES spots(spot_id)
);


-- =====================================================
-- FUNCTIONS / PROCEDURES / TRIGGER
-- =====================================================

-- -----------------------------------------------------
-- FUNCTION: issue_permit
-- PURPOSE: Issues a permit for a user if all business
--          rules are satisfied.
-- PRE-CONDITIONS:
--   1. The user must exist in users.
--   2. The parking type must exist in parkingTypes.
--   3. valid_from must be on or before valid_to.
--   4. The user must not already have an overlapping
--      permit of the same parking type.
-- POST-CONDITIONS:
--   1. A new row is inserted into permits.
--   2. The new permit is linked to the given user and
--      parking type.
--   3. The function returns the new permit_id.
-- ----------------------------------------------------
CREATE OR REPLACE FUNCTION issue_permit(
    p_user_id INT,
    p_parking_type_id INT,
    p_valid_from DATE,
    p_valid_to DATE
)
RETURNS INT
AS $$
DECLARE
    new_permit_id INT;
    user_count INT;
    parking_type_count INT;
    permit_count INT;
BEGIN
    -- check dates
    IF p_valid_from > p_valid_to THEN
        RAISE EXCEPTION 'valid_from cannot be after valid_to';
    END IF;

    -- check user exists
    SELECT COUNT(*)
    INTO user_count
    FROM users
    WHERE user_id = p_user_id;

    IF user_count = 0 THEN
        RAISE EXCEPTION 'User does not exist';
    END IF;

    -- check parking type exists
    SELECT COUNT(*)
    INTO parking_type_count
    FROM parkingTypes
    WHERE parking_type_id = p_parking_type_id;

    IF parking_type_count = 0 THEN
        RAISE EXCEPTION 'Parking type does not exist';
    END IF;

    -- check if same kind of permit already overlaps
    SELECT COUNT(*)
    INTO permit_count
    FROM permits
    WHERE user_id = p_user_id
      AND parking_type_id = p_parking_type_id
      AND p_valid_from <= valid_to
      AND p_valid_to >= valid_from;

    IF permit_count > 0 THEN
        RAISE EXCEPTION 'User already has an overlapping permit of that parking type';
    END IF;

    -- insert permit
    INSERT INTO permits (parking_type_id, valid_from, valid_to, user_id)
    VALUES (p_parking_type_id, p_valid_from, p_valid_to, p_user_id)
    RETURNING permit_id INTO new_permit_id;

    RETURN new_permit_id;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------
-- FUNCTION: make_reservation
-- PURPOSE: Creates a reservation for a user, vehicle,
--          and parking spot.
-- PRE-CONDITIONS:
--   1. The user must exist in users.
--   2. The vehicle must exist in vehicles.
--   3. The spot must exist in spots.
--   4. The spot must be reservable.
--   5. start_time must be before end_time.
--   6. The spot must not already have an overlapping
--      reservation for the requested time.
-- POST-CONDITIONS:
--   1. A new row is inserted into reservations.
--   2. The reservation is linked to the given user,
--      vehicle, and spot.
--   3. The spot status may be updated to 'Reserved'.
--   4. The function returns the new reservation_id.
-- ----------------------------------------------------
CREATE OR REPLACE FUNCTION make_reservation(
    p_start_time TIMESTAMP,
    p_end_time TIMESTAMP,
    p_status VARCHAR(20),
    p_user_id INT,
    p_vehicle_id INT,
    p_spot_id INT
)
RETURNS INT
AS $$
DECLARE
    new_reservation_id INT;
    reservable_flag BOOLEAN;
    overlap_count INT;
BEGIN
    IF p_start_time >= p_end_time THEN
        RAISE EXCEPTION 'start_time must be before end_time';
    END IF;

    SELECT is_reservable
    INTO reservable_flag
    FROM spots
    WHERE spot_id = p_spot_id;

    IF reservable_flag IS NULL THEN
        RAISE EXCEPTION 'Spot does not exist';
    END IF;

    IF reservable_flag = FALSE THEN
        RAISE EXCEPTION 'Spot is not reservable';
    END IF;

    -- check overlap
    SELECT COUNT(*)
    INTO overlap_count
    FROM reservations
    WHERE spot_id = p_spot_id
      AND p_start_time < end_time
      AND p_end_time > start_time;

    IF overlap_count > 0 THEN
        RAISE EXCEPTION 'Spot already reserved for that time';
    END IF;

    INSERT INTO reservations (
        start_time,
        end_time,
        status,
        user_id,
        vehicle_id,
        spot_id
    )
    VALUES (
        p_start_time,
        p_end_time,
        p_status,
        p_user_id,
        p_vehicle_id,
        p_spot_id
    )
    RETURNING reservation_id INTO new_reservation_id;

    UPDATE spots
    SET current_status = 'Reserved'
    WHERE spot_id = p_spot_id;

    RETURN new_reservation_id;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------
-- PROCEDURE: delete_reservation
-- PURPOSE: Deletes an existing reservation and updates
--          the related spot status.
-- PRE-CONDITIONS:
--   1. The reservation must exist in reservations.
--   2. The reservation's spot_id must be retrievable.
-- POST-CONDITIONS:
--   1. The reservation row is removed from reservations.
--   2. The related spot status is updated to 'Available'.
-- ----------------------------------------------------
CREATE OR REPLACE PROCEDURE delete_reservation(
    p_reservation_id INT
)
AS $$
DECLARE
    reserved_spot_id INT;
BEGIN
    SELECT spot_id
    INTO reserved_spot_id
    FROM reservations
    WHERE reservation_id = p_reservation_id;

    IF reserved_spot_id IS NULL THEN
        RAISE EXCEPTION 'Reservation does not exist';
    END IF;

    DELETE FROM reservations
    WHERE reservation_id = p_reservation_id;

    UPDATE spots
    SET current_status = 'Available'
    WHERE spot_id = reserved_spot_id;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------
-- PROCEDURE: auto_ticket_violations
-- PURPOSE: Scans parking sessions and automatically
--          creates tickets for violations.
-- PRE-CONDITIONS:
--   1. The issuing user must exist in users.
--   2. parkingSessions must contain rows to scan.
--   3. tickets must allow inserts.
--   4. Permits must be available for checks when
--      permit_id is not null.
-- POST-CONDITIONS:
--   1. Tickets may be inserted for sessions with no
--      permit.
--   2. Tickets may be inserted for sessions with an
--      invalid or expired permit.
--   3. Duplicate tickets of the same type for the same
--      session are not inserted.
-- ----------------------------------------------------
CREATE OR REPLACE PROCEDURE auto_ticket_violations(
    p_issued_by_user_id INT
)
AS $$
BEGIN
    -- ticket sessions with no permit
    INSERT INTO tickets (
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
    SELECT
        'No Permit',
        50.00,
        FALSE,
        ps.user_id,
        p_issued_by_user_id,
        ps.spot_id,
        ps.vehicle_id,
        NULL,
        ps.session_id
    FROM parkingSessions ps
    WHERE ps.permit_id IS NULL
      AND NOT EXISTS (
          SELECT 1
          FROM tickets t
          WHERE t.session_id = ps.session_id
            AND t.violation_type = 'No Permit'
      );

    -- ticket sessions with expired/invalid permit
    INSERT INTO tickets (
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
    SELECT
        'Expired Permit',
        75.00,
        FALSE,
        ps.user_id,
        p_issued_by_user_id,
        ps.spot_id,
        ps.vehicle_id,
        ps.permit_id,
        ps.session_id
    FROM parkingSessions ps
    JOIN permits p
      ON ps.permit_id = p.permit_id
    WHERE DATE(ps.start_time) NOT BETWEEN p.valid_from AND p.valid_to
      AND NOT EXISTS (
          SELECT 1
          FROM tickets t
          WHERE t.session_id = ps.session_id
            AND t.violation_type = 'Expired Permit'
      );
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------
-- TRIGGER: trg_sensor_update
-- PURPOSE: Calls update_spot_status after a new sensor
--          event is inserted.
-- PRE-CONDITIONS:
--   1. The trigger must be created on sensorEvents.
--   2. An INSERT must occur on sensorEvents.
-- POST-CONDITIONS:
--   1. update_spot_status is executed.
--   2. The related spot status may be changed.
-- ----------------------------------------------------
DROP TRIGGER IF EXISTS trg_sensor_update ON sensorEvents;

CREATE OR REPLACE FUNCTION update_spot_status()
RETURNS TRIGGER
AS $$
BEGIN
    IF NEW.event_type = 'OCCUPIED' THEN
        UPDATE spots
        SET current_status = 'Occupied'
        WHERE spot_id = NEW.spot_id;
    ELSIF NEW.event_type = 'VACANT' THEN
        UPDATE spots
        SET current_status = 'Available'
        WHERE spot_id = NEW.spot_id;
    ELSIF NEW.event_type = 'RESERVED' THEN
        UPDATE spots
        SET current_status = 'Reserved'
        WHERE spot_id = NEW.spot_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- 6. Trigger
CREATE TRIGGER trg_sensor_update
AFTER INSERT ON sensorEvents
FOR EACH ROW
EXECUTE FUNCTION update_spot_status();


-- =====================================================
-- VIEWS
-- =====================================================

-- View Currently Active Permits
CREATE OR REPLACE VIEW CurrentActivePermits AS
SELECT
    p.permit_id,
    pt.code AS parking_type_code,
    pt.info AS parking_type_info,
    p.valid_from,
    p.valid_to,
    u.user_id,
    u.first_name,
    u.last_name,
    u.email
FROM permits p
JOIN users u
    ON p.user_id = u.user_id
JOIN parkingTypes pt
    ON p.parking_type_id = pt.parking_type_id
WHERE CURRENT_DATE BETWEEN p.valid_from AND p.valid_to;


-- Current Lot Availability
CREATE OR REPLACE VIEW CurrentLotAvailability AS
SELECT
    l.lot_id,
    l.lot_name,
    l.location,
    COUNT(s.spot_id) AS total_spots,
    COUNT(CASE WHEN s.current_status = 'Available' THEN 1 END) AS available_spots,
    COUNT(CASE WHEN s.current_status = 'Occupied' THEN 1 END) AS occupied_spots,
    COUNT(CASE WHEN s.current_status = 'Reserved' THEN 1 END) AS reserved_spots
FROM lots l
LEFT JOIN spots s
    ON l.lot_id = s.lot_id
GROUP BY l.lot_id, l.lot_name, l.location;


-- Overdue Payments
CREATE OR REPLACE VIEW OverduePayments AS
SELECT
    t.ticket_id,
    t.created_at,
    t.violation_type,
    t.fine_amount,
    u.user_id,
    u.first_name,
    u.last_name,
    v.plate_number
FROM tickets t
JOIN users u
    ON t.issued_to_user_id = u.user_id
JOIN vehicles v
    ON t.vehicle_id = v.vehicle_id
WHERE t.has_paid = FALSE;
