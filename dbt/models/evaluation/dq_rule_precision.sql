-- PRECISION: when a rule quarantines something, was it really one of our injected problems?
-- not_in_log > 0 would mean a rule is flagging rows we never corrupted (false alarms or real generator quirks).
-- parent_po_quarantined is excluded: it is a consequence of other rules, not a rule of its own.
with quarantined as (
    select record_id, rule_name from {{ ref('quarantine_po_headers') }}
    union all
    select record_id, rule_name from {{ ref('quarantine_po_items') }}
),

injected as (
    select record_id, issue_type
    from {{ source('bronze', 'corruption_log') }}
)

select
    q.rule_name,
    count(*) as quarantined,
    count_if(i.record_id is not null) as matches_injected_issue,
    count(*) - count_if(i.record_id is not null) as not_in_log
from quarantined q
join {{ ref('eval_issue_rule_map') }} m on q.rule_name = m.rule_name
left join injected i on q.record_id = i.record_id and i.issue_type = m.issue_type
group by q.rule_name
order by q.rule_name
