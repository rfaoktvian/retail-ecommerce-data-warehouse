
    
    

with child as (
    select product_id as from_field
    from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`postgres_order_items`
    where product_id is not null
),

parent as (
    select product_id as to_field
    from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`postgres_products`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


