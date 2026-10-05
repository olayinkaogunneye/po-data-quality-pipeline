-- Staging: give each supplier column its proper type.
-- Rule of thumb: staging converts and renames, it never deletes rows.
select
    supplier_id,
    name                                     as supplier_name,
    country,
    payment_terms,
    try_to_date(created_date, 'YYYY-MM-DD')  as created_date
from {{ source('bronze', 'suppliers_raw') }}
