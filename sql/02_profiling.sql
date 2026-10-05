-- 02_profiling.sql
-- Data profiling of the BRONZE layer (run in Snowsight or the VS Code Snowflake extension).
-- Bronze columns are all VARCHAR, so MIN/MAX below are text comparisons, not numeric ones.

USE DATABASE PO_QUALITY;
CREATE SCHEMA IF NOT EXISTS PROFILING;

-- ============================================================
-- 1. Column-level profile: nulls, distinct counts, min/max
-- ============================================================
CREATE OR REPLACE TABLE PROFILING.COLUMN_PROFILE AS
SELECT 'SUPPLIERS_RAW' AS table_name, 'supplier_id' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(supplier_id IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(supplier_id IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT supplier_id) AS distinct_count,
       MIN(supplier_id) AS min_value,
       MAX(supplier_id) AS max_value
FROM BRONZE.SUPPLIERS_RAW
UNION ALL
SELECT 'SUPPLIERS_RAW' AS table_name, 'name' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(name IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(name IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT name) AS distinct_count,
       MIN(name) AS min_value,
       MAX(name) AS max_value
FROM BRONZE.SUPPLIERS_RAW
UNION ALL
SELECT 'SUPPLIERS_RAW' AS table_name, 'country' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(country IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(country IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT country) AS distinct_count,
       MIN(country) AS min_value,
       MAX(country) AS max_value
FROM BRONZE.SUPPLIERS_RAW
UNION ALL
SELECT 'SUPPLIERS_RAW' AS table_name, 'payment_terms' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(payment_terms IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(payment_terms IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT payment_terms) AS distinct_count,
       MIN(payment_terms) AS min_value,
       MAX(payment_terms) AS max_value
FROM BRONZE.SUPPLIERS_RAW
UNION ALL
SELECT 'SUPPLIERS_RAW' AS table_name, 'created_date' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(created_date IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(created_date IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT created_date) AS distinct_count,
       MIN(created_date) AS min_value,
       MAX(created_date) AS max_value
FROM BRONZE.SUPPLIERS_RAW
UNION ALL
SELECT 'PO_HEADERS_RAW' AS table_name, 'po_id' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(po_id IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(po_id IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT po_id) AS distinct_count,
       MIN(po_id) AS min_value,
       MAX(po_id) AS max_value
FROM BRONZE.PO_HEADERS_RAW
UNION ALL
SELECT 'PO_HEADERS_RAW' AS table_name, 'supplier_id' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(supplier_id IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(supplier_id IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT supplier_id) AS distinct_count,
       MIN(supplier_id) AS min_value,
       MAX(supplier_id) AS max_value
FROM BRONZE.PO_HEADERS_RAW
UNION ALL
SELECT 'PO_HEADERS_RAW' AS table_name, 'order_date' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(order_date IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(order_date IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT order_date) AS distinct_count,
       MIN(order_date) AS min_value,
       MAX(order_date) AS max_value
FROM BRONZE.PO_HEADERS_RAW
UNION ALL
SELECT 'PO_HEADERS_RAW' AS table_name, 'currency' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(currency IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(currency IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT currency) AS distinct_count,
       MIN(currency) AS min_value,
       MAX(currency) AS max_value
FROM BRONZE.PO_HEADERS_RAW
UNION ALL
SELECT 'PO_HEADERS_RAW' AS table_name, 'total_amount' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(total_amount IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(total_amount IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT total_amount) AS distinct_count,
       MIN(total_amount) AS min_value,
       MAX(total_amount) AS max_value
FROM BRONZE.PO_HEADERS_RAW
UNION ALL
SELECT 'PO_ITEMS_RAW' AS table_name, 'po_id' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(po_id IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(po_id IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT po_id) AS distinct_count,
       MIN(po_id) AS min_value,
       MAX(po_id) AS max_value
FROM BRONZE.PO_ITEMS_RAW
UNION ALL
SELECT 'PO_ITEMS_RAW' AS table_name, 'item_no' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(item_no IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(item_no IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT item_no) AS distinct_count,
       MIN(item_no) AS min_value,
       MAX(item_no) AS max_value
FROM BRONZE.PO_ITEMS_RAW
UNION ALL
SELECT 'PO_ITEMS_RAW' AS table_name, 'description' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(description IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(description IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT description) AS distinct_count,
       MIN(description) AS min_value,
       MAX(description) AS max_value
FROM BRONZE.PO_ITEMS_RAW
UNION ALL
SELECT 'PO_ITEMS_RAW' AS table_name, 'quantity' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(quantity IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(quantity IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT quantity) AS distinct_count,
       MIN(quantity) AS min_value,
       MAX(quantity) AS max_value
FROM BRONZE.PO_ITEMS_RAW
UNION ALL
SELECT 'PO_ITEMS_RAW' AS table_name, 'unit_price' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(unit_price IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(unit_price IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT unit_price) AS distinct_count,
       MIN(unit_price) AS min_value,
       MAX(unit_price) AS max_value
FROM BRONZE.PO_ITEMS_RAW
UNION ALL
SELECT 'PO_ITEMS_RAW' AS table_name, 'delivery_date' AS column_name,
       COUNT(*) AS total_rows,
       COUNT_IF(delivery_date IS NULL) AS null_count,
       ROUND(100 * COUNT_IF(delivery_date IS NULL) / COUNT(*), 2) AS null_pct,
       COUNT(DISTINCT delivery_date) AS distinct_count,
       MIN(delivery_date) AS min_value,
       MAX(delivery_date) AS max_value
FROM BRONZE.PO_ITEMS_RAW;

SELECT * FROM PROFILING.COLUMN_PROFILE ORDER BY table_name, column_name;

-- ============================================================
-- 2. Pattern and consistency checks (saved as a table)
-- ============================================================
CREATE OR REPLACE TABLE PROFILING.PATTERN_CHECKS AS
SELECT 'suppliers' AS table_name, 'duplicate supplier_id' AS check_name,
       COUNT(*) - COUNT(DISTINCT supplier_id) AS failing_rows
FROM BRONZE.SUPPLIERS_RAW

UNION ALL
SELECT 'po_headers', 'duplicate po_id rows',
       COUNT(*) - COUNT(DISTINCT po_id)
FROM BRONZE.PO_HEADERS_RAW

UNION ALL
SELECT 'po_headers', 'order_date not in YYYY-MM-DD format',
       COUNT_IF(order_date IS NOT NULL AND NOT REGEXP_LIKE(order_date, '[0-9]{4}-[0-9]{2}-[0-9]{2}'))
FROM BRONZE.PO_HEADERS_RAW

UNION ALL
SELECT 'po_headers', 'currency is NULL',
       COUNT_IF(currency IS NULL)
FROM BRONZE.PO_HEADERS_RAW

UNION ALL
SELECT 'po_headers', 'currency not in (EUR, USD)',
       COUNT_IF(currency IS NOT NULL AND currency NOT IN ('EUR', 'USD'))
FROM BRONZE.PO_HEADERS_RAW

UNION ALL
SELECT 'po_headers', 'supplier_id not found in suppliers',
       COUNT_IF(s.supplier_id IS NULL)
FROM BRONZE.PO_HEADERS_RAW h
LEFT JOIN BRONZE.SUPPLIERS_RAW s ON h.supplier_id = s.supplier_id

UNION ALL
SELECT 'po_headers', 'total_amount not numeric',
       COUNT_IF(total_amount IS NOT NULL AND TRY_TO_DOUBLE(total_amount) IS NULL)
FROM BRONZE.PO_HEADERS_RAW

UNION ALL
SELECT 'po_items', 'description is NULL',
       COUNT_IF(description IS NULL)
FROM BRONZE.PO_ITEMS_RAW

UNION ALL
SELECT 'po_items', 'quantity is NULL',
       COUNT_IF(quantity IS NULL)
FROM BRONZE.PO_ITEMS_RAW

UNION ALL
SELECT 'po_items', 'quantity or unit_price not numeric, or not positive',
       COUNT_IF(TRY_TO_DOUBLE(quantity) <= 0 OR TRY_TO_DOUBLE(unit_price) <= 0
                OR (quantity IS NOT NULL AND TRY_TO_DOUBLE(quantity) IS NULL)
                OR (unit_price IS NOT NULL AND TRY_TO_DOUBLE(unit_price) IS NULL))
FROM BRONZE.PO_ITEMS_RAW

UNION ALL
SELECT 'po_items', 'delivery_date earlier than order_date',
       COUNT(DISTINCT i.po_id || '|' || i.item_no)
FROM BRONZE.PO_ITEMS_RAW i
JOIN BRONZE.PO_HEADERS_RAW h ON i.po_id = h.po_id
WHERE TRY_TO_DATE(i.delivery_date) < TRY_TO_DATE(h.order_date);

SELECT * FROM PROFILING.PATTERN_CHECKS ORDER BY table_name, check_name;

-- ============================================================
-- 3. Distributions (explore, no table saved)
-- ============================================================
-- Currency values
SELECT currency, COUNT(*) AS n FROM BRONZE.PO_HEADERS_RAW GROUP BY currency ORDER BY n DESC;

-- Numeric spread of quantity and unit_price: look at how far max sits from p99
SELECT 'quantity' AS col,
       MIN(q) AS min_v,
       PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY q) AS p50,
       PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY q) AS p95,
       PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY q) AS p99,
       MAX(q) AS max_v
FROM (SELECT TRY_TO_DOUBLE(quantity) AS q FROM BRONZE.PO_ITEMS_RAW)
UNION ALL
SELECT 'unit_price',
       MIN(p),
       PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY p),
       PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY p),
       PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY p),
       MAX(p)
FROM (SELECT TRY_TO_DOUBLE(unit_price) AS p FROM BRONZE.PO_ITEMS_RAW);