{{ config(materialized='incremental') }}
-- Monitoring: a snapshot of pipeline health that is APPENDED every time this model runs,
-- so you can watch row counts and failure rates change from run to run.
-- Use `dbt run --select dq_run_history --full-refresh` to wipe the history and start again.
with metrics as (

    select 'po_headers' as table_name, 'rows_in_staging' as metric, count(*) as value
    from {{ ref('stg_po_headers') }}
    union all
    select 'po_headers', 'rows_in_silver', count(*) from {{ ref('silver_po_headers') }}

    union all
    select 'po_items', 'rows_in_staging', count(*) from {{ ref('stg_po_items') }}
    union all
    select 'po_items', 'rows_in_silver', count(*) from {{ ref('silver_po_items') }}

    union all
    select 'suppliers', 'rows_in_staging', count(*) from {{ ref('stg_suppliers') }}
    union all
    select 'suppliers', 'rows_in_silver', count(*) from {{ ref('silver_suppliers') }}

    -- one metric per quarantine rule, e.g. quarantined_by_missing_currency
    union all
    select table_name, 'quarantined_by_' || rule_name, count(*)
    from {{ ref('quarantine_po_headers') }}
    group by table_name, rule_name

    union all
    select table_name, 'quarantined_by_' || rule_name, count(*)
    from {{ ref('quarantine_po_items') }}
    group by table_name, rule_name

)

select
    current_timestamp() as run_at,
    table_name,
    metric,
    value,
    round(
        100 * value / nullif(max(case when metric = 'rows_in_staging' then value end)
                             over (partition by table_name), 0),
        2
    ) as pct_of_staging
from metrics
