select
    concat_ws('-', t.departure_date, t.train_number, r.stop_index) as stop_event_id,
    t.train_id,
    t.departure_date,
    t.train_number,
    r.stop_index,
    r.stop->>'stationShortCode'               as station_short_code,
    r.stop->>'type'                           as event_type,
   (r.stop->>'scheduledTime')::timestamptz    as scheduled_at,
   (r.stop->>'actualTime')::timestamptz       as actual_at,
   (r.stop->>'differenceInMinutes')::int      as difference_in_minutes,
   (r.stop->>'trainStopping')::boolean        as is_train_stopping,
   (r.stop->>'commercialStop')::boolean       as is_commercial_stop,
   (r.stop->>'cancelled')::boolean            as is_cancelled
from "warehouse"."analytics"."stg_digitraffic__trains" as t
cross join lateral jsonb_array_elements(t.time_table_rows)
    with ordinality r(stop,stop_index)