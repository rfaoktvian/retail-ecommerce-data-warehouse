
  
    

    create or replace table `qwiklabs-gcp-04-05c5517686d1`.`gold`.`dim_customer`
      
    
    

    
    OPTIONS()
    as (
      select
    to_hex(md5(cast(coalesce(cast(customer_id as string), '_dbt_utils_surrogate_key_null_') as string))) as customer_key,
    customer_id,
    customer_unique_id,
    zip_code_prefix,
    city,
    state

from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`postgres_customers`
    );
  