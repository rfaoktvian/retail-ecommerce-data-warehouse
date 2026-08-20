-- Silver: order_items
-- Cleaning: buang baris tanpa order_id/product_id (integritas dasar bridge table)

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

from `qwiklabs-gcp-04-05c5517686d1`.`bronze`.`postgres_order_items`
where order_id is not null
  and product_id is not null