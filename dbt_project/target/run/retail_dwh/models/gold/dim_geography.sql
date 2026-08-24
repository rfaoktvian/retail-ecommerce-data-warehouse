
  
    

    create or replace table `qwiklabs-gcp-03-018d48a9d681`.`gold`.`dim_geography`
      
    
    

    
    OPTIONS()
    as (
      -- Gold: dim_geography
-- Grain: 1 baris = 1 zip_code_prefix (sudah di-dedup dan di-agregasi di silver)

select
    to_hex(md5(cast(coalesce(cast(zip_code_prefix as string), '_dbt_utils_surrogate_key_null_') as string))) as geography_key,

    zip_code_prefix,
    city,
    state,
    latitude,
    longitude

from `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_geolocation`
    );
  