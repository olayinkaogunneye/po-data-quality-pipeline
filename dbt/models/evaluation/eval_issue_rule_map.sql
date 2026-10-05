-- Which quarantine rule is supposed to catch which injected issue type.
-- Issue types that no rule covers (near duplicates, name variants, outliers) are left out on purpose.
select * from (values
    ('missing_currency',       'missing_currency'),
    ('invalid_currency',       'invalid_currency'),
    ('bad_date_format',        'bad_date_format'),
    ('orphan_supplier',        'orphan_supplier'),
    ('exact_duplicate_header', 'duplicate_po_id'),
    ('delivery_before_order',  'delivery_before_order'),
    ('missing_item_field',     'missing_description'),
    ('missing_item_field',     'missing_quantity')
) as t(issue_type, rule_name)
