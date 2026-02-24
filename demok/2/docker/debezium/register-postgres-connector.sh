#!/bin/bash
# Debezium PostgreSQL connector regisztrálása
# Használat: bash register-postgres-connector.sh

echo "Waiting for Debezium Connect to start..."
until curl -s http://localhost:8083/connectors > /dev/null 2>&1; do
    sleep 2
done
echo "Debezium Connect is ready."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "webshop-connector",
    "config": {
      "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
      "database.hostname": "postgres",
      "database.port": "5432",
      "database.user": "dataeng",
      "database.password": "dataeng2024",
      "database.dbname": "webshop",
      "topic.prefix": "webshop",
      "plugin.name": "pgoutput",
      "publication.name": "dbz_publication",
      "slot.name": "debezium_slot",
      "schema.include.list": "public",
      "table.include.list": "public.customers,public.orders,public.order_items,public.products",
      "decimal.handling.mode": "double",
      "time.precision.mode": "connect"
    }
  }'

echo ""
echo "Connector registered. Check status:"
curl -s http://localhost:8083/connectors/webshop-connector/status | python3 -m json.tool
