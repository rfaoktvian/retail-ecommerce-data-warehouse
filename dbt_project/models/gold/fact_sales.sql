-- Grain: 1 baris = 1 order_item (produk spesifik dalam 1 order)
--
-- CATATAN PENTING (hasil data profiling): ~775 order di source TIDAK punya order_item
-- sama sekali (dominan berstatus unavailable/canceled/created — order yang gagal
-- diproses sebelum ada item terkonfirmasi). Order-order ini TIDAK AKAN muncul di
-- fact_sales karena grain-nya per order_item, bukan per order. Ini WAJAR, bukan bug —
-- tidak ada order berstatus 'delivered' yang hilang. Kalau butuh analisis funnel/
-- conversion (termasuk order yang gagal), pakai postgres_orders langsung, bukan
-- fact_sales.

select
    {{ dbt_utils.generate_surrogate_key(['oi.order_id', 'oi.order_item_id']) }} as sales_key,

    dc.customer_key,
    dp.product_key,
    ds.seller_key,
    dd.date_key as order_date_key,

    oi.order_id,
    oi.order_item_id,
    o.order_status,
    oi.price,
    oi.freight_value,
    oi.price + oi.freight_value as total_amount

from {{ ref('postgres_order_items') }} oi
left join {{ ref('postgres_orders') }} o
    on oi.order_id = o.order_id
left join {{ ref('dim_customers') }} dc
    on o.customer_id = dc.customer_id
left join {{ ref('dim_products') }} dp
    on oi.product_id = dp.product_id
left join {{ ref('dim_sellers') }} ds
    on oi.seller_id = ds.seller_id
left join {{ ref('dim_date') }} dd
    on cast(o.order_date as date) = dd.full_date