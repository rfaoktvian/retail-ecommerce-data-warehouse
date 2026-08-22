-- Gold: dim_geography
-- Grain: 1 baris = 1 zip_code_prefix (sudah di-dedup dan di-agregasi di silver)

select
    {{ dbt_utils.generate_surrogate_key(['zip_code_prefix']) }} as geography_key,

    zip_code_prefix,
    city,
    state,
    latitude,
    longitude

from {{ ref('stg_geolocation') }}