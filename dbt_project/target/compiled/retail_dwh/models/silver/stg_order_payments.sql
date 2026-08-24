-- Silver: order_payments
-- Source: bronze.postgres_order_payments
-- Cleaning:
--   1. [DQ FIX] 3 baris payment_type = 'not_defined' → distandarkan jadi 'unknown'
--      agar tidak ada nilai ambigu di kolom kategori.
--   2. [DQ FIX] 2 baris payment_installments = 0 → di-floor ke 1
--      (secara bisnis minimal 1x pembayaran, nilai 0 adalah error input).
--   3. [DQ NOTE] 9 baris payment_value = 0 dibiarkan — nilai nol adalah VALID
--      (bisa full-voucher atau order yang di-cover promo 100%).
--      Tidak di-nullify karena tidak bisa dibedakan dari error tanpa info tambahan.

select
    order_id,
    payment_sequential,
    -- DQ Fix #1: normalisasi payment_type
    case
        when lower(trim(payment_type)) = 'not_defined' then 'unknown'
        else lower(trim(payment_type))
    end as payment_type,
    -- DQ Fix #2: floor payment_installments ke minimum 1
    case
        when payment_installments = 0 then 1
        else payment_installments
    end as payment_installments,
    payment_value,
    dwh_extracted_at,
    dwh_source_system

from `qwiklabs-gcp-03-018d48a9d681`.`bronze`.`postgres_order_payments`
where order_id is not null