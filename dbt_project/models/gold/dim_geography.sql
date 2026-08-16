select
    {{ dbt_utils.generate_surrogate_key(['zip_code_prefix']) }} as geography_key,
    zip_code_prefix,
    latitude,
    longitude,
    city,
    state

from {{ ref('csv_geolocation') }}