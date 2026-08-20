
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select customer_key
from `qwiklabs-gcp-04-05c5517686d1`.`gold`.`dim_customer`
where customer_key is null



  
  
      
    ) dbt_internal_test