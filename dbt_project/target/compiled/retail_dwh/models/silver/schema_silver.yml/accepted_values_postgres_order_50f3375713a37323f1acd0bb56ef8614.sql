
    
    

with all_values as (

    select
        order_status as value_field,
        count(*) as n_records

    from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`postgres_orders`
    group by order_status

)

select *
from all_values
where value_field not in (
    'delivered','shipped','canceled','unavailable','invoiced','processing','created','approved'
)


