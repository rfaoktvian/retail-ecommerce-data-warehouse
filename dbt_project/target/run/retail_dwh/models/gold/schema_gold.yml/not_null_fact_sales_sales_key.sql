
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select sales_key
from `qwiklabs-gcp-03-018d48a9d681`.`gold`.`fact_sales`
where sales_key is null



  
  
      
    ) dbt_internal_test