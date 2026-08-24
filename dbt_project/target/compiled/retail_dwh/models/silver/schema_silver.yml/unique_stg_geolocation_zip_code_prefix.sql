
    
    

with dbt_test__target as (

  select zip_code_prefix as unique_field
  from `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_geolocation`
  where zip_code_prefix is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


