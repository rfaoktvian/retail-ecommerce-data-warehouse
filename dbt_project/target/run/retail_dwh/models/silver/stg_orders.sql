

  create or replace view `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_orders`
  OPTIONS()
  as -- Silver: orders
-- Source: bronze.postgres_orders
-- Cleaning:
--   1. Standardisasi order_status (lowercase, trim) + rename kolom timestamp lebih ringkas
--   2. [DQ NOTE] 160 null order_approved_at (0.16%) — WAJAR untuk order dengan status
--      'canceled', 'unavailable', atau 'created' yang belum sempat di-approve.
--      Kolom dibiarkan nullable.
--   3. [DQ FIX] 166 baris order_delivered_carrier_date < order_purchase_timestamp
--      (tidak logis, kemungkinan error input di source) → di-nullify, bukan dihapus barisnya.
--   4. [DQ NOTE] 1783 null order_delivered_carrier_date (1.79%) dan
--      2965 null order_delivered_customer_date (2.98%) — WAJAR untuk order yang belum
--      sampai ke carrier / belum diterima customer (status non-delivered).
--      Kolom dibiarkan nullable.

select
    order_id,
    customer_id,
    lower(trim(order_status))                       as order_status,
    order_purchase_timestamp                        as order_date,
    -- DQ Note: 160 null (0.16%), wajar untuk order yang belum/tidak di-approve
    order_approved_at                               as approved_at,
    -- DQ Fix: 166 baris carrier_date < purchase_timestamp → null (tidak logis)
    -- DQ Note: 1783 null (1.79%), wajar untuk order belum di-pickup carrier
    case
        when order_delivered_carrier_date < order_purchase_timestamp then null
        else order_delivered_carrier_date
    end                                             as delivered_carrier_at,
    -- DQ Note: 2965 null (2.98%), wajar untuk order belum diterima customer
    order_delivered_customer_date                   as delivered_customer_at,
    order_estimated_delivery_date                   as estimated_delivery_date,
    dwh_extracted_at,
    dwh_source_system

from `qwiklabs-gcp-03-018d48a9d681`.`bronze`.`postgres_orders`
where order_id is not null;

