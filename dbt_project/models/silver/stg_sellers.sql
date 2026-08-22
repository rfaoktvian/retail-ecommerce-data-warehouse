-- Silver: sellers
-- Cleaning: standardisasi casing city/state, sama pola dengan customers

select
    seller_id,
    seller_zip_code_prefix as zip_code_prefix,
    lower(trim(seller_city)) as city,
    upper(trim(seller_state)) as state,
    dwh_extracted_at,
    dwh_source_system

from {{ source('bronze', 'csv_sellers') }}
where seller_id is not null