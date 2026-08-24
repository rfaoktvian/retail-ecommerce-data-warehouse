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
    to_hex(md5(cast(coalesce(cast(op.order_id as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(op.payment_sequential as string), '_dbt_utils_surrogate_key_null_') as string))) as payment_key,

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

from `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_order_payments` op
left join `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_orders` o
    on op.order_id = o.order_id
left join `qwiklabs-gcp-03-018d48a9d681`.`gold`.`dim_customers` dc
    on o.customer_id = dc.customer_id
left join `qwiklabs-gcp-03-018d48a9d681`.`gold`.`dim_date` dd
    on date(cast(o.order_date as timestamp)) = dd.full_date