-- Silver: sellers
-- Cleaning: standardisasi casing city/state, sama pola dengan customers

select
    seller_id,
    cast(seller_zip_code_prefix as string) as zip_code_prefix,
    lower(trim(seller_city)) as city,
    upper(trim(seller_state)) as state,
    dwh_extracted_at,
    dwh_source_system

from `qwiklabs-gcp-03-018d48a9d681`.`bronze`.`csv_sellers`
where seller_id is not null