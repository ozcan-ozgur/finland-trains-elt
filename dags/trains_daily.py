from datetime import datetime

from airflow.sdk import dag, task

from extract import extract
from load import load


@dag(
    schedule="0 6 * * *",
    start_date = datetime(2026,11,1),
    catchup=False,
)
def trains_daily():
    @task
    def extract_and_load(*, ds, macros):
        day = macros.ds_add(ds, -1)
        trains = extract(day)
        loaded = load(trains)
        print(f"{len(trains)} trains extracted, {loaded} trains loaded")

    @task.bash
    def dbt_build():
        return "cd /opt/airflow/transform && /opt/airflow/dbt_venv/bin/dbt build"

    extract_and_load() >> dbt_build()

trains_daily()




