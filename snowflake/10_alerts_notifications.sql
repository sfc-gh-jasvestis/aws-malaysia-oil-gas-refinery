-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Refinery Operations Intelligence
-- ============================================================================
USE DATABASE OIL_GAS_REFINERY;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_malaysia_oil_gas_refinery_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('<YOUR_EMAIL>');

-- Alert: PROCESS_EXCURSION_ALERT
CREATE OR REPLACE ALERT APP.PROCESS_EXCURSION_ALERT
  WAREHOUSE = OG_REFINERY_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Process excursion detected — anomalous sensor reading'
IF (EXISTS (
  SELECT 1 FROM CURATED.UNIT_AVAILABILITY
  WHERE 1=1 -- Condition: IS_ANOMALY = TRUE for critical process parameter
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_malaysia_oil_gas_refinery_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Refinery Operations Intelligence: Process excursion detected — anomalous sensor reading',
    'Process excursion detected — anomalous sensor reading'
  );

ALTER ALERT APP.PROCESS_EXCURSION_ALERT RESUME;

-- Alert: AVAILABILITY_DROP_ALERT
CREATE OR REPLACE ALERT APP.AVAILABILITY_DROP_ALERT
  WAREHOUSE = OG_REFINERY_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Unit availability dropped below threshold'
IF (EXISTS (
  SELECT 1 FROM CURATED.UNIT_AVAILABILITY
  WHERE 1=1 -- Condition: UNIT_AVAILABILITY < 95% for any unit
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_malaysia_oil_gas_refinery_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Refinery Operations Intelligence: Unit availability dropped below threshold',
    'Unit availability dropped below threshold'
  );

ALTER ALERT APP.AVAILABILITY_DROP_ALERT RESUME;

-- Alert: ALARM_FLOOD_ALERT
CREATE OR REPLACE ALERT APP.ALARM_FLOOD_ALERT
  WAREHOUSE = OG_REFINERY_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Alarm flood detected — investigate root cause'
IF (EXISTS (
  SELECT 1 FROM CURATED.UNIT_AVAILABILITY
  WHERE 1=1 -- Condition: ALARM_COUNT_48H > 20 for any unit
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_malaysia_oil_gas_refinery_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Refinery Operations Intelligence: Alarm flood detected — investigate root cause',
    'Alarm flood detected — investigate root cause'
  );

ALTER ALERT APP.ALARM_FLOOD_ALERT RESUME;

