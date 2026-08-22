-- Gold: fact_payments
-- Grain: 1 baris = 1 payment record
--        (1 order bisa punya >1 baris jika split payment, diidentifikasi via payment_sequential)
--
-- Join ke fact_sales: gunakan order_id sebagai bridge key (payments di level order,
-- bukan order_item). Untuk drill-down ke item-level, join fact_payments → fact_sales
-- via order_id.
--
-- KOLOM:
--   - payment_key   : surrogate key unik per payment record
--   - customer_key  : FK ke dim_customers
--   - order_date_key: FK ke dim_date (tanggal order, bukan tanggal pembayaran)
--   - order_id      : degenerate dimension — bridge key ke fact_sales

select
    {{ dbt_utils.generate_surrogate_key(['op.order_id', 'op.payment_sequential']) }} as payment_key,

    -- Foreign Keys
    dc.customer_key,
    dd.date_key                   as order_date_key,

    -- Degenerate Dimensions / Bridge Keys
    op.order_id,
    op.payment_sequential,

    -- Attributes
    op.payment_type,
    op.payment_installments,

    -- Measures
    op.payment_value

from {{ ref('stg_order_payments') }} op
left join {{ ref('stg_orders') }} o
    on op.order_id = o.order_id
left join {{ ref('dim_customers') }} dc
    on o.customer_id = dc.customer_id
left join {{ ref('dim_date') }} dd
    on cast(o.order_date as date) = dd.full_date