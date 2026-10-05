{{ config(severity='error') }}
-- Silver must contain no line delivered before its order date.
select i.po_id, i.item_no, h.order_date, i.delivery_date
from {{ ref('silver_po_items') }} i
join {{ ref('silver_po_headers') }} h on i.po_id = h.po_id
where i.delivery_date < h.order_date
