
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select zip_code_prefix
from `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_geolocation`
where zip_code_prefix is null



  
  
      
    ) dbt_internal_test