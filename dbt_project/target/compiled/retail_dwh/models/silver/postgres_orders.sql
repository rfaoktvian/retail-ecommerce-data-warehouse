-- Silver: orders
-- Cleaning: standardisasi order_status (lowercase), rename kolom timestamp jadi lebih ringkas

select
    order_id,
    customer_id,
    lower(trim(order_status)) as order_status,
    order_purchase_timestamp as order_date,
    order_approved_at as approved_at,
    -- Data quality fix: 166 baris punya delivered_carrier_date SEBELUM purchase_timestamp
    -- (tidak logis, kemungkinan error input di source). Di-nullify, bukan dihapus barisnya.
    case
        when order_delivered_carrier_date < order_purchase_timestamp then null
        else order_delivered_carrier_date
    end as delivered_carrier_at,
    order_delivered_customer_date as delivered_customer_at,
    order_estimated_delivery_date as estimated_delivery_date,
    dwh_extracted_at,
    dwh_source_system

from `qwiklabs-gcp-04-05c5517686d1`.`bronze`.`postgres_orders`
where order_id is not null