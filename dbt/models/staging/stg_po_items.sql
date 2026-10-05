-- Staging: type the line-item columns, keeping the raw delivery date for diagnosis.
select
    po_id,
    try_to_number(item_no)                    as item_no,
    description,
    try_to_number(quantity)                   as quantity,
    try_to_decimal(unit_price, 18, 2)         as unit_price,
    delivery_date                             as delivery_date_raw,
    try_to_date(delivery_date, 'YYYY-MM-DD')  as delivery_date
from {{ source('bronze', 'po_items_raw') }}
