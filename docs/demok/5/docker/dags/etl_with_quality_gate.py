"""
Demo 5 – ETL pipeline adatminőség gate-tel (Great Expectations)
Kapcsolódó: demo5-cicd.md
"""
from airflow.decorators import dag, task
from datetime import datetime
import duckdb


@dag(
    dag_id="etl_with_quality_gate",
    schedule="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["week05", "demo5"],
)
def etl_quality_pipeline():

    @task
    def extract(ds: str = None) -> list[dict]:
        import random
        return [{"id": i, "amount": round(random.uniform(100, 50000), 2),
                 "date": ds} for i in range(1, 51)]

    @task
    def data_quality_check(records: list[dict], ds: str = None) -> list[dict]:
        """Great Expectations adatminőség ellenőrzés."""
        import pandas as pd
        import great_expectations as gx

        df = pd.DataFrame(records)
        context = gx.get_context(mode="ephemeral")
        ds_gx  = context.sources.add_pandas("orders_source")
        da     = ds_gx.add_dataframe_asset("orders")
        batch  = da.build_batch_request(dataframe=df)
        suite  = context.add_expectation_suite("orders_suite")

        validator = context.get_validator(
            batch_request=batch,
            expectation_suite_name="orders_suite",
        )
        validator.expect_column_values_to_not_be_null("id")
        validator.expect_column_values_to_not_be_null("amount")
        validator.expect_column_values_to_be_between("amount", min_value=0)
        results = validator.validate()

        if not results["success"]:
            failed = [r for r in results["results"] if not r["success"]]
            raise ValueError(
                f"Adatminőség ellenőrzés MEGBUKOTT: {len(failed)} elvárás nem teljesült"
            )
        print(f"Adatminőség OK: {len(records)} rekord validálva")
        return records

    @task
    def load(records: list[dict], ds: str = None) -> None:
        con = duckdb.connect("/tmp/orders.duckdb")
        con.execute("CREATE TABLE IF NOT EXISTS orders (id INT, amount FLOAT, date VARCHAR)")
        con.execute("DELETE FROM orders WHERE date = ?", [ds])
        con.executemany(
            "INSERT INTO orders VALUES (?, ?, ?)",
            [(r["id"], r["amount"], r["date"]) for r in records]
        )
        print(f"Betöltve: {len(records)} sor ({ds})")

    @task(trigger_rule="one_failed")
    def send_alert(ds: str = None) -> None:
        """Csak akkor fut, ha valamelyik upstream task megbukott."""
        print(f"ALERT: pipeline megbukott {ds}-n")

    raw   = extract()
    valid = data_quality_check(raw)
    load(valid)
    send_alert()


etl_quality_pipeline()
