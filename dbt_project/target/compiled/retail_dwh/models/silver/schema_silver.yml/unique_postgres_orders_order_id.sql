
    
    

with dbt_test__target as (

  select order_id as unique_field
  from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`postgres_orders`
  where order_id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


