-- Simulasi tabel sistem OLTP retail: order_items & payments
-- order_id, product_id, seller_id di sini WAJIB konsisten dengan
-- Olist dataset (sumber CRM & Product) sesuai ERD yang sudah didesain.

CREATE TABLE IF NOT EXISTS order_items (
    order_item_id   SERIAL PRIMARY KEY,
    order_id        VARCHAR(64) NOT NULL,
    product_id      VARCHAR(64) NOT NULL,
    seller_id       VARCHAR(64) NOT NULL,
    quantity        INT NOT NULL DEFAULT 1,
    price           NUMERIC(10,2) NOT NULL,
    freight_value   NUMERIC(10,2) NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payments (
    payment_id            SERIAL PRIMARY KEY,
    order_id              VARCHAR(64) NOT NULL,
    payment_sequential    INT NOT NULL DEFAULT 1,
    payment_type          VARCHAR(32) NOT NULL,
    payment_installments  INT NOT NULL DEFAULT 1,
    payment_value         NUMERIC(10,2) NOT NULL,
    created_at            TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items (order_id);
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments (order_id);
