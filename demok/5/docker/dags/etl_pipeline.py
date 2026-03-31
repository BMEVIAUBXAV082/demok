"""
Demo 1 – Klasszikus Airflow DAG
Kapcsolódó dia: Blokk 2 (Apache Airflow), demo1-airflow.md
"""
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import random

default_args = {
    "owner": "dataeng",
    "retries": 2,
    "retry_delay": timedelta(seconds=30),
    "email_on_failure": False,
}


def extract_orders(**context):
    """Szimulált API hívás – rekordok letöltése."""
    records = [{"id": i, "amount": round(random.uniform(100, 50000), 2)}
               for i in range(1, 101)]
    context["ti"].xcom_push(key="record_count", value=len(records))
    context["ti"].xcom_push(key="records", value=records)
    print(f"Letöltött rekordok: {len(records)}")
    return records


def validate_orders(**context):
    """Adatminőség-ellenőrzés – negatív amount kiszűrése."""
    records = context["ti"].xcom_pull(task_ids="extract", key="records")
    valid = [r for r in records if r["amount"] > 0]
    invalid_count = len(records) - len(valid)
    if invalid_count > 0:
        print(f"Figyelmeztetés: {invalid_count} érvénytelen rekord kiszűrve")
    context["ti"].xcom_push(key="valid_records", value=valid)
    print(f"Validált rekordok: {len(valid)}")


def transform_orders(**context):
    """Transzformáció – összeg HUF-ra konvertálva."""
    records = context["ti"].xcom_pull(task_ids="validate", key="valid_records")
    transformed = [{"id": r["id"], "amount_huf": round(r["amount"] * 390, 0)}
                   for r in records]
    context["ti"].xcom_push(key="transformed", value=transformed)
    print(f"Transzformált: {len(transformed)} rekord")


def load_orders(**context):
    """Betöltés – szimulált DuckDB write."""
    records = context["ti"].xcom_pull(task_ids="transform", key="transformed")
    total   = sum(r["amount_huf"] for r in records)
    print(f"Betöltve: {len(records)} rekord, összes: {total:,.0f} HUF")


with DAG(
    dag_id="etl_pipeline",
    default_args=default_args,
    schedule="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["week05", "demo1"],
) as dag:

    extract   = PythonOperator(task_id="extract",   python_callable=extract_orders)
    validate  = PythonOperator(task_id="validate",  python_callable=validate_orders)
    transform = PythonOperator(task_id="transform", python_callable=transform_orders)
    load      = PythonOperator(task_id="load",      python_callable=load_orders)

    extract >> validate >> transform >> load
