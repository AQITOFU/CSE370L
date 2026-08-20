-- ============================================================
-- Parking Management System — Full Schema
-- Run AFTER schema.sql (which creates the DB + Users table)
-- ============================================================
USE parking_management;

-- 1. PARKING_LOT
CREATE TABLE IF NOT EXISTS Parking_Lot (
    lot_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200) NOT NULL,
    total_capacity INT NOT NULL,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6)
);

-- 2. FLOOR (belongs to a Parking_Lot)
CREATE TABLE IF NOT EXISTS Floor (
    lot_id INT NOT NULL,
    floor_no INT NOT NULL,
    capacity INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- active / closed / maintenance
    PRIMARY KEY (lot_id, floor_no),
    FOREIGN KEY (lot_id) REFERENCES Parking_Lot(lot_id) ON DELETE CASCADE
);

-- 3. SPOT (belongs to a Floor)
CREATE TABLE IF NOT EXISTS Spot (
    lot_id INT NOT NULL,
    floor_no INT NOT NULL,
    spot_no INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'vacant', -- vacant / occupied / reserved / disabled
    spot_type VARCHAR(20) NOT NULL DEFAULT 'regular', -- regular / handicap / ev / compact
    PRIMARY KEY (lot_id, floor_no, spot_no),
    FOREIGN KEY (lot_id, floor_no) REFERENCES Floor(lot_id, floor_no) ON DELETE CASCADE
);

-- 4. VEHICLE
CREATE TABLE IF NOT EXISTS Vehicle (
    license_plate VARCHAR(20) PRIMARY KEY,
    model VARCHAR(50),
    customer_id INT -- loose reference, see Customer_Session note below
);

-- 5. CUSTOMER_SESSION
-- NOTE: kept as one entity to match your team's ER diagram, but customer_id
-- is NOT a safe primary key (same customer parks multiple times -> duplicate
-- customer_id across rows, which breaks PK uniqueness). session_id is the
-- real PK. customer_id/name/email/phone_no are denormalized on purpose here
-- — fine for a course project, but say this out loud in your report so it
-- reads as a decision, not an oversight.
CREATE TABLE IF NOT EXISTS Customer_Session (
    session_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone_no VARCHAR(20),
    license_plate VARCHAR(20) NOT NULL,
    lot_id INT NOT NULL,
    floor_no INT NOT NULL,
    spot_no INT NOT NULL,
    entry_time DATETIME NOT NULL,
    exit_time DATETIME NULL,
    total_duration INT NULL, -- minutes, computed on exit
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- active / completed
    FOREIGN KEY (license_plate) REFERENCES Vehicle(license_plate),
    FOREIGN KEY (lot_id, floor_no, spot_no) REFERENCES Spot(lot_id, floor_no, spot_no)
);

-- 6. RESERVATION
CREATE TABLE IF NOT EXISTS Reservation (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    license_plate VARCHAR(20) NOT NULL,
    lot_id INT NOT NULL,
    floor_no INT NOT NULL,
    spot_no INT NOT NULL,
    date_time DATETIME NOT NULL, -- when the reservation was made
    entry_time DATETIME NULL,    -- reserved window start
    exit_time DATETIME NULL,     -- reserved window end
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending / confirmed / cancelled / expired
    FOREIGN KEY (license_plate) REFERENCES Vehicle(license_plate),
    FOREIGN KEY (lot_id, floor_no, spot_no) REFERENCES Spot(lot_id, floor_no, spot_no)
);

-- 7. PAYMENT (tied to a completed/ongoing session; optionally linked to a reservation)
CREATE TABLE IF NOT EXISTS Payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    session_id INT NOT NULL,
    reservation_id INT NULL,
    amount DECIMAL(8,2) NOT NULL,
    payment_method VARCHAR(30) NOT NULL, -- cash / card / mobile_banking
    transaction_time DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending / paid / failed / refunded
    FOREIGN KEY (session_id) REFERENCES Customer_Session(session_id),
    FOREIGN KEY (reservation_id) REFERENCES Reservation(reservation_id)
);

-- 8. ENFORCED_RULES / CITATION (issued against a vehicle)
CREATE TABLE IF NOT EXISTS Enforced_Rules (
    citation_id INT AUTO_INCREMENT PRIMARY KEY,
    license_plate VARCHAR(20) NOT NULL,
    violation_type VARCHAR(100) NOT NULL,
    officer_name VARCHAR(100),
    fine_amount DECIMAL(8,2) NOT NULL,
    issue_time DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'unpaid', -- unpaid / paid / disputed / waived
    FOREIGN KEY (license_plate) REFERENCES Vehicle(license_plate)
);

-- ============================================================
-- SEED DATA (satisfies "database populated" requirement)
-- ============================================================
INSERT INTO Parking_Lot (name, address, total_capacity, latitude, longitude) VALUES
('Gulshan Central Parking', 'Gulshan Ave, Dhaka', 200, 23.7925, 90.4078),
('Dhanmondi Plaza Parking', 'Road 27, Dhanmondi, Dhaka', 120, 23.7461, 90.3742);

INSERT INTO Floor (lot_id, floor_no, capacity, status) VALUES
(1, 1, 50, 'active'),
(1, 2, 50, 'active'),
(2, 1, 60, 'active');

INSERT INTO Spot (lot_id, floor_no, spot_no, status, spot_type) VALUES
(1, 1, 1, 'vacant', 'regular'),
(1, 1, 2, 'occupied', 'regular'),
(1, 1, 3, 'vacant', 'handicap'),
(1, 2, 1, 'vacant', 'ev'),
(2, 1, 1, 'vacant', 'regular'),
(2, 1, 2, 'reserved', 'compact');

INSERT INTO Vehicle (license_plate, model, customer_id) VALUES
('DHA-1234', 'Toyota Axio', 1),
('DHA-5678', 'Honda Vezel', 2),
('DHA-9012', 'Suzuki Alto', 1);

INSERT INTO Customer_Session (customer_id, name, email, phone_no, license_plate, lot_id, floor_no, spot_no, entry_time, exit_time, total_duration, status) VALUES
(1, 'Fahim Rahman', 'fahim@example.com', '01710000001', 'DHA-1234', 1, 1, 2, '2026-08-18 09:00:00', '2026-08-18 11:30:00', 150, 'completed'),
(2, 'Nusrat Jahan', 'nusrat@example.com', '01710000002', 'DHA-5678', 2, 1, 1, '2026-08-19 08:00:00', NULL, NULL, 'active');

INSERT INTO Reservation (customer_id, license_plate, lot_id, floor_no, spot_no, date_time, entry_time, exit_time, status) VALUES
(1, 'DHA-9012', 2, 1, 2, '2026-08-19 07:00:00', '2026-08-20 09:00:00', '2026-08-20 12:00:00', 'confirmed');

INSERT INTO Payment (session_id, reservation_id, amount, payment_method, transaction_time, status) VALUES
(1, NULL, 250.00, 'mobile_banking', '2026-08-18 11:30:00', 'paid'),
(2, NULL, 0.00, 'cash', '2026-08-19 08:00:00', 'pending');

INSERT INTO Enforced_Rules (license_plate, violation_type, officer_name, fine_amount, issue_time, status) VALUES
('DHA-5678', 'Parked outside marked spot', 'Officer Karim', 500.00, '2026-08-19 10:15:00', 'unpaid');
