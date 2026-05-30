# 🚖 Ride-Sharing Data Cleaning & Analysis (Ola vs Uber)

A complete SQL project that simulates a real-world ride-sharing database (modeled on Ola & Uber), performs systematic data cleaning, and runs analytical queries to extract business insights.

---

## 📁 Project Structure

```
ride-sharing-sql/
├── schema.sql          # Table definitions (users, drivers, rides)
├── seed_data.sql       # INSERT statements for all three tables
├── data_cleaning.sql   # Step-by-step data quality fixes
└── analysis.sql        # Business analytics queries
```

---

## 🗃️ Database Schema

### `users`
| Column | Type | Description |
|---|---|---|
| user_id | INT (PK) | Unique user identifier |
| city | VARCHAR(50) | City of the user |
| signup_date | DATE | Date of registration |
| gender | VARCHAR(10) | Gender (normalized) |
| age | INT | User age |

### `drivers`
| Column | Type | Description |
|---|---|---|
| driver_id | INT (PK) | Unique driver identifier |
| rating | FLOAT | Driver rating (1.0–5.0) |
| vehicle_type | VARCHAR(20) | Sedan / SUV / Auto / Hatchback |
| signup_date | DATE | Date of registration |
| total_trips | INT | Cumulative trip count |

### `rides`
| Column | Type | Description |
|---|---|---|
| ride_id | SERIAL (PK) | Auto-incremented ride ID |
| user_id | INT (FK) | References users |
| driver_id | INT (FK) | References drivers |
| platform | VARCHAR(10) | Ola or Uber |
| ride_type | VARCHAR(10) | Solo or Shared |
| pickup_location | VARCHAR(100) | Pickup area |
| drop_location | VARCHAR(100) | Drop area |
| distance_km | FLOAT | Trip distance |
| ride_duration_minutes | INT | Trip duration |
| fare_amount | FLOAT | Total fare charged |
| driver_earnings | FLOAT | Driver's share |
| surge_multiplier | FLOAT | Surge pricing factor |
| payment_method | VARCHAR(20) | UPI / Cash / Card |
| ride_status | VARCHAR(15) | Completed / Cancelled |
| cancel_reason | VARCHAR(100) | Reason if cancelled |
| request_time | TIMESTAMP | Ride request timestamp |
| fare_per_km *(computed)* | FLOAT | fare_amount / distance_km |
| driver_cut_pct *(computed)* | FLOAT | driver_earnings / fare_amount × 100 |

---

## 🧹 Data Cleaning Pipeline

The cleaning is done in **5 structured steps**:

### Step 1 — Audit Dirty Data
- Count NULLs in `gender`, `age`, `city`
- Detect negative fares, zero-distance rides, invalid driver ratings
- Flag impossible ages (negative or > 100)

### Step 2 — Standardize Text Values
- Normalize `gender` variants (`M`, `MALE`, `F`, `FEMALE`, `Other`) → `Male` / `Female` / `Other`
- Replace NULL gender with `Unknown`
- Fix `vehicle_type` casing using `INITCAP()`

### Step 3 — Handle Invalid Numerics
- Set age to `NULL` where `age < 0` or `age > 100`
- Set rating to `NULL` where `rating < 1.0` or `rating > 5.0`
- Reset `total_trips` to `0` where negative
- Delete rides with `distance_km = 0`, negative fares, or negative driver earnings

### Step 4 — Remove Duplicate Rides
- Identify duplicates by `(user_id, driver_id, pickup_location, request_time)`
- Keep the lowest `ride_id`, delete the rest
- Fill missing `cancel_reason` for cancelled rides with `'Not_Specified'`

### Step 5 — Add Derived Columns
```sql
-- Fare efficiency
fare_per_km = ROUND((fare_amount / distance_km)::NUMERIC, 2)

-- Driver earnings share
driver_cut_pct = ROUND((driver_earnings / fare_amount * 100)::NUMERIC, 1)
```
Both columns are `GENERATED ALWAYS AS ... STORED` — computed and persisted automatically by PostgreSQL.

---

## 📊 Analysis Queries

### Ride Type Comparison (Solo vs Shared)
Compares volume, average fare, distance, duration, fare efficiency, total revenue, and cancellation rate by ride type.

### Platform Performance (Ola vs Uber)
Compares total rides, revenue, average fare, average driver earnings, and cancellation rate between platforms.

### Top 20 Users by Total Spend
Identifies highest-value users with breakdowns by city, gender, age, and platform preference — useful for loyalty targeting.

### Additional KPI Queries
- Ride count by status (Completed / Cancelled)
- Ride volume per platform
- Average fare by ride type
- Users per city
- Driver count by vehicle type
- Most-used payment methods
- Monthly revenue trend
- Average driver rating by vehicle type
- Average fare per km by ride type

---

## 🛠️ Setup & Usage

### Prerequisites
- PostgreSQL 13+ (uses `GENERATED ALWAYS AS` and `FILTER` aggregate syntax)

### Run in Order

```bash
# 1. Create tables
psql -d your_database -f schema.sql

# 2. Load seed data
psql -d your_database -f seed_data.sql

# 3. Clean the data
psql -d your_database -f data_cleaning.sql

# 4. Run analysis
psql -d your_database -f analysis.sql
```

Or run everything in a single session using your SQL client (pgAdmin, DBeaver, etc.).

---

## 🔍 Key Data Quality Issues Found & Fixed

| Issue | Table | Fix Applied |
|---|---|---|
| Inconsistent gender casing (M, MALE, F, FEMALE) | users | Normalized to Male/Female/Other/Unknown |
| Negative ages (e.g. -5, -8) | users | Set to NULL |
| Impossible ages (e.g. 150, 200) | users | Set to NULL |
| NULL gender values | users | Set to 'Unknown' |
| Driver ratings > 5.0 (e.g. 6.0, 7.2) | drivers | Set to NULL |
| Negative total_trips (e.g. -50) | drivers | Reset to 0 |
| Mixed-case vehicle types (sedan, HATCHBACK) | drivers | Normalized with INITCAP() |
| Negative fares / earnings | rides | Rows deleted |
| Zero-distance rides | rides | Rows deleted |
| Missing cancel_reason on cancelled rides | rides | Set to 'Not_Specified' |

---

## 📌 Notes

- Dataset covers **400 users**, **300 drivers**, and **400 ride records** across 6 Indian cities: Mumbai, Delhi, Bangalore, Chennai, Hyderabad, Pune, and Kolkata.
- Platform split: **Ola** and **Uber**
- Ride types: **Solo** and **Shared**
- All queries written for **PostgreSQL** — minor adjustments needed for MySQL or SQL Server.

---

## 📜 License

This project is for educational and portfolio purposes. Feel free to fork and adapt.
