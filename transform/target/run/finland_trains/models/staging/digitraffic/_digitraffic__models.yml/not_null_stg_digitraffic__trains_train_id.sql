
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select train_id
from "warehouse"."analytics"."stg_digitraffic__trains"
where train_id is null



  
  
      
    ) dbt_internal_test