-- Silver: reviews
-- Cleaning: rename kolom camelCase (dari format JSON/API) kembali ke snake_case,
-- konsisten dengan konvensi kolom di seluruh warehouse.
-- Cast eksplisit STRING -> TIMESTAMP (JSON selalu simpan tanggal sebagai string).
-- Data quality fix: ditemukan 814 baris dengan review_id DUPLIKAT di bronze.
-- Di-dedup pakai QUALIFY + ROW_NUMBER, keep baris dengan answeredAt TERBARU
-- per review_id (asumsi: revisi/update jawaban terakhir yang paling valid).

select
    reviewId as review_id,
    orderId as order_id,
    reviewScore as review_score,
    commentTitle as comment_title,
    commentMessage as comment_message,
    cast(createdAt as timestamp) as created_at,
    cast(answeredAt as timestamp) as answered_at,
    dwh_extracted_at,
    dwh_source_system

from `qwiklabs-gcp-04-05c5517686d1`.`bronze`.`json_reviews`
where reviewId is not null
qualify row_number() over (
    partition by reviewId
    order by cast(answeredAt as timestamp) desc
) = 1