-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Refinery Operations Intelligence
-- ============================================================================
USE DATABASE OIL_GAS_REFINERY;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_RETRAIN_ANOMALY_MODELS
  WAREHOUSE = OG_REFINERY_WH
  SCHEDULE = 'USING CRON 0 */4 * * * UTC'
  COMMENT = 'Retrain anomaly detection models every 4 hours'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_REFRESH_AI
  WAREHOUSE = OG_REFINERY_WH
  AFTER APP.TASK_RETRAIN_ANOMALY_MODELS
  COMMENT = 'Refresh AI alarm classification'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_SEND_NOTIFICATIONS
  WAREHOUSE = OG_REFINERY_WH
  AFTER APP.TASK_REFRESH_AI
  COMMENT = 'Send SNS notifications for critical excursions'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_SEND_NOTIFICATIONS RESUME;
ALTER TASK APP.TASK_REFRESH_AI RESUME;
ALTER TASK APP.TASK_RETRAIN_ANOMALY_MODELS RESUME;
