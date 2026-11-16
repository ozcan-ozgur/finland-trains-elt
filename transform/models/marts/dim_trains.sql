with trains as (

    select
    train_id,
    departure_date,
    train_number,
    train_category,
    train_type,
    is_cancelled,
    operator_short_code

from {{ ref('stg_digitraffic__trains') }}

),

stops as (

    select
        train_id,
        stop_index,
        station_short_code,
        max(stop_index) over (
            partition by(train_id)
                )                 as last_stop_index

    from {{ ref('int_train_stops_unnested') }}

),

origins as (

    select
        train_id,
        station_short_code as origin_station_short_code
    from stops
    where stop_index = 1

),

destinations as (

    select
        train_id,
        station_short_code as destination_station_short_code
    from stops
    where stop_index = last_stop_index

)

select
    t.train_id,
    t.departure_date,
    t.train_number,
    t.train_category,
    t.train_type,
    t.operator_short_code,
    t.is_cancelled,
    o.origin_station_short_code,
    d.destination_station_short_code
from trains as t
left join origins as o
    on t.train_id = o.train_id
left join destinations as d
    on t.train_id = d.train_id