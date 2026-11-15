
  create view "warehouse"."analytics"."stg_digitraffic__trains__dbt_tmp"
    
    
  as (
    with latest_train as (

    select
        *,
        row_number() over (
        partition by departure_date, train_number
        order by version DESC
        ) as rn

    from "warehouse"."raw"."trains"

)


select
    concat_ws('-', departure_date, train_number) as train_id,
    departure_date,
    train_number,
    version,
    payload->>'operatorShortCode' as operator_short_code,
    (payload->>'cancelled')::boolean as is_cancelled,
    payload->'timeTableRows' as time_table_rows
from latest_train
where rn = 1
  );