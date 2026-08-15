-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Refinery Operations Intelligence
-- ============================================================================
USE DATABASE OIL_GAS_REFINERY;
USE SCHEMA CURATED;

-- UNIT_AVAILABILITY: Real-time unit availability and uptime calculation
-- Source: PROCESS_UNITS, ALARM_HISTORY
CREATE OR REPLACE DYNAMIC TABLE CURATED.UNIT_AVAILABILITY
  TARGET_LAG = '5 minutes'
  WAREHOUSE = OG_REFINERY_WH
AS
SELECT * FROM RAW.PROCESS_UNITS;
-- TODO: Replace with actual join/aggregation logic per demo

-- SENSOR_TIMESERIES: Aggregated sensor readings for ML.ANOMALY_DETECTION input
-- Source: SENSOR_READINGS
CREATE OR REPLACE DYNAMIC TABLE CURATED.SENSOR_TIMESERIES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = OG_REFINERY_WH
AS
SELECT * FROM RAW.SENSOR_READINGS;
-- TODO: Replace with actual join/aggregation logic per demo

-- ALARM_SUMMARY: Alarm frequency and severity by unit in rolling 48hr window
-- Source: ALARM_HISTORY
CREATE OR REPLACE DYNAMIC TABLE CURATED.ALARM_SUMMARY
  TARGET_LAG = '5 minutes'
  WAREHOUSE = OG_REFINERY_WH
AS
SELECT * FROM RAW.ALARM_HISTORY;
-- TODO: Replace with actual join/aggregation logic per demo

-- THROUGHPUT_ECONOMICS: Daily throughput value and margin by process unit
-- Source: PROCESS_UNITS, REFINERY_ECONOMICS
CREATE OR REPLACE DYNAMIC TABLE CURATED.THROUGHPUT_ECONOMICS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = OG_REFINERY_WH
AS
SELECT * FROM RAW.PROCESS_UNITS;
-- TODO: Replace with actual join/aggregation logic per demo

