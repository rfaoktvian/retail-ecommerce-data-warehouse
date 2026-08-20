
  
    

    create or replace table `qwiklabs-gcp-04-05c5517686d1`.`gold`.`fact_reviews`
      
    
    

    
    OPTIONS()
    as (
      -- Grain: 1 baris = 1 review

select
    to_hex(md5(cast(coalesce(cast(r.review_id as string), '_dbt_utils_surrogate_key_null_') as string))) as review_key,

    dc.customer_key,
    dd.date_key as review_date_key,

    r.review_id,
    r.order_id,
    r.review_score,
    r.comment_title,
    r.comment_message

from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`json_reviews` r
left join `qwiklabs-gcp-04-05c5517686d1`.`silver`.`postgres_orders` o
    on r.order_id = o.order_id
left join `qwiklabs-gcp-04-05c5517686d1`.`gold`.`dim_customer` dc
    on o.customer_id = dc.customer_id
left join `qwiklabs-gcp-04-05c5517686d1`.`gold`.`dim_date` dd
    on cast(r.created_at as date) = dd.full_date
    );
  