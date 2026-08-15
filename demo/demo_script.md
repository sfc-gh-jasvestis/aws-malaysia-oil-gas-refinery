# Demo Script: Refinery Operations Intelligence
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake ingests 2M sensor readings per day from 24 process units — ML.ANOMALY_DETECTION catches process excursions before safety shutdowns, Dynamic Tables compute unit availability, and Cortex Agent answers operational questions in natural language"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Encik Razali bin Hassan** | Plant Manager | React App (SPCS) | Unit availability, safety incidents, throughput economics, maintenance backlog |
| **Eng. Liew Kok Wai** | Process Engineer | Amazon QuickSight | Process excursions, sensor drift, root cause analysis, corrective actions |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 6 tables | PROCESS_UNITS (24), SENSOR_READINGS (2000000), ALARM_HISTORY (5000), MAINTENANCE_LOG (3000), OPERATIONS_DOCS (80), REFINERY_ECONOMICS (365) |
| **CURATED** | 4 Dynamic Tables | UNIT_AVAILABILITY, SENSOR_TIMESERIES, ALARM_SUMMARY, THROUGHPUT_ECONOMICS |
| **ML** | ML.ANOMALY_DETECTION + ML.FORECAST | Forecasting + anomaly detection |
| **AI** | SUMMARIZE, AI_CLASSIFY | Classification + extraction |
| **Search** | Cortex Search | 80 documents indexed |
| **Agent** | REFINERY_OPERATIONS_AGENT | Semantic View + Search tools |


---

## The Story

Malaysia's Pengerang Integrated Complex is one of Asia's largest refining hubs, processing 300,000 bbl/d. An alarm spike across 24 process units signals a potential catalyst deactivation event in the reformer — but with 2M sensor readings per day, finding the root cause requires AI that understands process engineering context.

---

## Script

### [0:00–0:45] PLANT OVERVIEW

**Show**: Plant Overview tab

> "Twenty-four process units monitored in real-time — CDU, VDU, FCC, reformers, hydrotreaters."

**Action**: Point at the 98.2% availability KPI

### [0:45–1:30] ANOMALY DETECTION

**Show**: Anomaly Detection tab

> "ML.ANOMALY_DETECTION running on all 24 units — catches process excursions before safety systems trip."

**Action**: Click Unit 7 in the process unit list

### [1:30–2:15] THROUGHPUT ECONOMICS

**Show**: Throughput Economics tab

> "RM 1.8 billion monthly throughput value at risk if availability drops."

**Action**: Point at RM 1.8B monthly value KPI

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Encik Razali asks: 'Which units triggered alarms in the last 48 hours?'"

**Action**: Type: 'Which units have alarms in last 48 hours?'

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Seven Snowflake capabilities, six AWS services."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **ML.ANOMALY_DETECTION on refinery process data** — Only demo using anomaly detection for refinery process excursions — not financial or yield data
2. **2M sensor readings/day via Snowpipe Streaming** — Only demo showing real-time IoT ingestion at refinery scale
3. **Digital twin concept via React Canvas** — Only demo visualizing process unit topology with real-time status
4. **Malaysian downstream O&G context** — Pengerang complex, PETRONAS Chemicals, Malaysian refinery terminology
5. **Operations docs searchable via Cortex Search** — SOPs, safety bulletins, turnaround reports indexed for instant retrieval
6. **AWS IoT Core + TwinMaker integration** — Only demo combining IoT sensor streaming with digital twin visualization


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM OIL_GAS_REFINERY.RAW.SENSOR_READINGS` → 2000000
- [ ] `SELECT COUNT(*) FROM OIL_GAS_REFINERY.RAW.ALARM_HISTORY` → 5000
- [ ] `SELECT COUNT(*) FROM OIL_GAS_REFINERY.CURATED.UNIT_AVAILABILITY WHERE AVAILABILITY_PCT < 0.95` → >=1

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM OIL_GAS_REFINERY.ML.PROCESS_EXCURSION_RESULTS` → >0
- [ ] `SELECT SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) FROM OIL_GAS_REFINERY.ML.PROCESS_EXCURSION_RESULTS WHERE SERIES = 'UNIT-07'` → >=3

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM OIL_GAS_REFINERY.AI.ALARM_CLASSIFICATION WHERE ROOT_CAUSE_CATEGORY = 'CATALYST_DEACTIVATION'` → >=2

