-- Quarantine for PO lines. record_id is "po_id|item_no".
-- Every staging row must end up either in silver or here, so lines whose parent PO
-- was quarantined are logged too (rule parent_po_quarantined) instead of silently vanishing.
with items as (
    select *, po_id || '|' || item_no::varchar as record_id
    from {{ ref('stg_po_items') }}
),

po_dates as (
    -- distinct, because duplicated header rows would otherwise double-count lines
    select distinct po_id, order_date
    from {{ ref('stg_po_headers') }}
),

bad_pos as (
    -- duplicate copies are harmless: the PO itself is fine and survives in silver
    select distinct record_id as po_id
    from {{ ref('quarantine_po_headers') }}
    where rule_name <> 'duplicate_po_id'
)

select 'po_items' as table_name, record_id,
       'missing_description' as rule_name, 'description is NULL' as reason
from items
where description is null

union all
select 'po_items', record_id, 'missing_quantity', 'quantity is NULL'
from items
where quantity is null

union all
select 'po_items', i.record_id, 'delivery_before_order',
       'delivery_date ' || i.delivery_date::varchar || ' is before order_date ' || d.order_date::varchar
from items i
join po_dates d on i.po_id = d.po_id
where i.delivery_date < d.order_date

union all
select 'po_items', i.record_id, 'orphan_po', 'po_id not found in PO headers'
from items i
left join po_dates d on i.po_id = d.po_id
where d.po_id is null

union all
select 'po_items', i.record_id, 'parent_po_quarantined', 'the parent PO failed validation'
from items i
join bad_pos b on i.po_id = b.po_id
