import os
from datetime import date
import psycopg
from psycopg.types.json import Jsonb
from extract import extract

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

    with psycopg.connect(get_conninfo()) as conn:
        with conn.cursor() as cur:
            cur.execute(CREATE_SCHEMA)
            cur.execute(CREATE_TABLE)
            cur.executemany(INSERT_TRAIN, rows)
            return cur.rowcount


if __name__ == "__main__":
    day = "2026-11-12"
    trains = extract(day)
    inserted = load(trains)
