import os
from datetime import date

import psycopg
from psycopg.types.json import Jsonb

from extract import extract, extract_stations

CREATE_SCHEMA = "CREATE SCHEMA IF NOT EXISTS raw"

CREATE_TABLE = """
CREATE TABLE IF NOT EXISTS raw.trains (
    departure_date date    NOT NULL,
    train_number integer   NOT NULL,
    version bigint         NOT NULL,
    payload jsonb          NOT NULL,
    loaded_at timestamptz  NOT NULL DEFAULT now(),
    PRIMARY KEY (departure_date, train_number, version)
)
"""

INSERT_TRAIN = """
INSERT INTO raw.trains (departure_date, train_number, version, payload)
VALUES (%s, %s, %s, %s)
ON CONFLICT (departure_date, train_number, version) DO NOTHING
"""

CREATE_STATIONS_TABLE = """
CREATE TABLE IF NOT EXISTS raw.stations (
    station_short_code text PRIMARY KEY,
    payload jsonb NOT NULL,
    loaded_at timestamptz NOT NULL DEFAULT now()
)
"""

TRUNCATE_STATIONS = "TRUNCATE raw.stations"

INSERT_STATION = """
INSERT INTO raw.stations (station_short_code, payload)
VALUES (%s, %s)
"""


def get_conninfo() -> str:
    return (
        f"host={os.environ.get('POSTGRES_HOST', 'localhost')} "
        f"port={os.environ.get('POSTGRES_PORT', '5432')} "
        "dbname=warehouse "
        f"user={os.environ['POSTGRES_USER']} "
        f"password={os.environ['POSTGRES_PASSWORD']}"
    )


def load(trains):
    rows = []

    for t in trains:
        row = (
            date.fromisoformat(t["departureDate"]),
            t["trainNumber"],
            t["version"],
            Jsonb(t),
        )
        rows.append(row)

    with psycopg.connect(get_conninfo()) as conn, conn.cursor() as cur:
        cur.execute(CREATE_SCHEMA)
        cur.execute(CREATE_TABLE)
        cur.executemany(INSERT_TRAIN, rows)
        return cur.rowcount


def load_stations(stations):
    rows = []

    for s in stations:
        row = (
            s["stationShortCode"],
            Jsonb(s),
        )
        rows.append(row)

    with psycopg.connect(get_conninfo()) as conn, conn.cursor() as cur:
        cur.execute(CREATE_SCHEMA)
        cur.execute(CREATE_STATIONS_TABLE)
        cur.execute(TRUNCATE_STATIONS)
        cur.executemany(INSERT_STATION, rows)
        return cur.rowcount


if __name__ == "__main__":
    ds = "2026-11-15"
    trains = extract(ds)
    loaded = load(trains)
    print(f"{len(trains)} trains extracted, {loaded} trains loaded")

    stations = extract_stations()
    loaded_stations = load_stations(stations)
    print(f"{len(stations)} stations extracted, {loaded_stations} stations loaded")
