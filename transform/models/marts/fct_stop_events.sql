with stops as (

    select *
    from {{  ref("int_train_stops_unnested") }}

),

trains as (

    select train_id,
           train_category,
           train_type,
           operator_short_code
    from {{ ref('stg_digitraffic__trains') }}

),

joined as (
    select
        s.*,
        t.train_category,
        t.train_type,
        t.operator_short_code,

        case t.train_category
            when 'Long-distance' then 5
            when 'Commuter'      then 3
            when 'Cargo'         then 30
        end as punctuality_threshold_in_minutes,

        s.stop_index = 1 as is_first_departure,
        s.stop_index = max(stop_index) over (partition by s.train_id) as is_final_arrival

    from stops as s
        join trains as t on s.train_id = t.train_id

)

select
    stop_event_id,
    train_id,
    departure_date,
    train_number,
    stop_index,
    station_short_code,
    event_type,
    train_category,
    train_type,
    operator_short_code,
    scheduled_at,
    actual_at,
    difference_in_minutes as delay_minutes,
    punctuality_threshold_in_minutes,
    case
        when actual_at is null or punctuality_threshold_in_minutes is null then null
        else difference_in_minutes <= punctuality_threshold_in_minutes
    end as is_on_time,
    is_first_departure,
    is_final_arrival,
    is_train_stopping,
    is_commercial_stop,
    is_cancelled

from joined