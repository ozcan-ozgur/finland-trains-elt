# Finland Trains ELT

An ELT pipeline for Finnish railway traffic data. It pulls daily train runs and station metadata from the [Digitraffic](https://www.digitraffic.fi/en/railway-traffic/) open API, loads the raw JSON into PostgreSQL, and builds analysis-ready models with dbt. Apache Airflow handles scheduling and Metabase handles visualization.

## Architecture

```text
Digitraffic API ──► extract.py ──► load.py ──► Postgres (raw.*) ──► dbt ──► analytics_marts.* ──► Metabase
                    └──────────── Airflow DAGs ────────────┘
```

| Component  | Technology                          | Port (host) |
|------------|-------------------------------------|-------------|
| Warehouse  | PostgreSQL 17                       | `5400`      |
| Scheduler  | Apache Airflow 3.3 (standalone)     | `8080`      |
| Transform  | dbt-core 1.12 + dbt-postgres        | –           |
| BI         | Metabase v0.64                      | `3000`      |

One Postgres instance holds three databases:

- `warehouse`: the pipeline data (`raw`, `analytics_staging`, `analytics_marts` schemas)
- `airflow`: Airflow metadata
- `metabase`: Metabase application data

## Project structure

```text
.
├── dags/
│   ├── trains_daily.py        # Daily: yesterday's trains → raw.trains, then dbt build
│   └── stations_weekly.py     # Weekly: station metadata → raw.stations
├── src/
│   ├── extract.py             # Digitraffic API client
│   └── load.py                # Loads into Postgres (raw schema)
├── transform/                 # dbt project (finland_trains)
│   ├── models/
│   │   ├── staging/digitraffic/
│   │   ├── intermediate/
│   │   └── marts/
│   ├── dbt_project.yml
│   └── profiles.yml
├── docker/
│   ├── airflow/Dockerfile     # Airflow image + separate venv for dbt
│   └── postgres/init/         # Creates databases and the raw schema
├── docker-compose.yml
├── pyproject.toml / uv.lock
└── .env.example
```

## Data flow

### Extract & Load (`src/`)

- **Trains:** `GET /api/v1/trains/{date}` returns all train runs for a day. Each train is stored in `raw.trains` as `jsonb`. The primary key is `(departure_date, train_number, version)`, so the load is idempotent (`ON CONFLICT DO NOTHING`) and keeps every version of a train.
- **Stations:** `GET /api/v1/metadata/stations` returns station metadata. The load writes it to `raw.stations` with a full refresh (`TRUNCATE` + `INSERT`).

### Transform (`transform/`)

| Layer        | Model                         | Materialization | Description |
|--------------|-------------------------------|-----------------|-------------|
| staging      | `stg_digitraffic__trains`     | view            | Keeps the latest `version` of each train and parses JSON fields |
| staging      | `stg_digitraffic__stations`   | view            | Parses station metadata |
| intermediate | `int_train_stops_unnested`    | view            | Unnests `timeTableRows` into one row per stop event |
| marts        | `fct_stop_events`             | table           | Stop-event fact table with delay and punctuality (`is_on_time`) |
| marts        | `dim_trains`                  | table           | One row per train run, with origin and destination stations |
| marts        | `dim_stations`                | table           | Station dimension |
| marts        | `dim_dates`                   | table           | Date dimension for 2026–2027 |

**Punctuality thresholds** (`fct_stop_events.punctuality_threshold_in_minutes`):

| Train category | Threshold |
|----------------|-----------|
| Commuter       | 3 min     |
| Long-distance  | 5 min     |
| Cargo          | 30 min    |

Other categories have no threshold, so `is_on_time` is `null` for them. It is also `null` when no actual time exists yet.

The tests cover `unique`, `not_null`, `accepted_values`, and `relationships` (fact → dimension) checks.

> Note: dbt's default schema naming prefixes custom schemas with the target schema, so the models land in `analytics_staging` and `analytics_marts`.

### Orchestration (`dags/`)

| DAG               | Schedule             | Steps |
|-------------------|----------------------|-------|
| `trains_daily`    | Daily at 06:00       | `extract_and_load` (for `ds - 1`, the previous day) → `dbt_build` |
| `stations_weekly` | Mondays at 05:00     | `extract_and_load` (3 retries, 5 min apart) |

## Setup

### Requirements

- Docker + Docker Compose
- (Optional, for local development) Python 3.12+ and [uv](https://docs.astral.sh/uv/)

### 1. Environment variables

```bash
cp .env.example .env
# Edit POSTGRES_PASSWORD in .env
```

| Variable            | Description                                  |
|---------------------|----------------------------------------------|
| `POSTGRES_USER`     | Postgres user                                |
| `POSTGRES_PASSWORD` | Postgres password                            |
| `POSTGRES_HOST`     | Used for local runs (`localhost`)            |
| `POSTGRES_PORT`     | Used for local runs (`5400`)                 |

Inside the containers, `POSTGRES_HOST=postgres` and `POSTGRES_PORT=5432` are set by `docker-compose.yml`.

### 2. Start the services

```bash
docker compose up -d --build
```

- **Airflow UI:** <http://localhost:8080> (the simple auth manager is on, so every user is an admin)
- **Metabase:** <http://localhost:3000> (first start can take a few minutes)

Note: the init scripts in `docker/postgres/init` run only when the `pgdata` volume is created for the first time.

### 3. Run the pipeline

Turn on the `trains_daily` and `stations_weekly` DAGs in the Airflow UI and trigger them manually. Run `stations_weekly` first, because the `fct_stop_events → dim_stations` relationship test needs station data.

### 4. Connect Metabase

Add a PostgreSQL database in Metabase:

- Host: `postgres`, Port: `5432`
- Database: `warehouse`
- User/Password: the values from `.env`
- The analysis tables are in the `analytics_marts` schema.

## Local development

```bash
uv sync

# Load environment variables (POSTGRES_HOST=localhost, POSTGRES_PORT=5400)
set -a; source .env; set +a

# One-off EL run (the date is fixed inside load.py)
cd src && uv run python load.py

# dbt
cd ../transform
uv run dbt build          # profiles.yml is read from this directory
uv run dbt docs generate && uv run dbt docs serve
```

Linting:

```bash
uv run ruff check .
uv run yamllint .
```

## Data source

Data comes from [Digitraffic](https://rata.digitraffic.fi/api/v1/doc/index.html) (Fintraffic) under the [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) license. API requests send a `Digitraffic-User` header, as the API asks.
