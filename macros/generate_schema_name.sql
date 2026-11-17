{#
    prod: nodes land in their custom schema as-is (staging, marts, snapshots);
          nodes without one (e.g. UDFs) land in the target's dataset.
    any other target (dev, cloud, dbt Cloud IDE/CI, ...): everything lands in the
          target's own single dataset (e.g. dbt_dev), so non-prod runs never touch
          prod and each environment is one dataset.
    Sources are unaffected: they point at the raw datasets explicitly.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is not none and target.name == 'prod' -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ target.schema }}
    {%- endif -%}
{%- endmacro %}
