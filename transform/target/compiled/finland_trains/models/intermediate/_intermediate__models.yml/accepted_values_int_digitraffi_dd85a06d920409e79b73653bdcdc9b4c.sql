
    
    

with all_values as (

    select
        event_type as value_field,
        count(*) as n_records

    from "warehouse"."analytics"."int_digitraffic__train_stops_unnested"
    group by event_type

)

select *
from all_values
where value_field not in (
    'ARRIVAL','DEPARTURE'
)


