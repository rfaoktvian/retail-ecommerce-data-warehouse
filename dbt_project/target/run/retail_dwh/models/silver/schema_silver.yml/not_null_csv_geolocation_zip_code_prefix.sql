
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select zip_code_prefix
from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`csv_geolocation`
where zip_code_prefix is null



  
  
      
    ) dbt_internal_test