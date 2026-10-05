-- Snowflake bronze layer setup for the PO data quality project
-- Run in a Snowsight worksheet.

CREATE DATABASE IF NOT EXISTS PO_QUALITY;
USE DATABASE PO_QUALITY;

CREATE SCHEMA IF NOT EXISTS BRONZE;      -- raw, untouched
CREATE SCHEMA IF NOT EXISTS SILVER;      -- validated
CREATE SCHEMA IF NOT EXISTS QUARANTINE;  -- rejected rows + reasons
CREATE SCHEMA IF NOT EXISTS GOLD;        -- curated / enriched
USE SCHEMA BRONZE;

-- Bronze tables are all VARCHAR on purpose: bad dates, "EURO" currencies and
-- NULLs must load without failing. Typing and validation happen in SILVER.
CREATE OR REPLACE TABLE SUPPLIERS_RAW (
  supplier_id VARCHAR, name VARCHAR, country VARCHAR,
  payment_terms VARCHAR, created_date VARCHAR
);
CREATE OR REPLACE TABLE PO_HEADERS_RAW (
  po_id VARCHAR, supplier_id VARCHAR, order_date VARCHAR,
  currency VARCHAR, total_amount VARCHAR
);
CREATE OR REPLACE TABLE PO_ITEMS_RAW (
  po_id VARCHAR, item_no VARCHAR, description VARCHAR,
  quantity VARCHAR, unit_price VARCHAR, delivery_date VARCHAR
);
-- Evaluation-only tables (not part of the pipeline input)
CREATE OR REPLACE TABLE GROUND_TRUTH_CATEGORIES (po_id VARCHAR, item_no VARCHAR, true_category VARCHAR);
CREATE OR REPLACE TABLE CORRUPTION_LOG (
  table_name VARCHAR, record_id VARCHAR, issue_type VARCHAR, detail VARCHAR, ml_target VARCHAR
);

CREATE OR REPLACE FILE FORMAT CSV_FMT
  TYPE = CSV
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  EMPTY_FIELD_AS_NULL = TRUE;

CREATE OR REPLACE STAGE PO_STAGE FILE_FORMAT = CSV_FMT;

-- Upload the 5 CSV files to the stage, either:
--  (a) Snowsight: Data > Databases > PO_QUALITY > BRONZE > Stages > PO_STAGE > "+ Files"
--  (b) SnowSQL / CLI:  PUT file:///path/to/output/*.csv @PO_STAGE AUTO_COMPRESS=TRUE;

COPY INTO SUPPLIERS_RAW           FROM @PO_STAGE/suppliers.csv.gz;
COPY INTO PO_HEADERS_RAW          FROM @PO_STAGE/po_headers.csv.gz;
COPY INTO PO_ITEMS_RAW            FROM @PO_STAGE/po_items.csv.gz;
COPY INTO GROUND_TRUTH_CATEGORIES FROM @PO_STAGE/ground_truth_categories.csv.gz;
COPY INTO CORRUPTION_LOG          FROM @PO_STAGE/corruption_log.csv.gz;

-- Sanity check: expect ~23 / ~2020 / ~6017 rows
SELECT 'suppliers' t, COUNT(*) n FROM SUPPLIERS_RAW
UNION ALL SELECT 'po_headers', COUNT(*) FROM PO_HEADERS_RAW
UNION ALL SELECT 'po_items',   COUNT(*) FROM PO_ITEMS_RAW;

-- First profiling query (null rates for headers)
SELECT
  COUNT(*)                                   AS total_rows,
  COUNT_IF(currency IS NULL)                 AS null_currency,
  COUNT(DISTINCT po_id)                      AS distinct_po_ids,
  COUNT(*) - COUNT(DISTINCT po_id)           AS duplicate_po_rows,
  COUNT_IF(TRY_TO_DATE(order_date) IS NULL)  AS unparseable_order_dates
FROM PO_HEADERS_RAW;
