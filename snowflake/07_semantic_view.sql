-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Refinery Operations Intelligence
-- ============================================================================
USE DATABASE OIL_GAS_REFINERY;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.REFINERY_ANALYTICS
  COMMENT = 'Refinery operations, alarm, sensor, and throughput analytics'
AS
  TABLES (
    CURATED.UNIT_AVAILABILITY AS unit_availability,CURATED.SENSOR_TIMESERIES AS sensor_timeseries,CURATED.ALARM_SUMMARY AS alarm_summary,CURATED.THROUGHPUT_ECONOMICS AS throughput_economics
  );
