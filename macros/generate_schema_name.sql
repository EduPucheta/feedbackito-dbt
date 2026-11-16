{#
    prod: models land in their custom schema as-is (e.g. `public`, `snapshots`).
    any other target (dev, cloud, ...): prefixed with the target's own dataset
    (e.g. `dbt_dev_public`), so non-prod runs never overwrite prod tables.
    Sources are unaffected: they point at the raw datasets explicitly.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- elif target.name == 'prod' -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
