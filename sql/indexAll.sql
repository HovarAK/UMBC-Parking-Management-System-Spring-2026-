-- =====================================================
-- indexAll.sql
-- Indexes to improve expensive queries
-- =====================================================

-- Index 1
CREATE INDEX idx_parkingSessions_permit_id
ON parkingSessions (permit_id);

-- Index 2
CREATE INDEX idx_parkingSessions_vehicle_id
ON parkingSessions (vehicle_id);

-- Index 3
CREATE INDEX idx_parkingSessions_spot_id
ON parkingSessions (spot_id);

-- Index 4
CREATE INDEX idx_spots_lot_id
ON spots (lot_id);

-- Index 5
CREATE INDEX idx_tickets_spot_violation
ON tickets (spot_id, violation_type);

-- Indexes 6-13: remaining FK columns used by queryAll.sql joins/filters
-- and the views, that weren't already covered by indexes 1-5 above or by
-- the reservations_spot_id_tsrange_excl GiST index on reservations.
CREATE INDEX idx_permits_user_id
ON permits (user_id);

CREATE INDEX idx_tickets_issued_to_user_id
ON tickets (issued_to_user_id);

CREATE INDEX idx_tickets_issued_by_user_id
ON tickets (issued_by_user_id);

CREATE INDEX idx_vehicles_user_id
ON vehicles (user_id);

CREATE INDEX idx_users_role_id
ON users (role_id);

CREATE INDEX idx_parkingSessions_user_id
ON parkingSessions (user_id);

CREATE INDEX idx_parkingSessions_reservation_id
ON parkingSessions (reservation_id);

CREATE INDEX idx_sensorEvents_spot_id
ON sensorEvents (spot_id);
