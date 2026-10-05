-- Silver lines: typed, and not quarantined for any reason.
select po_id, item_no, description, quantity, unit_price, delivery_date
from {{ ref('stg_po_items') }}
where (po_id || '|' || item_no::varchar) not in (
    select record_id from {{ ref('quarantine_po_items') }}
)
