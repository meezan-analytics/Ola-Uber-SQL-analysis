-- ============================================================
--  Ride-Hailing Database  |  Analysis Queries
--  Business questions answered using SQL
-- ============================================================


-- ─────────────────────────────────────────────────────────────
-- Q1. Total number of rides by status
-- ─────────────────────────────────────────────────────────────
SELECT ride_status,
       COUNT(*) AS total_rides_by_status
FROM rides
GROUP BY ride_status
ORDER BY total_rides_by_status DESC;


-- ─────────────────────────────────────────────────────────────
-- Q2. How many rides does each platform have?
-- ─────────────────────────────────────────────────────────────
SELECT platform,
       COUNT(*) AS total_rides
FROM rides
GROUP BY platform
ORDER BY total_rides DESC;


-- ─────────────────────────────────────────────────────────────
-- Q3. Average fare by ride type (Solo vs Shared)
-- ─────────────────────────────────────────────────────────────
SELECT ride_type,
       ROUND(AVG(fare_amount)::NUMERIC, 2) AS avg_fare
FROM rides
WHERE ride_status = 'Completed'
GROUP BY ride_type;


-- ─────────────────────────────────────────────────────────────
-- Q4. Count of users per city
-- ─────────────────────────────────────────────────────────────
SELECT city,
       COUNT(*) AS user_count
FROM users
GROUP BY city
ORDER BY user_count DESC;


-- ─────────────────────────────────────────────────────────────
-- Q5. Count of drivers by vehicle type
-- ─────────────────────────────────────────────────────────────
SELECT vehicle_type,
       COUNT(*) AS total_drivers
FROM drivers
GROUP BY vehicle_type
ORDER BY total_drivers DESC;


-- ─────────────────────────────────────────────────────────────
-- Q6. Most used payment method (completed rides only)
-- ─────────────────────────────────────────────────────────────
SELECT payment_method,
       COUNT(*) AS usage_count
FROM rides
WHERE ride_status = 'Completed'
GROUP BY payment_method
ORDER BY usage_count DESC;


-- ─────────────────────────────────────────────────────────────
-- Q7. Total revenue per month
-- ─────────────────────────────────────────────────────────────
SELECT TO_CHAR(request_time, 'YYYY-MM') AS month,
       ROUND(SUM(fare_amount)::NUMERIC, 2) AS total_revenue
FROM rides
GROUP BY month
ORDER BY month;


-- ─────────────────────────────────────────────────────────────
-- Q8. Average driver rating by vehicle type
-- ─────────────────────────────────────────────────────────────
SELECT vehicle_type,
       ROUND(AVG(rating)::NUMERIC, 2) AS avg_rating,
       COUNT(*) AS total_drivers
FROM drivers
WHERE rating IS NOT NULL
GROUP BY vehicle_type
ORDER BY avg_rating DESC;


-- ─────────────────────────────────────────────────────────────
-- Q9. Average fare per km by ride type
-- ─────────────────────────────────────────────────────────────
SELECT ride_type,
       ROUND(AVG(fare_per_km)::NUMERIC, 2) AS avg_fare_per_km
FROM rides
WHERE ride_status = 'Completed'
GROUP BY ride_type;


-- ─────────────────────────────────────────────────────────────
-- Q10. Solo vs Shared ride comparison
--      (Volume, pricing, distance, duration, efficiency, cancellation)
-- ─────────────────────────────────────────────────────────────
SELECT
  ride_type,
  COUNT(*)                                                         AS total_rides,
  ROUND(AVG(fare_amount)::NUMERIC, 2)                             AS avg_fare,
  ROUND(AVG(distance_km)::NUMERIC, 2)                             AS avg_distance_km,
  ROUND(AVG(ride_duration_minutes)::NUMERIC, 1)                   AS avg_duration_min,
  ROUND(AVG(fare_per_km)::NUMERIC, 2)                             AS avg_fare_per_km,
  ROUND(SUM(fare_amount)::NUMERIC, 2)                             AS total_revenue,
  COUNT(*) FILTER (WHERE ride_status = 'Cancelled')               AS cancellations,
  ROUND(
    COUNT(*) FILTER (WHERE ride_status = 'Cancelled') * 100.0
    / COUNT(*), 1
  )                                                                AS cancel_rate_pct
FROM rides
WHERE ride_status IN ('Completed', 'Cancelled')
GROUP BY ride_type
ORDER BY total_rides DESC;


-- ─────────────────────────────────────────────────────────────
-- Q11. Ola vs Uber platform performance
--      (Revenue, avg fare, driver earnings, cancellation rate)
-- ─────────────────────────────────────────────────────────────
SELECT
  platform,
  COUNT(*)                                                         AS total_rides,
  ROUND(AVG(fare_per_km)::NUMERIC, 2)                             AS avg_fare_per_km,
  ROUND(SUM(fare_amount)::NUMERIC, 2)                             AS total_revenue,
  ROUND(AVG(fare_amount)::NUMERIC, 2)                             AS avg_fare,
  ROUND(AVG(driver_earnings)::NUMERIC, 2)                         AS avg_driver_earnings,
  COUNT(*) FILTER (WHERE ride_status = 'Cancelled')               AS cancellations,
  ROUND(
    COUNT(*) FILTER (WHERE ride_status = 'Cancelled') * 100.0
    / COUNT(*), 1
  )                                                                AS cancel_rate_pct
FROM rides
WHERE ride_status IN ('Completed', 'Cancelled')
GROUP BY platform
ORDER BY total_rides DESC;


-- ─────────────────────────────────────────────────────────────
-- Q12. Top 20 users by total spend (Completed rides only)
--      (Loyalty program targeting, high-value user identification)
-- ─────────────────────────────────────────────────────────────
SELECT
  u.user_id,
  u.city,
  u.gender,
  u.age,
  COUNT(r.ride_id)                                    AS total_rides,
  ROUND(SUM(r.fare_amount)::NUMERIC, 2)              AS total_spend,
  ROUND(AVG(r.fare_amount)::NUMERIC, 2)              AS avg_fare,
  ROUND(MAX(r.fare_amount)::NUMERIC, 2)              AS max_fare,
  COUNT(*) FILTER (WHERE r.platform = 'Ola')         AS ola_rides,
  COUNT(*) FILTER (WHERE r.platform = 'Uber')        AS uber_rides
FROM users u
JOIN rides r ON u.user_id = r.user_id
WHERE r.ride_status = 'Completed'
GROUP BY u.user_id, u.city, u.gender, u.age
ORDER BY total_spend DESC
LIMIT 20;
