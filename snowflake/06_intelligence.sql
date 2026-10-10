-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-telemetry alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_TELEMETRY.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic process-upset SOP corpus (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.PROCESS_DOCS AS
WITH causes AS (
  SELECT DISTINCT r.ROOT_CAUSE, u.CATEGORY
  FROM RAW.UNIT_DAILY r JOIN RAW.UNITS u ON u.ID = r.ENTITY_ID
  WHERE r.ROOT_CAUSE IS NOT NULL AND r.UPSET_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, ROOT_CAUSE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  ROOT_CAUSE,
  CATEGORY || ' - ' || ROOT_CAUSE || ' upset response' AS TITLE,
  'Synthetic demo SOP. Unit type: ' || CATEGORY || '. Upset cause: ' || ROOT_CAUSE || '. '
  || 'Step 1: move the unit to a safe reduced-rate state, route off-spec product to slop and notify the shift process engineer. '
  || 'Step 2: ' || CASE
       WHEN ROOT_CAUSE ILIKE '%desalter%' THEN 'check desalter interface level, wash water rate and mix valve pressure drop, and reduce crude charge until brine water quality recovers.'
       WHEN ROOT_CAUSE ILIKE '%burner%' OR ROOT_CAUSE ILIKE '%hot spot%' THEN 'check fuel gas pressure, excess oxygen and tube skin thermocouples against the heater operating window, and clean or replace burner tips.'
       WHEN ROOT_CAUSE ILIKE '%corrosion%' THEN 'isolate the leaking overhead exchanger, verify neutraliser and wash water injection, and schedule a thickness survey.'
       WHEN ROOT_CAUSE ILIKE '%ejector%' THEN 'check motive steam pressure and condenser cooling water, and switch to the standby ejector set.'
       WHEN ROOT_CAUSE ILIKE '%coking%' THEN 'raise wash oil rate to the minimum wetting limit, lower heater outlet temperature and track wash bed pressure drop.'
       WHEN ROOT_CAUSE ILIKE '%catalyst circulation%' OR ROOT_CAUSE ILIKE '%slide valve%' THEN 'check slide valve differential pressure and actuator response, and reduce feed rate until catalyst circulation is stable.'
       WHEN ROOT_CAUSE ILIKE '%blower%' OR ROOT_CAUSE ILIKE '%compressor%' THEN 'follow the trip-response checklist, confirm machine protection status and restart only after the area engineer approves.'
       WHEN ROOT_CAUSE ILIKE '%chloride%' THEN 'compare recycle gas moisture and chloride injection rate with the operating window and retune chloride dosing.'
       WHEN ROOT_CAUSE ILIKE '%pressure drop%' THEN 'trend reactor bed pressure drop, check feed filters and plan a skim or catalyst change if the rise continues.'
       WHEN ROOT_CAUSE ILIKE '%seal%' THEN 'switch to the standby pump, isolate and depressurise the failed pump, and replace the mechanical seal from critical spares.'
       WHEN ROOT_CAUSE ILIKE '%power%' THEN 'confirm utility power status, follow the load-shedding sequence and restart units in the approved order.'
       ELSE 'inspect the affected equipment, record readings and escalate to the area engineer if readings are out of tolerance.'
     END
  || ' Step 3: if setpoint deviation exceeds 5% or outlet temperature exceeds 385 C after restart, keep the unit at reduced rate. '
  || 'Step 4: record the root cause, product shortfall barrels and downtime in the plant maintenance system.' AS CONTENT
FROM causes;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.PROCESS_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, ROOT_CAUSE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, ROOT_CAUSE, CONTENT FROM SEARCH.PROCESS_DOCS);

-- ---------- Setpoint deviation anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.SETPOINT_DEV_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, SETPOINT_DEV_PCT::FLOAT AS SETPOINT_DEV
FROM RAW.UNIT_DAILY;
CREATE OR REPLACE VIEW ML.SETPOINT_DEV_TRAIN AS
SELECT * FROM ML.SETPOINT_DEV_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.SETPOINT_DEV_SERIES);
CREATE OR REPLACE VIEW ML.SETPOINT_DEV_DETECT AS
SELECT * FROM ML.SETPOINT_DEV_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.SETPOINT_DEV_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.SETPOINT_DEV_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.SETPOINT_DEV_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'SETPOINT_DEV',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.SETPOINT_DEV_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS SETPOINT_DEV, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.SETPOINT_DEV_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.SETPOINT_DEV_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'SETPOINT_DEV'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.PROCESS_ANALYTICS
  TABLES (
    units AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      COMMENT = 'One row per process unit, 90-day totals',
    risk AS ML.UPSET_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day process upset probability per unit',
    causes AS CURATED.UPSET_CAUSES PRIMARY KEY (ROOT_CAUSE)
      COMMENT = 'Process upsets by root cause, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Network-wide totals per day'
  )
  RELATIONSHIPS (risk_unit AS risk (ENTITY_ID) REFERENCES units)
  FACTS (
    units.product_f AS PRODUCT_BBL,
    units.target_product_f AS TARGET_PRODUCT_BBL,
    units.charge_f AS CHARGE_BBL,
    units.energy_f AS ENERGY_GJ,
    units.upsets_f AS UPSET_COUNT,
    units.downtime_hours_f AS DOWNTIME_HOURS,
    units.operating_hours_f AS OPERATING_HOURS,
    units.planned_hours_f AS PLANNED_HOURS,
    risk.upset_prob_f AS UPSET_PROB_7D,
    causes.cause_upsets_f AS UPSET_COUNT,
    causes.cause_shortfall_f AS PRODUCT_SHORTFALL_BBL,
    causes.cause_hours_f AS DOWNTIME_HOURS,
    daily.day_product_f AS PRODUCT_BBL,
    daily.day_target_f AS TARGET_PRODUCT_BBL,
    daily.day_upsets_f AS UPSET_COUNT
  )
  DIMENSIONS (
    units.unit_id AS ENTITY_ID WITH SYNONYMS = ('entities', 'unit', 'process unit', 'refinery unit'),
    units.unit_name AS ENTITY_NAME,
    units.site AS REGION WITH SYNONYMS = ('refinery', 'site', 'region', 'city') COMMENT = 'Malaysian city of the refinery site (fictional refineries)',
    units.unit_type AS CATEGORY WITH SYNONYMS = ('unit type', 'process', 'unit category') COMMENT = 'Crude Distillation and Vacuum Distillation are distillation; Catalytic Cracker, Catalytic Reformer and Hydrotreater are conversion and treating',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    causes.root_cause AS ROOT_CAUSE,
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    units.unit_count AS COUNT(units.unit_id) WITH SYNONYMS = ('number of entities', 'entity count', 'number of units'),
    units.overall_yield_attainment_pct AS 100 * SUM(units.product_f) / NULLIF(SUM(units.target_product_f), 0)
      COMMENT = 'Target product barrels made / target product barrels at design yield',
    units.total_product_bbl AS SUM(units.product_f),
    units.process_upsets AS SUM(units.upsets_f) WITH SYNONYMS = ('upsets', 'process events', 'unit trips'),
    units.energy_gj_per_bbl AS SUM(units.energy_f) / NULLIF(SUM(units.charge_f), 0)
      COMMENT = 'Energy GJ per barrel of charge',
    units.total_charge_bbl AS SUM(units.charge_f) WITH SYNONYMS = ('throughput', 'charge processed', 'barrels processed'),
    units.unit_availability_pct AS 100 * SUM(units.operating_hours_f) / NULLIF(SUM(units.planned_hours_f), 0),
    units.total_downtime_hours AS SUM(units.downtime_hours_f),
    risk.avg_upset_prob AS AVG(risk.upset_prob_f),
    causes.cause_upsets AS SUM(causes.cause_upsets_f),
    causes.cause_shortfall_bbl AS SUM(causes.cause_shortfall_f),
    causes.cause_downtime_hours AS SUM(causes.cause_hours_f),
    daily.daily_yield_attainment_pct AS 100 * SUM(daily.day_product_f) / NULLIF(SUM(daily.day_target_f), 0),
    daily.daily_upsets AS SUM(daily.day_upsets_f)
  )
  COMMENT = 'Synthetic Malaysia refinery operations analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.PROCESS_AGENT
  COMMENT = 'Process assistant over a synthetic network of Malaysian refinery process units'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give unit IDs and numbers with units."
  orchestration: "Use process_analyst for yield attainment, process upsets, energy intensity, charge, units, sites, risk and root causes. Use sop_search for upset response procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: process_analyst
      description: "Yield attainment, process upsets, energy per barrel, charge throughput, unit availability, root causes and upset-risk scores"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic upset-response SOPs by unit type and cause"
tool_resources:
  process_analyst:
    semantic_view: __DEMO_DB__.APP.PROCESS_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.PROCESS_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-telemetry alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), UNIT_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, SETPOINT_DEV_PCT FLOAT, OUTLET_TEMP_C FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION MY_OIL_GAS_REFINERY_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALARMS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (UNIT_ID, EVENT_TS, SETPOINT_DEV_PCT, OUTLET_TEMP_C, SOP_HINT)
    SELECT t.UNIT_ID, t.EVENT_TS, t.SETPOINT_DEV_PCT, t.OUTLET_TEMP_C,
           'Check ' || un.CATEGORY || ' SOPs; current risk band ' || COALESCE(r.RISK_BAND, 'n/a')
    FROM RAW.LIVE_TELEMETRY t
    JOIN RAW.UNITS un ON un.ID = t.UNIT_ID
    LEFT JOIN ML.UPSET_RISK_SCORES r ON r.ENTITY_ID = t.UNIT_ID
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.UNIT_ID = t.UNIT_ID AND l.EVENT_TS = t.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('MY_OIL_GAS_REFINERY_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Malaysia refinery unit alarm',
      'New live-telemetry alarms logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_ALARM_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_TELEMETRY t
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.UNIT_ID = t.UNIT_ID AND l.EVENT_TS = t.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALARMS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.UPSET_CAUSES REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.UPSET_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.UPSET_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.UPSET_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'AGE_YEARS', AGE_YEARS, 'SETPOINT_DEV_PCT', SETPOINT_DEV_PCT,
             'OUTLET_TEMP_C', OUTLET_TEMP_C, 'SETPOINT_DEV_7D', SETPOINT_DEV_7D, 'UPSETS_30D', UPSETS_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:UPSET::FLOAT, 4) AS UPSET_PROB_7D,
         CASE WHEN PRED:probability:UPSET::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:UPSET::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
