"""
Demo 1 – TaskFlow API verzió (Airflow 2.x)
Ugyanaz az etl_pipeline, de @task dekorátorral – automatikus XCom kezeléssel.
Kapcsolódó dia: Blokk 2 (TaskFlow API), demo1-airflow.md
"""
from airflow.decorators import dag, task
from datetime import datetime, timedelta
import random


@dag(
    dag_id="etl_taskflow",
    schedule="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args={"retries": 2, "retry_delay": timedelta(seconds=30)},
    tags=["week05", "demo1", "taskflow"],
)
def etl_taskflow_pipeline():

    @task
    def extract(ds: str = None) -> list[dict]:
        """Szimulált API hívás."""
        records = [{"id": i, "amount": round(random.uniform(100, 50000), 2),
                    "date": ds}
                   for i in range(1, 51)]
        print(f"Letöltve: {len(records)} rekord ({ds})")
        return records  # return értéke automatikusan XCom-ba kerül

    @task
    def validate(records: list[dict]) -> list[dict]:
        """Adatminőség: negatív amount kiszűrése."""
        valid = [r for r in records if r["amount"] > 0]
        print(f"Validált: {len(valid)} / {len(records)}")
        return valid

    @task(retries=3, retry_delay=timedelta(seconds=10))
    def transform(records: list[dict]) -> list[dict]:
        """HUF konverzió – 10% eséllyel megbukik (retry demo)."""
        if random.random() < 0.10:
            raise RuntimeError("Szimulált API hiba – retry fog indulni!")
        result = [{"id": r["id"], "amount_huf": round(r["amount"] * 390, 0),
                   "date": r["date"]} for r in records]
        print(f"Transzformálva: {len(result)} rekord")
        return result

    @task
    def load(records: list[dict], ds: str = None) -> None:
        """Betöltés szimulálása."""
        total = sum(r["amount_huf"] for r in records)
        print(f"[{ds}] Betöltve: {len(records)} sor | Összeg: {total:,.0f} HUF")

    raw     = extract()
    valid   = validate(raw)
    result  = transform(valid)
    load(result)


etl_taskflow_pipeline()
