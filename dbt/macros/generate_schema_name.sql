{# Use the schema names exactly as configured (SILVER, QUARANTINE, GOLD)
   instead of dbt's default "<target_schema>_<custom_schema>" naming. #}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
