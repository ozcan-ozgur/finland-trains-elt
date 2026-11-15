
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select stop_event_id
from "warehouse"."analytics"."int_digitraffic__train_stops_unnested"
where stop_event_id is null



  
  
      
    ) dbt_internal_test