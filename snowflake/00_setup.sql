-- ============================================================================
-- Refinery Operations Intelligence
-- Real-time monitoring of Malaysia's refinery operations — IoT sensors stream process data, ML.ANOMALY_DETECTION catches excursions, and React Canvas visualizes the refinery digital twin.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS OIL_GAS_REFINERY;
CREATE WAREHOUSE IF NOT EXISTS OG_REFINERY_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE OIL_GAS_REFINERY;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE OG_REFINERY_WH;
