
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select version
from "warehouse"."analytics"."stg_digitraffic__trains"
where version is null



  
  
      
    ) dbt_internal_test