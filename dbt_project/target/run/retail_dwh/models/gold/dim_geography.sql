
  
    

    create or replace table `qwiklabs-gcp-04-05c5517686d1`.`gold`.`dim_geography`
      
    
    

    
    OPTIONS()
    as (
      select
    to_hex(md5(cast(coalesce(cast(zip_code_prefix as string), '_dbt_utils_surrogate_key_null_') as string))) as geography_key,
    zip_code_prefix,
    latitude,
    longitude,
    city,
    state

from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`csv_geolocation`
    );
  