
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select geography_key
from `qwiklabs-gcp-03-018d48a9d681`.`gold`.`dim_geography`
where geography_key is null



  
  
      
    ) dbt_internal_test