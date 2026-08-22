-- Gold: dim_customers
-- Grain: 1 baris = 1 customer_id (transaksi-level, bukan customer unik)
-- Enrich: join ke stg_geolocation untuk koordinat lat/lng customer (berguna untuk peta distribusi)
-- Note: customer_unique_id adalah ID pelanggan sesungguhnya (1 pelanggan bisa punya
--       banyak customer_id kalau belanja lebih dari 1x dari device berbeda)

select
    {{ dbt_utils.generate_surrogate_key(['c.customer_id']) }} as customer_key,

    c.customer_id,
    c.customer_unique_id,
    c.zip_code_prefix,
    c.city,
    c.state,

    -- Koordinat dari geolocation (berguna untuk peta distribusi customer)
    g.latitude  as customer_latitude,
    g.longitude as customer_longitude

from {{ ref('stg_customers') }} c
left join {{ ref('stg_geolocation') }} g
    on c.zip_code_prefix = g.zip_code_prefix
