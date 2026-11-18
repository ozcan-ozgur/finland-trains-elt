
select
    (payload->>'type')::text as station_type,
    (payload->>'latitude')::numeric as latitude,
    (payload->>'longitude')::numeric as longitude,
    (payload->>'countryCode')::text as country_code,
    (payload->>'stationName')::text as station_name,
    (payload->>'stationUICCode')::int as station_uic_code,
    (payload->>'passengerTraffic')::boolean as is_passenger_traffic,
    (payload->>'stationShortCode')::text as station_short_code

from {{ source('digitraffic','stations') }}