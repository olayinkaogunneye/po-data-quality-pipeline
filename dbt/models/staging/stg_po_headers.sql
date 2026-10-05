-- Staging: type the header columns.
-- try_* functions return NULL instead of failing when a value cannot be converted,
-- so bad rows stay visible. The raw date is kept so we can tell "missing" from "wrong format".
select
    po_id,
    supplier_id,
    order_date                                as order_date_raw,
    try_to_date(order_date, 'YYYY-MM-DD')     as order_date,
    upper(trim(currency))                     as currency,
    try_to_decimal(total_amount, 18, 2)       as total_amount
from {{ source('bronze', 'po_headers_raw') }}
