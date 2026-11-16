-- https://docs.getdbt.com/docs/building-a-dbt-project/building-models/using-custom-database/
-- A custom database (GCP project) is honoured only on prod targets; everything else
-- builds in the target's own project.
{% macro generate_database_name(custom_database_name=none, node=none) -%}
    {%- set default_database = target.database -%}

    {%- if custom_database_name is none or "prod" not in target.name -%}
        {{ default_database }}
    {%- else -%}
        {{ custom_database_name | trim }}
    {%- endif -%}

{%- endmacro %}
