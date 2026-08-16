-- Grain: 1 baris = 1 review

select
    {{ dbt_utils.generate_surrogate_key(['r.review_id']) }} as review_key,

    dc.customer_key,
    dd.date_key as review_date_key,

    r.review_id,
    r.order_id,
    r.review_score,
    r.comment_title,
    r.comment_message

from {{ ref('json_reviews') }} r
left join {{ ref('postgres_orders') }} o
    on r.order_id = o.order_id
left join {{ ref('dim_customers') }} dc
    on o.customer_id = dc.customer_id
left join {{ ref('dim_date') }} dd
    on cast(r.created_at as date) = dd.full_date