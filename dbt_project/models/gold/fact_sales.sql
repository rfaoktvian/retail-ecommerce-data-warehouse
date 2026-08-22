-- Gold: fact_sales
-- Grain: 1 baris = 1 order_item (produk spesifik dalam 1 order)
--
-- CATATAN ANALISIS (hasil DQ profiling):
--   ~775 order di source TIDAK punya order_item sama sekali (dominan berstatus
--   unavailable/canceled/created — order gagal sebelum ada item terkonfirmasi).
--   Order ini tidak muncul di fact_sales karena grain-nya per order_item.
--   Ini WAJAR — tidak ada order 'delivered' yang hilang.
--   Untuk analisis funnel/conversion (termasuk order gagal): pakai stg_orders langsung.
--
-- KOLOM ANALITIK BARU:
--   - customer_geography_key : join ke dim_geography untuk peta penjualan per wilayah
--   - delivered_days          : total hari dari order → diterima customer
--   - days_early_or_late      : +N = N hari lebih cepat dari estimasi, -N = N hari terlambat
--   - is_late_delivery        : flag keterlambatan (delivered > estimated)
--   - is_weekend_order        : flag order di akhir pekan (Sabtu/Minggu)

select
    {{ dbt_utils.generate_surrogate_key(['oi.order_id', 'oi.order_item_id']) }} as sales_key,

    -- Foreign Keys
    dc.customer_key,
    dp.product_key,
    ds.seller_key,
    dd.date_key                                       as order_date_key,
    dg.geography_key                                  as customer_geography_key,

    -- Degenerate Dimensions
    oi.order_id,
    oi.order_item_id,
    o.order_status,

    -- Measures: Revenue
    oi.price,
    oi.freight_value,
    oi.price + oi.freight_value                       as total_amount,

    -- Measures: Delivery Performance
    date_diff(
        cast(o.delivered_customer_at as date),
        cast(o.order_date as date),
        day
    )                                                 as delivered_days,
    -- Positif = lebih cepat dari estimasi, negatif = terlambat
    date_diff(
        cast(o.estimated_delivery_date as date),
        cast(o.delivered_customer_at as date),
        day
    )                                                 as days_early_or_late,
    case
        when o.delivered_customer_at is not null
         and o.delivered_customer_at > o.estimated_delivery_date
        then true
        else false
    end                                               as is_late_delivery,

    -- Measures: Order Behavior
    case
        when extract(dayofweek from o.order_date) in (1, 7) then true
        else false
    end                                               as is_weekend_order

from {{ ref('stg_order_items') }} oi
left join {{ ref('stg_orders') }} o
    on oi.order_id = o.order_id
left join {{ ref('dim_customers') }} dc
    on o.customer_id = dc.customer_id
left join {{ ref('dim_products') }} dp
    on oi.product_id = dp.product_id
left join {{ ref('dim_sellers') }} ds
    on oi.seller_id = ds.seller_id
left join {{ ref('dim_date') }} dd
    on cast(o.order_date as date) = dd.full_date
left join {{ ref('dim_geography') }} dg
    on dc.zip_code_prefix = dg.zip_code_prefix