-- DuckDB takes decimal(12, 2); BigQuery's equivalent is NUMERIC.
{% macro money_type() -%}
    {{ 'numeric' if target.type == 'bigquery' else 'decimal(12, 2)' }}
{%- endmacro %}

{% macro rate_type() -%}
    {{ 'numeric' if target.type == 'bigquery' else 'decimal(5, 2)' }}
{%- endmacro %}
