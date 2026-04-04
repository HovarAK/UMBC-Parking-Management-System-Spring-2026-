-- Users Related Tables
-- -------------------------------------------------------------------
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
    lot_name VARCHAR(100) UNIQUE NOT NULL,
    location VARCHAR(255) NOT NULL,
    is_gated BOOLEAN NOT NULL,
    total_capacity INT NOT NULL,
    parking_type_id INT NOT NULL,
    FOREIGN KEY (parking_type_id) REFERENCES parkingTypes(parking_type_id)
);

-- Spots represent individual parking spaces within a lot and are linked to the lot they belong to. They have attributes to indicate their type, current status, and whether they can be reserved.
CREATE TABLE spots (
    spot_id SERIAL PRIMARY KEY,
    spot_label VARCHAR(50) NOT NULL,
    spot_type VARCHAR(50) NOT NULL,
    current_status VARCHAR(20) NOT NULL,
    is_reservable BOOLEAN NOT NULL,
    lot_id INT NOT NULL,
    FOREIGN KEY (lot_id) REFERENCES lots(lot_id)
);

-- Reservation and Permit Related Tables
-- -------------------------------------------------------------------
-- Permits can be issued to users for specific parking privileges and are linked to parking sessions and reservations.
CREATE TABLE permits (
    permit_id SERIAL PRIMARY KEY,
    permit_type VARCHAR(50) NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL,
    user_id INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Reservations can be made for specific time slots and are linked to users, vehicles, and parking spots. They can also be associated with parking sessions and permits.
CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    spot_id INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
    FOREIGN KEY (spot_id) REFERENCES spots(spot_id)
);

-- Parking sessions represent the actual parking events and are linked to users, vehicles, parking spots, reservations, and permits. They track the start and end times of parking, as well as the status of the session.
CREATE TABLE parkingSessions (
    session_id SERIAL PRIMARY KEY,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    session_status VARCHAR(20) NOT NULL,
    user_id INT NOT NULL,
    spot_id INT NOT NULL,
    reservation_id INT NOT NULL,
    permit_id INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (spot_id) REFERENCES spots(spot_id),
    FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id),
    FOREIGN KEY (permit_id) REFERENCES permits(permit_id)
);

-- Ticketing Related Tables
CREATE TABLE tickets (
    ticket_id SERIAL PRIMARY KEY,
    issue_time TIMESTAMP NOT NULL,
    violation_type VARCHAR(100) NOT NULL,
    fine_amount DECIMAL(10, 2) NOT NULL,
    has_paid BOOLEAN NOT NULL,
    issued_to_user_id INT NOT NULL,
    issued_by_user_id INT NOT NULL,
    spot_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    permit_id INT NOT NULL,
    session_id INT NOT NULL,
    FOREIGN KEY (issued_to_user_id) REFERENCES users(user_id),
    FOREIGN KEY (issued_by_user_id) REFERENCES users(user_id),
    FOREIGN KEY (spot_id) REFERENCES spots(spot_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
    FOREIGN KEY (permit_id) REFERENCES permits(permit_id),
    FOREIGN KEY (session_id) REFERENCES parkingSessions(session_id)
);