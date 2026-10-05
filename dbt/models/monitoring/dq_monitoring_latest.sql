-- The most recent snapshot only: the "current health" view to look at or screenshot.
select *
from {{ ref('dq_run_history') }}
where run_at = (select max(run_at) from {{ ref('dq_run_history') }})
order by table_name, metric
