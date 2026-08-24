
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select customer_key
from `qwiklabs-gcp-03-018d48a9d681`.`gold`.`dim_customers`
where customer_key is null



  
  
      
    ) dbt_internal_test