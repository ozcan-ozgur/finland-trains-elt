from datetime import datetime, timedelta

from airflow.sdk import dag, task

from extract import extract_stations
from load import load_stations


@dag(
    schedule="0 5 * * 1",
    start_date=datetime(2026, 11, 1),
    catchup=False,
)
def stations_weekly():
    @task(retries=3, retry_delay=timedelta(minutes=5))
    def extract_and_load():
        stations = extract_stations()
        loaded = load_stations(stations)
        print(f"{len(stations)} stations extracted, {loaded} stations loaded")

    extract_and_load()


stations_weekly()
