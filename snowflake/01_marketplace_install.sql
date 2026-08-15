-- ============================================================================
-- 01_MARKETPLACE_INSTALL.SQL — Install marketplace data for Refinery Operations Intelligence
-- ============================================================================
USE DATABASE OIL_GAS_REFINERY;
USE SCHEMA RAW;

-- Free listings to install from Snowflake Marketplace:
-- Install: Snowflake Public Data (Free)
--   https://app.snowflake.com/marketplace/listing/GZTSZ290BV255

-- Paid listing (mock): S&P Global Platts Pricing
--   Real data: https://app.snowflake.com/marketplace/listing/GZT0Z5I4XY0
--   Using mock table: REFINERY_ECONOMICS
CREATE TABLE IF NOT EXISTS RAW.REFINERY_ECONOMICS (
  ID INT AUTOINCREMENT, DATA VARIANT, LOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

