-- Synthetic unit-day observations for refinery process units (distillation,
-- conversion and treating). Nothing is seeded as a prediction. Randomness is
-- HASH-seeded, so every rebuild is reproducible: per-unit age and upset
-- propensity, fouling between maintenance windows, missed PM, unit-weighted
-- upset causes, and two site-wide utility power dips. Refineries and units are
-- fictional.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.UNITS AS
WITH units AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS UNIT_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 24))
), draws AS (
  SELECT UNIT_INDEX,
         MOD(ABS(HASH(UNIT_INDEX, 'age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(UNIT_INDEX, 'rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(UNIT_INDEX, 'pm')), 1000000) / 1e6 AS U_PM,
         MOD(ABS(HASH(UNIT_INDEX, 'discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(UNIT_INDEX, 'grade')), 1000000) / 1e6 AS U_GRADE
  FROM units
)
SELECT 'RU-' || LPAD(UNIT_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic unit ' || LPAD(UNIT_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (8 and 5 are coprime): every site and unit type is present.
       CASE MOD(UNIT_INDEX, 8) WHEN 0 THEN 'Pengerang' WHEN 1 THEN 'Pengerang' WHEN 2 THEN 'Pengerang'
            WHEN 3 THEN 'Port Dickson' WHEN 4 THEN 'Port Dickson' WHEN 5 THEN 'Melaka' WHEN 6 THEN 'Kerteh'
            ELSE 'Bintulu' END AS REGION,
       CASE MOD(UNIT_INDEX, 5) WHEN 0 THEN 'Crude Distillation' WHEN 1 THEN 'Vacuum Distillation'
            WHEN 2 THEN 'Catalytic Cracker' WHEN 3 THEN 'Catalytic Reformer' ELSE 'Hydrotreater' END AS CATEGORY,
       IFF(MOD(UNIT_INDEX, 5) < 2, 'Distillation', 'Conversion and treating') AS ROUTE,
       UNIT_INDEX,
       ROUND(1 + U_AGE * 24, 1) AS AGE_YEARS,
       -- Base daily upset probability 0.4%-3%; ~15% of units are chronic (x3).
       (0.004 + U_RATE * 0.026) * IFF(U_RATE > 0.85, 3, 1) AS BASE_UPSET_RATE,
       7 * (1 + FLOOR(U_PM * 3)) AS PM_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS PM_COMPLETION_PROB,
       -- Design yield: share of charge that leaves as the unit's target product.
       ROUND(100 * CASE MOD(UNIT_INDEX, 5) WHEN 0 THEN 0.42 + U_GRADE * 0.08 WHEN 1 THEN 0.45 + U_GRADE * 0.10
                   WHEN 2 THEN 0.50 + U_GRADE * 0.10 WHEN 3 THEN 0.82 + U_GRADE * 0.08
                   ELSE 0.95 + U_GRADE * 0.04 END, 2) AS DESIGN_YIELD_PCT,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.UNIT_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), power_dips AS (
  -- Two site-wide utility power dips in the window.
  SELECT * FROM VALUES (27, 'Pengerang', 3.5), (64, 'Port Dickson', 2.0) AS o(DAY_INDEX, REGION, HOURS)
), base AS (
  SELECT u.ID AS ENTITY_ID, u.UNIT_INDEX, u.CATEGORY, u.REGION, u.AGE_YEARS,
         u.BASE_UPSET_RATE, u.PM_INTERVAL_DAYS, u.PM_COMPLETION_PROB, u.DESIGN_YIELD_PCT,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         24.0 AS PLANNED_HOURS,
         MOD(d.DAY_INDEX + u.UNIT_INDEX * 5, u.PM_INTERVAL_DAYS) AS DAYS_SINCE_PM,
         MOD(ABS(HASH(u.ID, d.DAY_INDEX, 'upset')), 1000000) / 1e6 AS U_UPSET,
         MOD(ABS(HASH(u.ID, d.DAY_INDEX, 'down')), 1000000) / 1e6 + 1e-6 AS U_DOWN,
         MOD(ABS(HASH(u.ID, d.DAY_INDEX, 'cause')), 1000000) / 1e6 AS U_CAUSE,
         MOD(ABS(HASH(u.ID, d.DAY_INDEX, 'pmdone')), 1000000) / 1e6 AS U_PMDONE,
         MOD(ABS(HASH(u.ID, d.DAY_INDEX, 'feed')), 1000000) / 1e6 AS U_FEED,
         MOD(ABS(HASH(u.ID, d.DAY_INDEX, 'noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(u.ID, d.DAY_INDEX, 'hit')), 1000000) / 1e6 AS U_HIT,
         p.HOURS AS DIP_HOURS
  FROM RAW.UNITS u CROSS JOIN days d
  LEFT JOIN power_dips p ON p.DAY_INDEX = d.DAY_INDEX AND p.REGION = u.REGION
), pm AS (
  SELECT *,
         IFF(DAYS_SINCE_PM = 0, 1, 0) AS PM_DUE,
         IFF(DAYS_SINCE_PM = 0 AND U_PMDONE < PM_COMPLETION_PROB, 1, 0) AS PM_COMPLETED,
         -- Fouling (exchangers, trays, catalyst) rises between PM; weak discipline carries it over.
         DAYS_SINCE_PM / PM_INTERVAL_DAYS + (1 - PM_COMPLETION_PROB) AS WEAR
  FROM base
), upsets AS (
  SELECT *,
         CASE WHEN DIP_HOURS IS NOT NULL THEN 1
              WHEN U_UPSET < LEAST(0.5, BASE_UPSET_RATE * (0.4 + 1.6 * WEAR) * (1 + AGE_YEARS / 40)) / 4 THEN 2
              WHEN U_UPSET < LEAST(0.5, BASE_UPSET_RATE * (0.4 + 1.6 * WEAR) * (1 + AGE_YEARS / 40)) THEN 1
              ELSE 0 END AS UPSET_COUNT
  FROM pm
), timed AS (
  SELECT *,
         -- Unit-down hours: exponential, mean depends on the unit type.
         CASE WHEN UPSET_COUNT = 0 THEN 0.0
              WHEN DIP_HOURS IS NOT NULL THEN DIP_HOURS
              ELSE LEAST(20.0, ROUND(UPSET_COUNT * (0.5 - LN(U_DOWN) *
                   CASE CATEGORY WHEN 'Crude Distillation' THEN 3.0 WHEN 'Vacuum Distillation' THEN 3.5
                                 WHEN 'Catalytic Cracker' THEN 4.5 WHEN 'Catalytic Reformer' THEN 4.0 ELSE 2.5 END), 1))
         END AS DOWNTIME_HOURS
  FROM upsets
), output AS (
  SELECT *,
         PLANNED_HOURS - DOWNTIME_HOURS AS OPERATING_HOURS,
         -- Charge 1,500-4,000 bbl/h while running.
         ROUND((PLANNED_HOURS - DOWNTIME_HOURS) * (1500 + U_FEED * 2500)) AS CHARGE_BBL,
         -- Yield attainment versus design: base by unit, minus fouling, age and the upset hit.
         LEAST(0.995, GREATEST(0.60,
           CASE CATEGORY WHEN 'Crude Distillation' THEN 0.980 WHEN 'Vacuum Distillation' THEN 0.965
                         WHEN 'Catalytic Cracker' THEN 0.950 WHEN 'Catalytic Reformer' THEN 0.960 ELSE 0.975 END
           - 0.025 * WEAR - 0.004 * AGE_YEARS / 25 - 0.006 * U_NOISE
           - UPSET_COUNT * (0.04 + 0.08 * U_HIT))) AS ATTAINMENT,
         -- Fired-heater and utility energy per barrel of charge; fouling and upsets add losses.
         CASE CATEGORY WHEN 'Crude Distillation' THEN 0.12 WHEN 'Vacuum Distillation' THEN 0.09
                       WHEN 'Catalytic Cracker' THEN 0.20 WHEN 'Catalytic Reformer' THEN 0.28 ELSE 0.07 END
           * (1 + 0.08 * WEAR + 0.15 * UPSET_COUNT + 0.04 * U_NOISE) AS GJ_PER_BBL
  FROM timed
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE, PLANNED_HOURS, DOWNTIME_HOURS, OPERATING_HOURS,
       UPSET_COUNT,
       CASE WHEN UPSET_COUNT = 0 THEN 'None'
            WHEN DIP_HOURS IS NOT NULL THEN 'Utility power dip'
            WHEN CATEGORY = 'Crude Distillation' THEN IFF(U_CAUSE < 0.5, 'Desalter upset', IFF(U_CAUSE < 0.8, 'Heater burner instability', 'Overhead corrosion leak'))
            WHEN CATEGORY = 'Vacuum Distillation' THEN IFF(U_CAUSE < 0.45, 'Ejector vacuum loss', IFF(U_CAUSE < 0.8, 'Wash bed coking', 'Heater tube hot spot'))
            WHEN CATEGORY = 'Catalytic Cracker' THEN IFF(U_CAUSE < 0.5, 'Catalyst circulation upset', IFF(U_CAUSE < 0.8, 'Air blower trip', 'Slide valve sticking'))
            WHEN CATEGORY = 'Catalytic Reformer' THEN IFF(U_CAUSE < 0.6, 'Catalyst chloride imbalance', 'Recycle compressor trip')
            ELSE IFF(U_CAUSE < 0.6, 'Reactor pressure drop rise', 'Charge pump seal failure') END AS ROOT_CAUSE,
       PM_DUE, PM_COMPLETED,
       CHARGE_BBL,
       ROUND(CHARGE_BBL * DESIGN_YIELD_PCT / 100) AS TARGET_PRODUCT_BBL,
       ROUND(CHARGE_BBL * DESIGN_YIELD_PCT / 100 * ATTAINMENT) AS PRODUCT_BBL,
       ROUND(CHARGE_BBL * GJ_PER_BBL + DOWNTIME_HOURS * 40, 1) AS ENERGY_GJ,
       ROUND(0.6 + 2.2 * WEAR + 2.5 * UPSET_COUNT + U_NOISE * 0.6, 2) AS SETPOINT_DEV_PCT,
       ROUND(355 + 30 * WEAR + 25 * UPSET_COUNT + U_NOISE * 10, 1) AS OUTLET_TEMP_C,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM output;

-- Critical spares coverage per unit (snapshot).
CREATE TABLE RAW.CRITICAL_SPARES AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Crude Distillation' THEN 'Heater burner tip set' WHEN 'Vacuum Distillation' THEN 'Ejector nozzle set'
                     WHEN 'Catalytic Cracker' THEN 'Slide valve actuator kit' WHEN 'Catalytic Reformer' THEN 'Recycle compressor seal kit'
                     ELSE 'Charge pump mechanical seal' END AS PART_TYPE,
       1 + MOD(ABS(HASH(ID, 'req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'hand')), 5) AS ON_HAND_QTY,
       IFF(MOD(ABS(HASH(ID, 'hand')), 5) < 1 + MOD(ABS(HASH(ID, 'req')), 4),
           MOD(ABS(HASH(ID, 'order')), 3), 0) AS ON_ORDER_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.UNITS;
