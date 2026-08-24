

  create or replace view `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_order_items`
  OPTIONS()
  as -- Silver: order_items
-- Source: bronze.postgres_order_items
-- Cleaning:
--   1. Buang baris tanpa order_id / product_id (integritas dasar bridge table)
--   2. [DQ NOTE] 383 baris dengan freight_value = 0 dibiarkan — nilai nol adalah VALID
--      (bisa gratis ongkir karena promo, voucher, atau kebijakan seller tertentu).
--      Tidak di-nullify karena bukan data error.

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,
    dwh_extracted_at,
    dwh_source_system

from `qwiklabs-gcp-03-018d48a9d681`.`bronze`.`postgres_order_items`
where order_id is not null
  and product_id is not null;

