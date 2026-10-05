-- Singular test: returns every PO line whose delivery date is earlier than its order date.
-- A test passes when it returns zero rows; every row returned is a failure.
select
    i.po_id,
    i.item_no,
    h.order_date,
    i.delivery_date
from {{ ref('stg_po_items') }} i
join {{ ref('stg_po_headers') }} h
    on i.po_id = h.po_id
where i.delivery_date < h.order_date
