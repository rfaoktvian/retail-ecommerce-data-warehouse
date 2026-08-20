
    
    

with dbt_test__target as (

  select zip_code_prefix as unique_field
  from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`csv_geolocation`
  where zip_code_prefix is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


