# Refinery Operations Intelligence

**Malaysia - Oil & Gas — Downstream Refining**
Use case: Refinery Operations Monitoring

> Real-time monitoring of Malaysia's refinery operations — IoT sensors stream process data, ML.ANOMALY_DETECTION catches excursions, and React Canvas visualizes the refinery digital twin.

## Why Snowflake

Snowflake ingests 2M sensor readings per day from 24 process units — ML.ANOMALY_DETECTION catches process excursions before safety shutdowns, Dynamic Tables compute unit availability, and Cortex Agent answers operational questions in natural language

- **ML.ANOMALY_DETECTION on refinery process data** - Only demo using anomaly detection for refinery process excursions — not financial or yield data
- **2M sensor readings/day via Snowpipe Streaming** - Only demo showing real-time IoT ingestion at refinery scale
- **Digital twin concept via React Canvas** - Only demo visualizing process unit topology with real-time status
- **Malaysian downstream O&G context** - Pengerang complex, PETRONAS Chemicals, Malaysian refinery terminology
- **Operations docs searchable via Cortex Search** - SOPs, safety bulletins, turnaround reports indexed for instant retrieval
- **AWS IoT Core + TwinMaker integration** - Only demo combining IoT sensor streaming with digital twin visualization

## What is deployed

| | |
|---|---|
| Database | `MY_OIL_GAS_REFINERY` |
| Service | `MY_OIL_GAS_REFINERY_APP` |
| Compute pool | `SEA_DEMOS_MALAYSIA_POOL` |
| Dimension table | `RAW.PROCESS_UNITS` (20 rows) |
| Fact table | `RAW.SENSOR_READINGS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | MYR (RM) |

Regions in play: Selangor, Johor, Penang, Sabah, Sarawak
Segments: Crude Distillation, Hydrocracker, Reformer, Blending

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh MY_OIL_GAS_REFINERY
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Throughput | `242K bpd` | total across Process Units |
| Solomon EII | `94.2` | average per event |
| Unplanned Downtime | `0.8%` | average per event |
| Product Yield | `87%` | average per event |
| Margin Optimization | `+RM 2.4M/day` | average per event |
| Energy Index | `92` | average per event |
| Hydrogen Balance | `98%` | average per event |


## Demo flow

1. Plant Overview
2. Anomaly Detection
3. Throughput Economics
4. Ask AI
5. Architecture & Data

## Talking points

- **24 process units** - monitored in real-time across the refinery complex
- **2M sensor readings/day** - ingested via Snowpipe Streaming from DCS/SCADA
- **42 alarms** - in the last 48 hours (6 HIGH severity)
- **98.2% unit availability** - overall — Unit 7 dropped to 91%
- **RM 1.8B** - monthly throughput value at risk
- **3 excursions** - detected by ML.ANOMALY_DETECTION in 48 hours
- **80 operations docs** - indexed and searchable via Cortex Search

## Business impact

- Malaysia's refining capacity reached 796,500 bbl/d with Pengerang as the flagship complex (EIA)
- Unplanned refinery shutdowns cost $1-5M per day in lost production and restart costs (Solomon Associates)
- AI-enabled process monitoring reduces unplanned downtime by 30-50% in refining (McKinsey Chemicals)
- Real-time data platforms enable predictive maintenance saving 8-12% on maintenance costs (Deloitte Industry 4.0)

---
Generated from `generator/demo_specs/aws-malaysia-oil-gas-refinery.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-malaysia-oil-gas-refinery` instead.
