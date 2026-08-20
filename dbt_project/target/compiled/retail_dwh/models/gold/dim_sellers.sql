select
    to_hex(md5(cast(coalesce(cast(seller_id as string), '_dbt_utils_surrogate_key_null_') as string))) as seller_key,
    seller_id,
    zip_code_prefix,
    city,
    state

from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`csv_sellers`