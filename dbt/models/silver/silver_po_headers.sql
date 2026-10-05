-- Silver headers: typed, one row per PO, and no PO that failed a validation rule.
select po_id, supplier_id, order_date, currency, total_amount
from {{ ref('stg_po_headers') }}
where po_id not in (
    select record_id
    from {{ ref('quarantine_po_headers') }}
    where rule_name <> 'duplicate_po_id'
)
qualify row_number() over (partition by po_id order by order_date) = 1
