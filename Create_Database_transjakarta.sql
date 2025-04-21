-- -----------------------------------------------
-- SETUP DATABASE STRUCTURE UNTUK TRANSJAKARTA
-- -----------------------------------------------

CREATE DATABASE transjakarta;
GO

USE transjakarta;
GO

CREATE TABLE users (
    user_id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(15),
    password_hash VARCHAR(255),
    registered_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE cards (
    card_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT,
    card_number VARCHAR(50) UNIQUE,
    balance DECIMAL(10,2),
    status VARCHAR(10),
    issued_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE buses (
    bus_id INT PRIMARY KEY IDENTITY(1,1),
    plate_number VARCHAR(20),
    model VARCHAR(50),
    capacity INT,
    status VARCHAR(20)
);

CREATE TABLE drivers (
    driver_id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100),
    license_number VARCHAR(50),
    phone VARCHAR(15),
    status VARCHAR(20),
    bus_id INT,
    FOREIGN KEY (bus_id) REFERENCES buses(bus_id)
);

CREATE TABLE routes (
    route_id INT PRIMARY KEY IDENTITY(1,1),
    route_name VARCHAR(100),
    start_point VARCHAR(100),
    end_point VARCHAR(100),
    distance_km DECIMAL(5,2)
);

CREATE TABLE stops (
    stop_id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100),
    location VARCHAR(255),
    is_terminal BIT DEFAULT 0
);

CREATE TABLE schedules (
    schedule_id INT PRIMARY KEY IDENTITY(1,1),
    route_id INT,
    stop_id INT,
    bus_id INT,
    driver_id INT,
    departure_time DATETIME,
    arrival_time DATETIME,
    FOREIGN KEY (route_id) REFERENCES routes(route_id),
    FOREIGN KEY (stop_id) REFERENCES stops(stop_id),
    FOREIGN KEY (bus_id) REFERENCES buses(bus_id),
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
);

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY IDENTITY(1,1),
    card_id INT,
    schedule_id INT,
    fare DECIMAL(10,2),
    FOREIGN KEY (card_id) REFERENCES cards(card_id),
    FOREIGN KEY (schedule_id) REFERENCES schedules(schedule_id)
);

CREATE TABLE incidents (	
    incident_id INT PRIMARY KEY IDENTITY(1,1),
    schedule_id INT,
    description TEXT,
    reported_at DATETIME DEFAULT GETDATE(),
    severity VARCHAR(10),
    resolved BIT DEFAULT 0,
    FOREIGN KEY (schedule_id) REFERENCES schedules(schedule_id)
);

-- -----------------------------------------------
-- INSERT DATA
-- -----------------------------------------------

-- 1000 USERS DAN CARDS
DECLARE @i INT = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO users (name, email, phone, password_hash)
    VALUES (CONCAT('User_', @i), CONCAT('user', @i, '@mail.com'), CONCAT('08123', FORMAT(@i, 'D6')), 'hashed_pw');

    INSERT INTO cards (user_id, card_number, balance, status, issued_at)
    VALUES (@i, CONCAT('CARD', FORMAT(@i, 'D6')), 100000, 'active', GETDATE());

    SET @i += 1;
END

-- 10 BUSES
INSERT INTO buses (plate_number, model, capacity, status)
VALUES 
('B1234TJ', 'Mercedes', 60, 'active'),
('B2345TJ', 'Scania', 60, 'active'),
('B3456TJ', 'Hino', 60, 'active'),
('B4567TJ', 'Volvo', 60, 'active'),
('B5678TJ', 'MAN', 60, 'active'),
('B6789TJ', 'Hyundai', 60, 'active'),
('B7890TJ', 'BYD', 60, 'active'),
('B8901TJ', 'Golden Dragon', 60, 'active'),
('B9012TJ', 'Zhongtong', 60, 'active'),
('B0123TJ', 'Daewoo', 60, 'active');

-- 20 DRIVERS (2 per bus)
SET @i = 1;
WHILE @i <= 20
BEGIN
    DECLARE @busRef INT = ((@i - 1) / 2) + 1;
    INSERT INTO drivers (name, license_number, phone, status, bus_id)
    VALUES (CONCAT('Driver_', @i), CONCAT('SIM', FORMAT(@i, 'D6')), CONCAT('08213', FORMAT(@i, 'D6')), 'active', @busRef);
    SET @i += 1;
END

-- ROUTES JABODETABEK
INSERT INTO routes (route_name, start_point, end_point, distance_km)
VALUES 
('Koridor 1', 'Blok M', 'Kota', 15.0),
('Koridor 2', 'Pulogadung', 'Harmoni', 12.5),
('Koridor 3', 'Kalideres', 'Pasar Baru', 17.2),
('Koridor 4', 'Pulogadung', 'Dukuh Atas', 14.1);

-- STOPS
INSERT INTO stops (name, location, is_terminal)
VALUES ('Blok M', 'Jakarta Selatan', 1), ('Kota', 'Jakarta Barat', 1), ('Pulogadung', 'Jakarta Timur', 1), ('Harmoni', 'Jakarta Pusat', 0), ('Kalideres', 'Jakarta Barat', 1), ('Pasar Baru', 'Jakarta Pusat', 0), ('Dukuh Atas', 'Jakarta Pusat', 1);

-- SCHEDULE SETIAP HARI (KECUALI MINGGU) JAM 05.00 - 19.00, DENGAN VARIASI DATA
DECLARE @date DATE = '2025-01-01';
WHILE @date <= '2025-02-28'
BEGIN
    IF DATENAME(WEEKDAY, @date) <> 'Sunday'
    BEGIN
        DECLARE @hour INT = 5;
        WHILE @hour <= 19
        BEGIN
            DECLARE @busId INT = 1 + ABS(CHECKSUM(NEWID())) % 10;
            DECLARE @driverId INT = 1 + ABS(CHECKSUM(NEWID())) % 20;
            DECLARE @routeId INT = 1 + ABS(CHECKSUM(NEWID())) % 4;
            DECLARE @stopId INT = 1 + ABS(CHECKSUM(NEWID())) % 7;

            INSERT INTO schedules (route_id, stop_id, bus_id, driver_id, departure_time, arrival_time)
            VALUES (@routeId, @stopId, @busId, @driverId, DATEADD(HOUR, @hour, CAST(@date AS DATETIME)), DATEADD(MINUTE, 60, DATEADD(HOUR, @hour, CAST(@date AS DATETIME))));

            SET @hour += 2;
        END
    END
    SET @date = DATEADD(DAY, 1, @date);
END

-- TRANSACTIONS (SAMPLE UNTUK 1000 PENGGUNA DENGAN schedule_id)
INSERT INTO transactions (card_id, schedule_id, fare)
SELECT TOP 1000 c.card_id, 1 + ABS(CHECKSUM(NEWID())) % (SELECT COUNT(*) FROM schedules), 3500
FROM cards c;

-- 2 INCIDENTS
INSERT INTO incidents (schedule_id, description, severity)
VALUES (1, 'Ban bocor di tengah perjalanan', 'medium'), (2, 'Penumpang pingsan, perlu bantuan medis', 'high');
