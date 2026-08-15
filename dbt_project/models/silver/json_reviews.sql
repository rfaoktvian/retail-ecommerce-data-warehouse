-- Silver: reviews
-- Cleaning: rename kolom camelCase (dari format JSON/API) kembali ke snake_case,
-- konsisten dengan konvensi kolom di seluruh warehouse

select
    reviewId as review_id,
    orderId as order_id,
    reviewScore as review_score,
    commentTitle as comment_title,
    commentMessage as comment_message,
    createdAt as created_at,
    answeredAt as answered_at,
    dwh_extracted_at,
    dwh_source_system

from {{ source('bronze', 'json_reviews') }}
where reviewId is not null