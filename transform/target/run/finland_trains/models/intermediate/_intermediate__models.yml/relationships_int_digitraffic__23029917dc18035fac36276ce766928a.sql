
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with child as (
    select train_id as from_field
    from "warehouse"."analytics"."int_digitraffic__train_stops_unnested"
    where train_id is not null
),

parent as (
    select train_id as to_field
    from "warehouse"."analytics"."stg_digitraffic__trains"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null



  
  
      
    ) dbt_internal_test