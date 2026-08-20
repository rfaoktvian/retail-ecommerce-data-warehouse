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
    to_hex(md5(cast(coalesce(cast(oi.order_id as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(oi.order_item_id as string), '_dbt_utils_surrogate_key_null_') as string))) as sales_key,

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

from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`postgres_order_items` oi
left join `qwiklabs-gcp-04-05c5517686d1`.`silver`.`postgres_orders` o
    on oi.order_id = o.order_id
left join `qwiklabs-gcp-04-05c5517686d1`.`gold`.`dim_customer` dc
    on o.customer_id = dc.customer_id
left join `qwiklabs-gcp-04-05c5517686d1`.`gold`.`dim_products` dp
    on oi.product_id = dp.product_id
left join `qwiklabs-gcp-04-05c5517686d1`.`gold`.`dim_sellers` ds
    on oi.seller_id = ds.seller_id
left join `qwiklabs-gcp-04-05c5517686d1`.`gold`.`dim_date` dd
    on cast(o.order_date as date) = dd.full_date