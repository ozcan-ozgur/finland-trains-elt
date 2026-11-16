with days as (

    select
        day_ts::date as date_day

    from generate_series(
        '2026-01-01'::date,
        '2027-12-31'::date,
        interval '1 day'
    ) as d(day_ts)

)

select
    date_day,
    extract(year from date_day)::int    as year,
    extract(quarter from date_day)::int as quarter,
    extract(month from date_day)::int   as month,
    extract(day from date_day)::int     as day_of_month,
    extract(week from date_day)::int    as iso_week,
    extract(isodow from date_day)::int  as day_of_week,
    to_char(date_day, 'FMDay')          as day_name,
    to_char(date_day, 'FMMonth')        as month_name,
    extract(isodow from date_day) in (6,7) as is_weekend

from days

