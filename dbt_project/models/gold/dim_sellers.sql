-- Gold: dim_sellers
-- Grain: 1 baris = 1 seller_id
-- Enrich: join ke stg_geolocation untuk koordinat lat/lng seller (berguna untuk peta distribusi seller)

select
    {{ dbt_utils.generate_surrogate_key(['s.seller_id']) }} as seller_key,

    s.seller_id,
    s.zip_code_prefix,
    s.city,
    s.state,

    -- Koordinat dari geolocation (berguna untuk peta distribusi seller)
    g.latitude  as seller_latitude,
    g.longitude as seller_longitude

from {{ ref('stg_sellers') }} s
left join {{ ref('stg_geolocation') }} g
    on s.zip_code_prefix = g.zip_code_prefix