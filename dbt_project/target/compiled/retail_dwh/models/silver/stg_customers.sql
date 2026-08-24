-- Silver: customers
-- Cleaning: standardisasi casing city/state, buang baris tanpa customer_id

select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix as zip_code_prefix,
    lower(trim(customer_city)) as city,
    upper(trim(customer_state)) as state,
    dwh_extracted_at,
    dwh_source_system

from `qwiklabs-gcp-03-018d48a9d681`.`bronze`.`postgres_customers`
where customer_id is not null