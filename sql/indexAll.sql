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
