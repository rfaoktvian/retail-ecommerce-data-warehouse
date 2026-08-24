
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select review_id
from `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_reviews`
where review_id is null



  
  
      
    ) dbt_internal_test