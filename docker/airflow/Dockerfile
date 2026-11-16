FROM apache/airflow:3.3.2-python3.12

RUN python -m venv /opt/airflow/dbt_venv \
 && PIP_USER=false /opt/airflow/dbt_venv/bin/pip install --no-cache-dir \
      dbt-core==1.12.7 \
      dbt-postgres==1.11.0