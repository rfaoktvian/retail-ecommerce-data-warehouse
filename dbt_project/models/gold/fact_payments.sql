-- Grain: 1 baris = 1 payment (1 order bisa punya lebih dari 1 baris kalau split payment)

select
    {{ dbt_utils.generate_surrogate_key(['op.order_id', 'op.payment_sequential']) }} as payment_key,

    dc.customer_key,
    dd.date_key as order_date_key,

    op.order_id,
    op.payment_sequential,
    op.payment_type,
    op.payment_installments,
    op.payment_value

from {{ ref('postgres_order_payments') }} op
left join {{ ref('postgres_orders') }} o
    on op.order_id = o.order_id
left join {{ ref('dim_customers') }} dc
    on o.customer_id = dc.customer_id
left join {{ ref('dim_date') }} dd
    on cast(o.order_date as date) = dd.full_date