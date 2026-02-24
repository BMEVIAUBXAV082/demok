-- BME Data Engineering – Week 02: Webshop séma
-- PostgreSQL 16 | CDC-kompatibilis (WAL logical)

-- Ügyfelek
CREATE TABLE customers (
    customer_id   SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(150) UNIQUE NOT NULL,
    city          VARCHAR(80),
    segment       VARCHAR(30) DEFAULT 'standard',
    created_at    TIMESTAMP DEFAULT now(),
    updated_at    TIMESTAMP DEFAULT now()
);

-- Termékek
CREATE TABLE products (
    product_id    SERIAL PRIMARY KEY,
    name          VARCHAR(200) NOT NULL,
    category      VARCHAR(80) NOT NULL,
    price         NUMERIC(10,2) NOT NULL,
    stock         INTEGER DEFAULT 0,
    created_at    TIMESTAMP DEFAULT now()
);

-- Rendelések
CREATE TABLE orders (
    order_id      SERIAL PRIMARY KEY,
    customer_id   INTEGER REFERENCES customers(customer_id),
    order_date    TIMESTAMP DEFAULT now(),
    status        VARCHAR(30) DEFAULT 'pending',
    total_amount  NUMERIC(12,2),
    shipping_city VARCHAR(80)
);

-- Rendelés tételek
CREATE TABLE order_items (
    item_id       SERIAL PRIMARY KEY,
    order_id      INTEGER REFERENCES orders(order_id),
    product_id    INTEGER REFERENCES products(product_id),
    quantity      INTEGER NOT NULL,
    unit_price    NUMERIC(10,2) NOT NULL
);

-- Események (append-only log)
CREATE TABLE events (
    event_id      BIGSERIAL PRIMARY KEY,
    event_type    VARCHAR(50) NOT NULL,
    entity_type   VARCHAR(30),
    entity_id     INTEGER,
    payload       JSONB,
    created_at    TIMESTAMP DEFAULT now()
);

-- Indexek
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_created ON events(created_at);

-- Logikai replikáció publikáció (CDC-hez)
CREATE PUBLICATION dbz_publication FOR ALL TABLES;
