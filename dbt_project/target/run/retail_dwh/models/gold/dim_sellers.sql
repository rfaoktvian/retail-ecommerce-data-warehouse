
  
    

    create or replace table `qwiklabs-gcp-03-018d48a9d681`.`gold`.`dim_sellers`
      
    
    

    
    OPTIONS()
    as (
      -- Gold: dim_sellers
-- Grain: 1 baris = 1 seller_id
-- Enrich: join ke stg_geolocation untuk koordinat lat/lng seller (berguna untuk peta distribusi seller)

select
    to_hex(md5(cast(coalesce(cast(s.seller_id as string), '_dbt_utils_surrogate_key_null_') as string))) as seller_key,

    s.seller_id,
    s.zip_code_prefix,
    s.city,
    s.state,

    -- Koordinat dari geolocation (berguna untuk peta distribusi seller)
    g.latitude  as seller_latitude,
    g.longitude as seller_longitude

from `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_sellers` s
left join `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_geolocation` g
    on s.zip_code_prefix = g.zip_code_prefix
    );
  