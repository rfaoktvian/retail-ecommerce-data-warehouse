
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select product_id
from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`postgres_products`
where product_id is null



  
  
      
    ) dbt_internal_test