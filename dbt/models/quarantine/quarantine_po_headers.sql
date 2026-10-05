-- Quarantine: one row per (PO, rule it broke), with a human-readable reason.
-- Rules run on the first copy of each PO; extra copies are logged as duplicates.
with headers as (
    select
        *,
        row_number() over (partition by po_id order by order_date_raw, supplier_id) as copy_no
    from {{ ref('stg_po_headers') }}
),

known_suppliers as (
    select supplier_id from {{ ref('stg_suppliers') }}
)

select 'po_headers' as table_name, po_id as record_id,
       'duplicate_po_id' as rule_name,
       'Extra copy of a PO that already exists' as reason
from headers
where copy_no > 1

union all
select 'po_headers', po_id, 'missing_currency', 'currency is NULL'
from headers
where copy_no = 1 and currency is null

union all
select 'po_headers', po_id, 'invalid_currency', 'currency is not EUR or USD: ' || currency
from headers
where copy_no = 1 and currency is not null and currency not in ('EUR', 'USD')

union all
select 'po_headers', po_id, 'bad_date_format', 'order_date is not a valid YYYY-MM-DD date: ' || order_date_raw
from headers
where copy_no = 1 and order_date is null and order_date_raw is not null

union all
select 'po_headers', po_id, 'missing_order_date', 'order_date is NULL'
from headers
where copy_no = 1 and order_date_raw is null

union all
select 'po_headers', h.po_id, 'orphan_supplier', 'supplier_id not found in suppliers: ' || h.supplier_id
from headers h
left join known_suppliers s on h.supplier_id = s.supplier_id
where h.copy_no = 1 and h.supplier_id is not null and s.supplier_id is null
