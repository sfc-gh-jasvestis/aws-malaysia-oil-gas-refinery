-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Refinery Operations Intelligence
-- ============================================================================
USE DATABASE OIL_GAS_REFINERY;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.REFINERY_OPERATIONS_AGENT
  COMMENT = 'Refinery Operations Intelligence AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'OIL_GAS_REFINERY.APP.REFINERY_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'OIL_GAS_REFINERY.SEARCH.OPERATIONS_DOCS_SEARCH', TOOL_DESCRIPTION => 'Search documents for Oil & Gas — Downstream Refining information')
  )
  SYSTEM_PROMPT = 'You are the Refinery Operations Agent for a 300,000 bbl/d refinery complex in Malaysia, monitoring 24 process units across the Pengerang Integrated Complex.';
