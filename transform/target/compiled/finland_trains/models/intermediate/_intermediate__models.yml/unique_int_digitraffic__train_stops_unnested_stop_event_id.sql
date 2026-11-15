
    
    

select
    stop_event_id as unique_field,
    count(*) as n_records

from "warehouse"."analytics"."int_digitraffic__train_stops_unnested"
where stop_event_id is not null
group by stop_event_id
having count(*) > 1


