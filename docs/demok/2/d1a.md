# Demo 1a: Forrásrendszerek feltárása és Python natív CDC

## Áttekintés

Ez a demó bemutatja, hogyan térképezzük fel egy PostgreSQL forrásrendszert mérnöki szempontból, és hogyan valósítunk meg natív Python CDC-t (Change Data Capture) a WAL (Write-Ahead Log) logical replication segítségével.

!!! info "Előfeltételek"
    A Docker környezet fut (`docker compose up -d`), a PostgreSQL adatbázis elérhető.

## Indítás

```bash
# Docker környezet indítása
cd week02/docker
docker compose up -d

# Jupyter notebook megnyitása
# Böngészőben: http://localhost:8888 (token: bme2024)
```

## A demó lépései

### 1. Séma feltérképezés (Schema Discovery)

A forrásrendszer feltérképezése az első lépés minden adatmérnöki projektben:

- **Táblák listázása**: `pg_tables` rendszertáblából
- **Oszlop részletek**: `information_schema.columns`
- **Sorszámok**: `COUNT(*)` minden táblára

```sql
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname = 'public';
```

!!! tip "Gyakorlati tanács"
    Éles környezetben a séma discovery automatizált: metadata catalog (DataHub, Amundsen) vagy dbt docs használata javasolt.

### 2. Adatprofiling

Az adatprofiling célja a forrásadatok jellemzőinek megértése:

- **Eloszlások**: szegmens, város, státusz szerinti csoportosítás
- **Statisztikák**: min/max/átlag rendelési összeg, időszak
- **Anomáliák**: kiugró értékek, üres mezők

### 3. Adatminőségi ellenőrzések

Öt minőségi ellenőrzés a forráson:

| Ellenőrzés | SQL logika | Elvárt |
|-----------|-----------|--------|
| NULL email | `WHERE email IS NULL` | 0 |
| Duplikált email | `COUNT(*) - COUNT(DISTINCT email)` | 0 |
| Árva rendelés | `LEFT JOIN` ügyfél nélkül | 0 |
| Negatív összeg | `WHERE total_amount < 0` | 0 |
| Jövőbeli dátum | `WHERE order_date > now()` | 0 |

!!! warning "Fontos"
    Az adatminőségi ellenőrzéseket a pipeline részeként kell futtatni, nem csak egyszeri vizsgálatként!

### 4. Pull vs Push: SQL Polling vs CDC

**SQL Polling (Pull)**:

- Periodikus `SELECT` lekérdezések
- Késleltetés a polling intervallumtól függ
- Terhelés a forrásrendszeren
- Nem látja a köztes állapotokat (UPDATE→UPDATE)

**CDC (Push)**:

- WAL-ból olvassa a változásokat
- Valós idejű (ms-es késleltetés)
- Minimális terhelés a forrásrendszeren
- Minden változás látható (before/after)

### 5. Natív Python CDC

A PostgreSQL `pgoutput` plugin és a `psycopg2` `LogicalReplicationConnection` segítségével:

```python
# Replication slot létrehozása
rep_cur.create_replication_slot("demo1a_slot", output_plugin="pgoutput")

# CDC stream indítása
rep_cur.start_replication(
    slot_name="demo1a_slot",
    decode=True,
    options={"proto_version": "1", "publication_names": "dbz_publication"}
)
```

A demóban végrehajtunk INSERT, UPDATE és DELETE műveleteket, majd megfigyeljük a CDC eseményeket.

## Kulcsfontosságú tanulságok

1. A **séma discovery** automatizálása időt takarít meg és csökkenti a hibákat
2. Az **adatprofiling** elengedhetetlen a forrásadatok megértéséhez
3. A **minőségi ellenőrzések** a pipeline részei kell legyenek
4. A **CDC** hatékonyabb és valós idejűbb mint a polling
5. A natív CDC egyszerű, de ipari környezetben **Debezium** javasolt (→ Demo 1b)

## Kapcsolódó notebook

A teljes futtatható kód a `demo1a-source-discovery.ipynb` Jupyter notebookban található.
