
    
    

select
    train_id as unique_field,
    count(*) as n_records

from "warehouse"."analytics"."stg_digitraffic__trains"
where train_id is not null
group by train_id
having count(*) > 1


