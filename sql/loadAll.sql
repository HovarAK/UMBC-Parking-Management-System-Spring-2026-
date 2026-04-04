-- Implement loadAll.sql with at least 10 rows per table and data that tests your constraints 
-- (active/expired permits, paid/unpaid tickets, overlapping reservation attempts, etc.).
-- -------------------------------------------------------------------------------------------

-- Insert values into the systemRoles table.
INSERT INTO systemRoles (role_name) VALUES
('Admin'),
('Enforcement Officer'),
('User'),
('Guest');

-- Insert values into the users table.
INSERT INTO users (first_name, last_name, email, role_id)
VALUES
('Alice','Smith','alice1@email.com',1),
('Bob','Jones','bob2@email.com',2),
('Carol','Lee','carol3@email.com',2),
('David','Kim','david4@email.com',3),
('Eve','Miller','eve5@email.com',3),
('Frank','White','frank6@email.com',3),
('Grace','Hall','grace7@email.com',4),
('Henry','Young','henry8@email.com',4),
('Ivy','Allen','ivy9@email.com',4),
('Jack','King','jack10@email.com',4);

-- Insert values into the vehicles table.
INSERT INTO vehicles (plate_number, make, model, color, user_id)
VALUES
('AAA111','Toyota','Camry','Blue',1),
('BBB222','Honda','Civic','Red',1),
('CCC333','Ford','Focus','White',3),
('DDD444','Tesla','Model 3','Black',4),
('EEE555','Nissan','Altima','Gray',5),
('FFF666','Chevy','Malibu','Silver',6),
('GGG777','BMW','X5','Black',7),
('HHH888','Audi','A4','White',8),
('III999','Kia','Soul','Green',9),
('JJJ000','Hyundai','Elantra','Blue',10);

-- Insert values into the parkingTypes table.
INSERT INTO parkingTypes (code, type_name) VALUES
('COMM','Commuter Lot'),
('RES','Residential Lot'),
('FAC','Faculty/Staff Lot'),
('GATE','Gated Faculty/Staff Lot');

-- Insert values into the lots table.
INSERT INTO lots (lot_name, location, is_gated, total_capacity, parking_type_id)
VALUES
    ('Lot 1','North',TRUE,100,1),
    ('Lot 2','South',FALSE,80,1),
    ('Lot 3','East',TRUE,60,2),
    ('Lot 4','West',FALSE,120,2),
    ('Lot 5','Garage 1',TRUE,200,3),
    ('Lot 6','Garage 2',TRUE,150,3),
    ('Lot 7','Visitor Area',FALSE,50,1),
    ('Lot 8','VIP Area',TRUE,20,4),
    ('Lot 9','Staff Area',FALSE,90,3),
    ('Lot 10','Overflow',FALSE,300,1);

-- Insert values into the spots table.
INSERT INTO spots (spot_label, spot_type, current_status, is_reservable, lot_id)
VALUES
    ('A1','Compact','Available',TRUE,1),
    ('A2','Compact','Occupied',TRUE,1),
    ('B1','Large','Available',FALSE,2),
    ('B2','Large','Occupied',FALSE,2),
    ('C1','EV','Available',TRUE,5),
    ('C2','EV','Occupied',TRUE,5),
    ('D1','ADA','Available',TRUE,6),
    ('D2','ADA','Occupied',TRUE,6),
    ('E1','General','Available',TRUE,3),
    ('E2','General','Occupied',TRUE,3);

-- Insert values into the permits table.
INSERT INTO permits (permit_type, valid_from, valid_to, user_id)
VALUES
    ('Student','2025-01-01','2026-12-31',1),
    ('Faculty','2024-01-01','2025-01-01',2), -- expired
    ('General','2025-06-01','2026-06-01',3),
    ('Visitor','2023-01-01','2024-01-01',4), -- expired
    ('EV','2025-03-01','2025-12-31',5),
    ('ADA','2025-02-01','2025-08-01',6),
    ('Staff','2024-05-01','2025-05-01',7), -- expired
    ('VIP','2025-07-01','2026-07-01',8),
    ('Student','2025-01-15','2025-04-01',9), -- expired
    ('Temp','2025-01-01','2026-01-01',10);

-- Insert values into the reservations table.
INSERT INTO reservations (start_time, end_time, status, user_id, vehicle_id, spot_id)
VALUES
    ('2026-04-03 08:00','2026-04-03 10:00','Active',1,1,1),
    ('2026-04-03 09:00','2026-04-03 11:00','Active',2,2,1), -- overlap
    ('2026-04-03 10:00','2026-04-03 12:00','Completed',3,3,2),
    ('2026-04-04 08:00','2026-04-04 09:00','Cancelled',4,4,3),
    ('2026-04-05 07:00','2026-04-05 09:00','Active',5,5,4),
    ('2026-04-06 08:00','2026-04-06 10:00','Active',6,6,5),
    ('2026-04-07 09:00','2026-04-07 11:00','Active',7,7,6),
    ('2026-04-08 10:00','2026-04-08 12:00','Completed',8,8,7),
    ('2026-04-09 08:00','2026-04-09 10:00','Active',9,9,8),
    ('2026-04-10 07:00','2026-04-10 09:00','Active',10,10,9);

-- Insert values into the parkingSessions table.
INSERT INTO parkingSessions (start_time, end_time, session_status, user_id, spot_id, reservation_id, permit_id)
VALUES
    ('2026-04-03 08:05','2026-04-03 09:30','Completed',1,1,1,1),
    ('2026-04-03 09:10','2026-04-03 10:30','Active',2,1,2,2),
    ('2026-04-03 10:15','2026-04-03 11:45','Completed',3,2,3,3),
    ('2026-04-04 08:10','2026-04-04 08:50','Completed',4,3,4,4),
    ('2026-04-05 07:10','2026-04-05 08:30','Active',5,4,5,5),
    ('2026-04-06 08:05','2026-04-06 09:30','Active',6,5,6,6),
    ('2026-04-07 09:05','2026-04-07 10:30','Active',7,6,7,7),
    ('2026-04-08 10:05','2026-04-08 11:30','Completed',8,7,8,8),
    ('2026-04-09 08:05','2026-04-09 09:30','Active',9,8,9,9),
    ('2026-04-10 07:05','2026-04-10 08:30','Active',10,9,10,10);

-- Inserting Values into the tickets table.
INSERT INTO tickets (issue_time, violation_type, fine_amount, has_paid,
issued_to_user_id, issued_by_user_id, spot_id, vehicle_id, permit_id, session_id)
VALUES
    ('2026-04-03 09:00','Expired Permit',50,FALSE,1,2,1,1,2,1),
    ('2026-04-03 10:00','No Permit',75,TRUE,2,3,1,2,2,2),
    ('2026-04-03 11:00','Overtime',30,FALSE,3,2,2,3,3,3),
    ('2026-04-04 08:30','Wrong Spot',40,TRUE,4,2,3,4,4,4),
    ('2026-04-05 08:30','No Reservation',60,FALSE,5,3,4,5,5,5),
    ('2026-04-06 09:00','Expired Permit',50,FALSE,6,2,5,6,7,6),
    ('2026-04-07 10:00','Overtime',30,TRUE,7,3,6,7,7,7),
    ('2026-04-08 11:00','No Permit',75,FALSE,8,2,7,8,8,8),
    ('2026-04-09 09:00','Wrong Spot',40,TRUE,9,3,8,9,9,9),
    ('2026-04-10 08:00','Expired Permit',50,FALSE,10,2,9,10,9,10);