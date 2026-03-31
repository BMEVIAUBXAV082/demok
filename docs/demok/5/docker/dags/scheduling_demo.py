"""
Demo 4 – Scheduling minták (cron, interval, catchup, sensor)
Kapcsolódó: demo4-scheduling.md
"""
from airflow.decorators import dag, task
from airflow.sensors.filesystem import FileSensor
from datetime import datetime, timedelta
import duckdb


# --- Cron-alapú, napi ütemezés ---

@dag(
    dag_id="daily_revenue_load",
    schedule="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,          # Biztonságos: kimaradt futások NEM pótlódnak automatikusan
    max_active_runs=1,      # Egyszerre csak 1 Run futhat párhuzamosan
    tags=["week05", "demo4"],
)
def daily_revenue_pipeline():

    @task
    def load_day(ds: str = None) -> None:
        """Idempotens betöltés: DELETE + INSERT az adott napra."""
        con = duckdb.connect("/tmp/revenue_demo.duckdb")
        con.execute("""
            CREATE TABLE IF NOT EXISTS daily_revenue (
                date    VARCHAR PRIMARY KEY,
                revenue FLOAT
            )
        """)
        # DELETE + INSERT = idempotens: akárhányszor lefuttatva ugyanaz az eredmény
        con.execute("DELETE FROM daily_revenue WHERE date = ?", [ds])
        con.execute("INSERT INTO daily_revenue VALUES (?, ?)", [ds, 123456.78])
        count = con.execute(
            "SELECT COUNT(*) FROM daily_revenue WHERE date = ?", [ds]
        ).fetchone()[0]
        print(f"Betöltve: {count} sor ({ds})")

    load_day()


daily_revenue_pipeline()


# --- Event-driven pipeline: Sensor triggereli ---

@dag(
    dag_id="file_triggered_pipeline",
    schedule=None,          # Nem cron-alapú: a Sensor triggeli
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["week05", "demo4", "sensor"],
)
def file_triggered_pipeline():

    wait_for_file = FileSensor(
        task_id="wait_for_daily_export",
        filepath="/tmp/incoming/orders_{{ ds }}.csv",
        poke_interval=60,       # Percenként ellenőriz
        timeout=3600,           # Max 1 óra – utána megbukik
        mode="reschedule",      # Hatékony: worker slot felszabadul poking közt
        soft_fail=False,
    )

    @task
    def process_file(ds: str = None) -> None:
        print(f"Fájl feldolgozása: orders_{ds}.csv")

    wait_for_file >> process_file()


file_triggered_pipeline()
