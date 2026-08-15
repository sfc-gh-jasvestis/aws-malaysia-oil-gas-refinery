-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Refinery Operations Intelligence
-- ============================================================================
USE DATABASE OIL_GAS_REFINERY;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.OPERATIONS_DOCS_SEARCH
  ON CONTENT
  ATTRIBUTES DOC_TYPE, UNIT_ID, SAFETY_LEVEL, AUTHOR
  WAREHOUSE = OG_REFINERY_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.OPERATIONS_DOCS
);
