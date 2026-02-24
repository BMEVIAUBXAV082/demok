-- BME Data Engineering – Week 02: Mintaadatok
-- ~500 sor e-commerce adat

-- ── Ügyfelek (30 fő) ───────────────────────────────────────────
INSERT INTO customers (name, email, city, segment) VALUES
('Kovács Anna', 'kovacs.anna@example.com', 'Budapest', 'premium'),
('Nagy Péter', 'nagy.peter@example.com', 'Debrecen', 'standard'),
('Szabó Katalin', 'szabo.katalin@example.com', 'Szeged', 'premium'),
('Tóth László', 'toth.laszlo@example.com', 'Pécs', 'standard'),
('Horváth Gábor', 'horvath.gabor@example.com', 'Győr', 'standard'),
('Varga Éva', 'varga.eva@example.com', 'Budapest', 'premium'),
('Kiss Márton', 'kiss.marton@example.com', 'Miskolc', 'standard'),
('Molnár Zsófia', 'molnar.zsofia@example.com', 'Budapest', 'gold'),
('Németh Balázs', 'nemeth.balazs@example.com', 'Debrecen', 'standard'),
('Farkas Judit', 'farkas.judit@example.com', 'Szeged', 'standard'),
('Balogh Tamás', 'balogh.tamas@example.com', 'Pécs', 'premium'),
('Papp Ildikó', 'papp.ildiko@example.com', 'Győr', 'standard'),
('Takács Dávid', 'takacs.david@example.com', 'Budapest', 'standard'),
('Juhász Réka', 'juhasz.reka@example.com', 'Kecskemét', 'standard'),
('Lakatos Ferenc', 'lakatos.ferenc@example.com', 'Nyíregyháza', 'gold'),
('Simon Orsolya', 'simon.orsolya@example.com', 'Budapest', 'premium'),
('Oláh András', 'olah.andras@example.com', 'Székesfehérvár', 'standard'),
('Fekete Noémi', 'fekete.noemi@example.com', 'Eger', 'standard'),
('Szűcs Krisztián', 'szucs.krisztian@example.com', 'Budapest', 'standard'),
('Mészáros Boglárka', 'meszaros.boglarka@example.com', 'Debrecen', 'premium'),
('Pintér Gergő', 'pinter.gergo@example.com', 'Veszprém', 'standard'),
('Török Anita', 'torok.anita@example.com', 'Budapest', 'standard'),
('Vincze Levente', 'vincze.levente@example.com', 'Miskolc', 'standard'),
('Hegedűs Emese', 'hegedus.emese@example.com', 'Szeged', 'gold'),
('Kocsis Norbert', 'kocsis.norbert@example.com', 'Pécs', 'standard'),
('Szilágyi Dóra', 'szilagyi.dora@example.com', 'Budapest', 'premium'),
('Hajdu Bence', 'hajdu.bence@example.com', 'Debrecen', 'standard'),
('Gál Vivien', 'gal.vivien@example.com', 'Győr', 'standard'),
('Antal Zoltán', 'antal.zoltan@example.com', 'Budapest', 'standard'),
('Kelemen Lilla', 'kelemen.lilla@example.com', 'Szeged', 'premium');

-- ── Termékek (25 tétel) ─────────────────────────────────────────
INSERT INTO products (name, category, price, stock) VALUES
('Laptop ASUS VivoBook 15', 'Elektronika', 249990, 45),
('Samsung Galaxy S24', 'Mobiltelefon', 349990, 120),
('Sony WH-1000XM5 fejhallgató', 'Audio', 129990, 80),
('Logitech MX Master 3S egér', 'Periféria', 39990, 200),
('Dell UltraSharp 27" monitor', 'Monitor', 189990, 30),
('Apple iPad Air 2024', 'Tablet', 279990, 55),
('Kindle Paperwhite', 'E-könyvolvasó', 49990, 150),
('JBL Charge 5 hangszóró', 'Audio', 44990, 90),
('Razer BlackWidow V4 billentyűzet', 'Periféria', 54990, 60),
('TP-Link Archer AX73 router', 'Hálózat', 29990, 100),
('WD Elements 2TB külső HDD', 'Tárhely', 24990, 180),
('Samsung 970 EVO Plus 1TB SSD', 'Tárhely', 39990, 120),
('Xiaomi Mi Band 8', 'Viselhető', 14990, 300),
('Canon EOS R50 fényképezőgép', 'Fotó', 299990, 20),
('Anker PowerCore 20000 powerbank', 'Kiegészítő', 12990, 250),
('Philips Hue Starter Kit', 'Okosotthon', 34990, 70),
('iRobot Roomba i3+', 'Háztartás', 159990, 25),
('Dyson V12 porszívó', 'Háztartás', 219990, 15),
('Nintendo Switch OLED', 'Játék', 129990, 40),
('PlayStation 5 DualSense kontroller', 'Játék', 24990, 110),
('Bosch Serie 6 mosogatógép', 'Háztartás', 189990, 10),
('LG OLED C3 55" TV', 'TV', 499990, 18),
('Bose QuietComfort Ultra', 'Audio', 149990, 50),
('Garmin Venu 3 okosóra', 'Viselhető', 149990, 35),
('Raspberry Pi 5 8GB', 'Elektronika', 29990, 200);

-- ── Rendelések (100 db, elmúlt 90 nap) ─────────────────────────
DO $$
DECLARE
    i INTEGER;
    cust_id INTEGER;
    ord_date TIMESTAMP;
    ord_status VARCHAR(30);
    statuses VARCHAR(30)[] := ARRAY['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
BEGIN
    FOR i IN 1..100 LOOP
        cust_id := (i % 30) + 1;
        ord_date := now() - (random() * 90)::INTEGER * INTERVAL '1 day' - (random() * 24)::INTEGER * INTERVAL '1 hour';
        ord_status := statuses[1 + (random() * 4)::INTEGER];

        INSERT INTO orders (customer_id, order_date, status, total_amount, shipping_city)
        SELECT cust_id, ord_date, ord_status, 0, c.city
        FROM customers c WHERE c.customer_id = cust_id;
    END LOOP;
END $$;

-- ── Rendeléstételek (1-3 tétel rendelésenként, ~250 sor) ───────
DO $$
DECLARE
    ord RECORD;
    num_items INTEGER;
    j INTEGER;
    prod_id INTEGER;
    qty INTEGER;
    uprice NUMERIC;
    ord_total NUMERIC;
BEGIN
    FOR ord IN SELECT order_id FROM orders LOOP
        num_items := 1 + (random() * 2)::INTEGER;
        ord_total := 0;
        FOR j IN 1..num_items LOOP
            prod_id := 1 + (random() * 24)::INTEGER;
            qty := 1 + (random() * 2)::INTEGER;
            SELECT price INTO uprice FROM products WHERE products.product_id = prod_id;
            INSERT INTO order_items (order_id, product_id, quantity, unit_price)
            VALUES (ord.order_id, prod_id, qty, uprice);
            ord_total := ord_total + (uprice * qty);
        END LOOP;
        UPDATE orders SET total_amount = ord_total WHERE orders.order_id = ord.order_id;
    END LOOP;
END $$;

-- ── Események (append-only log, ~100 esemény) ──────────────────
DO $$
DECLARE
    ord RECORD;
    evt_types VARCHAR(50)[] := ARRAY['order_created', 'payment_received', 'item_shipped', 'item_delivered'];
    evt_type VARCHAR(50);
BEGIN
    FOR ord IN SELECT order_id, customer_id, order_date, status FROM orders LIMIT 80 LOOP
        evt_type := evt_types[1 + (random() * 3)::INTEGER];
        INSERT INTO events (event_type, entity_type, entity_id, payload, created_at)
        VALUES (
            evt_type,
            'order',
            ord.order_id,
            json_build_object('customer_id', ord.customer_id, 'status', ord.status)::jsonb,
            ord.order_date + (random() * 60)::INTEGER * INTERVAL '1 minute'
        );
    END LOOP;
END $$;
