{% macro generate_schema_name(custom_schema_name, node) -%}
    {#-
        Default dbt akan gabungkan target.schema + custom_schema_name,
        misal jadi "dev_silver". Kita override supaya persis "silver"/"gold"
        saja, sesuai dataset yang sudah dibuat lewat setup_bigquery.py.
    -#}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}