-- RECALL: of the problems we injected, how many did the rules catch?
-- One row per injected issue type, scored against the corruption log (the answer key).
with injected as (
    select record_id, issue_type, ml_target
    from {{ source('bronze', 'corruption_log') }}
),

quarantined as (
    select record_id, rule_name from {{ ref('quarantine_po_headers') }}
    union all
    select record_id, rule_name from {{ ref('quarantine_po_items') }}
),

per_record as (
    select
        i.issue_type,
        i.record_id,
        i.ml_target,
        max(case when q.record_id is not null then 1 else 0 end) as caught
    from injected i
    left join {{ ref('eval_issue_rule_map') }} m on i.issue_type = m.issue_type
    left join quarantined q on i.record_id = q.record_id and q.rule_name = m.rule_name
    group by i.issue_type, i.record_id, i.ml_target
)

select
    issue_type,
    case
        when max(ml_target) = 'True' then 'ML anomaly detection'
        when issue_type in ('near_duplicate_po', 'inconsistent_supplier_name') then 'Fuzzy matching (not built yet)'
        else 'Rule-based validation'
    end as intended_method,
    count(*) as injected,
    sum(caught) as caught_by_rules,
    round(100 * sum(caught) / count(*), 1) as recall_pct
from per_record
group by issue_type
order by issue_type
