-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Refinery Operations Intelligence
-- Country: MALAYSIA | Currency: MYR
-- ============================================================================
USE DATABASE OIL_GAS_REFINERY;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- PROCESS_UNITS: 24 rows — Refinery process units (CDU, VDU, FCC, reformer, hydrotreater, etc.)
-- SENSOR_READINGS: 2,000,000 rows — IoT sensor data — temperature, pressure, flow, level, vibration
-- ALARM_HISTORY: 5,000 rows — Process alarm events with severity and acknowledgement status
-- MAINTENANCE_LOG: 3,000 rows — Work orders, PM schedules, corrective maintenance records
-- OPERATIONS_DOCS: 80 rows — Operating procedures, safety bulletins, turnaround reports
-- REFINERY_ECONOMICS: 365 rows — Daily crack spread, throughput value, and margin data
