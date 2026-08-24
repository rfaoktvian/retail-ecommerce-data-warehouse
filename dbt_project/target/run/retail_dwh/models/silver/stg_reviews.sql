

  create or replace view `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_reviews`
  OPTIONS()
  as -- Silver: reviews
-- Source: bronze.json_reviews (format JSON/API dengan kolom camelCase)
-- Cleaning:
--   1. Rename kolom camelCase → snake_case (konvensi warehouse)
--   2. [DQ FIX] Dedup 814 baris duplikat berdasarkan review_id
--      (satu order bisa memiliki lebih dari satu review entry di source).
--      Strategi: ambil review terbaru berdasarkan dwh_extracted_at.
--   3. [DQ NOTE] 87.656 baris null comment_title (88.3%) dan
--      58.247 baris null comment_message (58.7%) adalah WAJAR —
--      user tidak wajib mengisi komentar teks saat memberi rating.
--      Kolom dibiarkan nullable.

select
    reviewId       as review_id,
    orderId        as order_id,
    reviewScore    as review_score,
    commentTitle   as comment_title,
    commentMessage as comment_message,
    cast(createdAt as timestamp)   as created_at,
    cast(answeredAt as timestamp)  as answered_at,
    dwh_extracted_at,
    dwh_source_system

from `qwiklabs-gcp-03-018d48a9d681`.`bronze`.`json_reviews`
where reviewId is not null

-- Dedup: dari 814 duplikat review_id, pertahankan record terbaru
qualify row_number() over (
    partition by reviewId
    order by dwh_extracted_at desc
) = 1;

