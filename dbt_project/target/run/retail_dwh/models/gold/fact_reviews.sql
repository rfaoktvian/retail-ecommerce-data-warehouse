
  
    

    create or replace table `qwiklabs-gcp-03-018d48a9d681`.`gold`.`fact_reviews`
      
    
    

    
    OPTIONS()
    as (
      -- Gold: fact_reviews
-- Grain: 1 baris = 1 review (sudah di-dedup di silver via QUALIFY ROW_NUMBER)
--
-- Join ke fact_sales: gunakan order_id sebagai bridge key.
-- Catatan: 1 order bisa punya banyak order_item (baris di fact_sales),
-- sehingga join fact_reviews → fact_sales via order_id bisa menghasilkan fanout.
-- Gunakan dengan aggregasi (group by order_id) saat join ke fact_sales.
--
-- KOLOM ANALITIK BARU:
--   - review_answer_days : jumlah hari dari review dibuat → dijawab seller
--                          (proxy untuk kecepatan respons seller terhadap customer)

select
    to_hex(md5(cast(coalesce(cast(r.review_id as string), '_dbt_utils_surrogate_key_null_') as string))) as review_key,

    -- Foreign Keys
    dc.customer_key,
    dd.date_key                                         as review_date_key,

    -- Degenerate Dimensions / Bridge Keys
    r.review_id,
    r.order_id,

    -- Measures: Satisfaction
    r.review_score,

    -- Measures: Response Speed
    date_diff(
        date(cast(r.answered_at as timestamp)),
        date(cast(r.created_at as timestamp)),
        day
    )                                                   as review_answer_days,

    -- Attributes (nullable — user tidak wajib isi teks review)
    r.comment_title,
    r.comment_message,

    -- Timestamps
    r.created_at   as review_created_at,
    r.answered_at  as review_answered_at

from `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_reviews` r
left join `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_orders` o
    on r.order_id = o.order_id
left join `qwiklabs-gcp-03-018d48a9d681`.`gold`.`dim_customers` dc
    on o.customer_id = dc.customer_id
left join `qwiklabs-gcp-03-018d48a9d681`.`gold`.`dim_date` dd
    on date(cast(r.created_at as timestamp)) = dd.full_date
    );
  