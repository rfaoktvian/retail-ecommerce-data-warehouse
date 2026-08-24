
    
    

with all_values as (

    select
        order_status as value_field,
        count(*) as n_records

    from `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_orders`
    group by order_status

)

select *
from all_values
where value_field not in (
    'delivered','shipped','canceled','unavailable','invoiced','processing','created','approved'
)


