

  create or replace view `qwiklabs-gcp-04-05c5517686d1`.`silver`.`postgres_order_payments`
  OPTIONS()
  as -- Silver: order_payments
-- Cleaning: standardisasi payment_type (lowercase)

select
    order_id,
    payment_sequential,
    -- Data quality fix: 3 baris payment_type = 'not_defined', distandarkan jadi 'unknown'
    case
        when lower(trim(payment_type)) = 'not_defined' then 'unknown'
        else lower(trim(payment_type))
    end as payment_type,
    -- Data quality fix: 2 baris payment_installments = 0, tidak logis
    -- (minimal 1x pembayaran meski tidak dicicil). Di-floor jadi 1.
    case when payment_installments = 0 then 1 else payment_installments end as payment_installments,
    payment_value,
    dwh_extracted_at,
    dwh_source_system

from `qwiklabs-gcp-04-05c5517686d1`.`bronze`.`postgres_order_payments`
where order_id is not null;

