-- Grain: 1 baris = 1 payment (1 order bisa punya lebih dari 1 baris kalau split payment)

select
    to_hex(md5(cast(coalesce(cast(op.order_id as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(op.payment_sequential as string), '_dbt_utils_surrogate_key_null_') as string))) as payment_key,

    dc.customer_key,
    dd.date_key as order_date_key,

    op.order_id,
    op.payment_sequential,
    op.payment_type,
    op.payment_installments,
    op.payment_value

from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`postgres_order_payments` op
left join `qwiklabs-gcp-04-05c5517686d1`.`silver`.`postgres_orders` o
    on op.order_id = o.order_id
left join `qwiklabs-gcp-04-05c5517686d1`.`gold`.`dim_customer` dc
    on o.customer_id = dc.customer_id
left join `qwiklabs-gcp-04-05c5517686d1`.`gold`.`dim_date` dd
    on cast(o.order_date as date) = dd.full_date