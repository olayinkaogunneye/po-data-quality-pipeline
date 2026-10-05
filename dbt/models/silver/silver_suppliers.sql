-- No rule-based supplier problems to remove yet (name variants need a fuzzy check later).
select supplier_id, supplier_name, country, payment_terms, created_date
from {{ ref('stg_suppliers') }}
