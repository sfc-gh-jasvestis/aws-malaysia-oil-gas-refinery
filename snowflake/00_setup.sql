-- Generated from generator/demo_specs/aws-malaysia-oil-gas-refinery.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-malaysia-oil-gas-refinery
-- This is the schema that is actually deployed for MY_OIL_GAS_REFINERY.

-- MY_OIL_GAS_REFINERY  (Refinery Operations Intelligence)
-- generated from generator/demo_specs/aws-malaysia-oil-gas-refinery.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS MY_OIL_GAS_REFINERY;
CREATE SCHEMA IF NOT EXISTS MY_OIL_GAS_REFINERY.RAW;
CREATE SCHEMA IF NOT EXISTS MY_OIL_GAS_REFINERY.CURATED;
CREATE SCHEMA IF NOT EXISTS MY_OIL_GAS_REFINERY.APP;
USE DATABASE MY_OIL_GAS_REFINERY;

-- 5 real regions; entity names carry their region so the two always agree
