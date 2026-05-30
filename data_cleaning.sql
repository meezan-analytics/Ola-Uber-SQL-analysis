-- ============================================================
--  Ride-Hailing Database  |  Data Cleaning
--  Step-by-step audit and cleanup of dirty data
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- STEP 1: Audit Dirty Data Before Cleaning
-- ─────────────────────────────────────────────────────────────

-- Audit users table: NULLs, invalid ages, inconsistent genders
SELECT
  COUNT(*) FILTER (WHERE gender IS NULL)  AS null_gender,
  COUNT(*) FILTER (WHERE age IS NULL)     AS null_age,
  COUNT(*) FILTER (WHERE age < 0)         AS negative_age,
  COUNT(*) FILTER (WHERE age > 100)       AS impossible_age,
  COUNT(*) FILTER (WHERE city IS NULL)    AS null_city
FROM users;

-- Audit rides table: invalid fares, zero distances, bad surges
SELECT
  COUNT(*) FILTER (WHERE fare_amount < 0)     AS negative_fare,
  COUNT(*) FILTER (WHERE distance_km <= 0)    AS zero_distance,
  COUNT(*) FILTER (WHERE driver_earnings < 0) AS negative_earnings,
  COUNT(*) FILTER (WHERE surge_multiplier < 1)AS bad_surge,
  COUNT(*) FILTER (WHERE ride_status IS NULL) AS null_status
FROM rides;

-- Audit drivers table: invalid ratings, negative trips, NULLs
SELECT
  COUNT(*) FILTER (WHERE rating > 5 OR rating < 0) AS invalid_rating,
  COUNT(*) FILTER (WHERE total_trips < 0)          AS negative_trips,
  COUNT(*) FILTER (WHERE rating IS NULL)           AS null_rating
FROM drivers;


-- ─────────────────────────────────────────────────────────────
-- STEP 2: Standardize Inconsistent Text Values
-- ─────────────────────────────────────────────────────────────

-- Fix gender: normalize all variants → Male / Female / Other / Unknown
UPDATE users
SET gender = CASE
  WHEN UPPER(gender) IN ('M', 'MALE')     THEN 'Male'
  WHEN UPPER(gender) IN ('F', 'FEMALE')   THEN 'Female'
  WHEN UPPER(gender) IN ('O', 'OTHER')    THEN 'Other'
  ELSE 'Unknown'
END;

-- Replace remaining NULL gender with 'Unknown'
UPDATE users SET gender = 'Unknown' WHERE gender IS NULL;

-- Fix vehicle_type casing in drivers (e.g. 'sedan' → 'Sedan')
UPDATE drivers
SET vehicle_type = INITCAP(vehicle_type)
WHERE vehicle_type != INITCAP(vehicle_type);


-- ─────────────────────────────────────────────────────────────
-- STEP 3: Handle Impossible / Invalid Numeric Values
-- ─────────────────────────────────────────────────────────────

-- Fix impossible ages (negative or > 100) → set to NULL
UPDATE users SET age = NULL WHERE age < 0 OR age > 100;

-- Fix driver ratings out of 1–5 range → set to NULL
UPDATE drivers SET rating = NULL WHERE rating < 1.0 OR rating > 5.0;

-- Fix negative total_trips → set to 0
UPDATE drivers SET total_trips = 0 WHERE total_trips < 0;

-- Delete rides with zero/negative fare, zero distance, or negative earnings
DELETE FROM rides
WHERE distance_km = 0
   OR fare_amount <= 0
   OR driver_earnings <= 0;


-- ─────────────────────────────────────────────────────────────
-- STEP 4: Find and Remove Duplicate Rides
-- ─────────────────────────────────────────────────────────────

-- Identify duplicates (same user, driver, time, and pickup location)
SELECT user_id, driver_id, pickup_location, request_time,
       COUNT(*) AS duplicate_count
FROM rides
GROUP BY user_id, driver_id, pickup_location, request_time
HAVING COUNT(*) > 1;

-- Delete duplicates keeping the lowest ride_id per group
DELETE FROM rides
WHERE ride_id NOT IN (
  SELECT MIN(ride_id)
  FROM rides
  GROUP BY user_id, driver_id, request_time, pickup_location
);

-- Verify: cancelled rides should have a cancel_reason
SELECT ride_id, ride_status, cancel_reason
FROM rides
WHERE ride_status = 'Cancelled' AND cancel_reason IS NULL;

-- Fill missing cancel_reason for cancelled rides
UPDATE rides
SET cancel_reason = 'Not_Specified'
WHERE ride_status = 'Cancelled' AND cancel_reason IS NULL;


-- ─────────────────────────────────────────────────────────────
-- STEP 5: Add Derived / Computed Columns
-- ─────────────────────────────────────────────────────────────

-- fare_per_km: how much is charged per km traveled
ALTER TABLE rides ADD COLUMN fare_per_km FLOAT
  GENERATED ALWAYS AS (
    CASE WHEN distance_km > 0
         THEN ROUND((fare_amount / distance_km)::NUMERIC, 2)
         ELSE NULL END
  ) STORED;

-- driver_cut_pct: percentage of fare that goes to the driver
ALTER TABLE rides ADD COLUMN driver_cut_pct FLOAT
  GENERATED ALWAYS AS (
    CASE WHEN fare_amount > 0
         THEN ROUND((driver_earnings / fare_amount * 100)::NUMERIC, 1)
         ELSE NULL END
  ) STORED;
