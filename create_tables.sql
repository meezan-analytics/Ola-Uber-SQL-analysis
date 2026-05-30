-- ============================================================
--  Ride-Hailing Database  |  Schema Definition
--  Tables: users, drivers, rides
-- ============================================================

-- Create Users Table
CREATE TABLE users (
    user_id     INT PRIMARY KEY,
    city        VARCHAR(50),
    signup_date DATE,
    gender      VARCHAR(10),
    age         INT
);

-- Create Drivers Table
CREATE TABLE drivers (
    driver_id    INT PRIMARY KEY,
    rating       FLOAT,
    vehicle_type VARCHAR(20),
    signup_date  DATE,
    total_trips  INT DEFAULT 0
);

-- Create Rides Table
CREATE TABLE rides (
    ride_id                SERIAL PRIMARY KEY,
    user_id                INT,
    driver_id              INT,
    platform               VARCHAR(10),        -- Ola / Uber
    ride_type              VARCHAR(10),        -- Solo / Shared
    pickup_location        VARCHAR(100),
    drop_location          VARCHAR(100),
    distance_km            FLOAT,
    ride_duration_minutes  INT,
    fare_amount            FLOAT,
    driver_earnings        FLOAT,
    surge_multiplier       FLOAT,
    payment_method         VARCHAR(20),
    ride_status            VARCHAR(15),
    cancel_reason          VARCHAR(100),
    request_time           TIMESTAMP,
    FOREIGN KEY (user_id)   REFERENCES users(user_id),
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
);
