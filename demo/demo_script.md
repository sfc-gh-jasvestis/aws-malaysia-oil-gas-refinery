# Malaysia Refinery Operations

**Malaysia - Refinery Process Units (distillation, conversion and treating)**
Use case: Yield attainment monitoring and process-upset risk

> Refinery operations for a synthetic network of 24 process units across 5 Malaysian refinery sites: dynamic tables, a holdout-evaluated upset-risk classifier, a yield-attainment forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile yield attainment, energy intensity and availability from RAW unit data, with checks in `run_core.py`
- **Upset-risk classification** gives a holdout-evaluated next-7-day process-upset probability per unit
- **Yield-attainment forecast** projects 14 days of network-wide attainment with prediction intervals
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live telemetry**: a native simulator (Snowflake only) or IoT Core, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.UNITS` (24 rows) |
| Fact table | `RAW.UNIT_DAILY` (2,160 unit-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `UPSET_CAUSES`, `TREND_ANALYSIS` |
| ML | `ML.UPSET_RISK_SCORES`, `ML.UPSET_RISK_HOLDOUT_METRICS`, `ML.YIELD_FORECAST`, `ML.SETPOINT_DEV_ANOMALIES` |

Sites: Pengerang, Port Dickson, Melaka, Kerteh, Bintulu (Malaysian cities used as regions; refineries, units and operators are fictional).
Unit types: Crude Distillation and Vacuum Distillation (distillation); Catalytic Cracker, Catalytic Reformer and Hydrotreater (conversion and treating).

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Yield Attainment | 93.9% |
| Process Upsets | 151 |
| Energy Intensity | 0.168 GJ/bbl |
| Charge Processed (bbl) | 139,591,245 |
| Unit Availability | 98.9% |
| Process Units Monitored | 24 |
| Critical Spares Coverage | 56.1% |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily yield attainment, product shortfall by root cause, unit table
2. Predictive: holdout metrics, risk bands, 14-day yield-attainment forecast, setpoint deviation anomalies
3. Unit Health: availability, critical spares coverage, PM compliance against yield attainment, then generate the action memo
4. Live IoT: run `CALL APP.SIMULATE_TELEMETRY(20)` (Snowflake only) or `python aws/publish_telemetry.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_ALARM_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- Per-unit yield attainment ranges from 91.9% to 95.7%. Melaka is the lowest site, at 93.1%.
- Charge pump seal failure costs the most target product barrels of the 14 upset causes.
- The risk model is evaluated on a time-based holdout: precision 0.52 and recall 0.44 at 0.5, against a 0.28 base rate. Present it as triage, not a guarantee.
- Site-wide utility power dips are excluded from upset labels, because they are not unit-driven.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
