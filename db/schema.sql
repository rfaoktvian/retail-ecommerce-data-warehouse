-- ============================================================
-- schema.sql
-- Retail E-commerce Data Warehouse Portfolio
-- PostgreSQL Source Database (OLTP Layer)
--
-- Purpose:
-- - Create source tables for the ETL/ELT pipeline.
-- - Raw data is loaded from Olist CSV files.
-- - Additional sources (CSV & JSON) remain outside PostgreSQL
--   to simulate a multi-source data environment.
-- ============================================================

DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- ============================================================
-- customers
-- Source: olist_customers_dataset.csv
-- Primary Key: customer_id
-- ============================================================
CREATE TABLE customers (
    customer_id              VARCHAR(50) PRIMARY KEY,
    customer_unique_id       VARCHAR(50) NOT NULL,
    customer_zip_code_prefix VARCHAR(10),
    customer_city            VARCHAR(100),
    customer_state           VARCHAR(10)
);

CREATE INDEX idx_customers_unique_id
ON customers(customer_unique_id);

CREATE INDEX idx_customers_zip
ON customers(customer_zip_code_prefix);


-- ============================================================
-- products
-- Source: olist_products_dataset.csv
-- Product category translation is handled later in dbt.
-- ============================================================
CREATE TABLE products (
    product_id                 VARCHAR(50) PRIMARY KEY,
    product_category_name      VARCHAR(100),
    product_name_length        INT,
    product_description_length INT,
    product_photos_qty         INT,
    product_weight_g           NUMERIC(10,2),
    product_length_cm          NUMERIC(10,2),
    product_height_cm          NUMERIC(10,2),
    product_width_cm           NUMERIC(10,2)
);

CREATE INDEX idx_products_category_name
ON products(product_category_name);


-- ============================================================
-- orders
-- Source: olist_orders_dataset.csv
-- ============================================================
CREATE TABLE orders (
    order_id                       VARCHAR(50) PRIMARY KEY,
    customer_id                    VARCHAR(50) NOT NULL REFERENCES customers(customer_id),
    order_status                   VARCHAR(30) NOT NULL,
    order_purchase_timestamp       TIMESTAMP NOT NULL,
    order_approved_at              TIMESTAMP,
    order_delivered_carrier_date   TIMESTAMP,
    order_delivered_customer_date  TIMESTAMP,
    order_estimated_delivery_date  TIMESTAMP
);

CREATE INDEX idx_orders_customer_id
ON orders(customer_id);

CREATE INDEX idx_orders_purchase_ts
ON orders(order_purchase_timestamp);

CREATE INDEX idx_orders_status
ON orders(order_status);


-- ============================================================
-- order_items
-- Source: olist_order_items_dataset.csv
-- Composite Primary Key: (order_id, order_item_id)
-- seller_id references an external CSV source.
-- ============================================================
CREATE TABLE order_items (
    order_id            VARCHAR(50) REFERENCES orders(order_id),
    order_item_id       INT NOT NULL,
    product_id          VARCHAR(50) NOT NULL REFERENCES products(product_id),
    seller_id           VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(12,2) CHECK (price >= 0),
    freight_value       NUMERIC(12,2) DEFAULT 0,
    PRIMARY KEY (order_id, order_item_id)
);

CREATE INDEX idx_order_items_product_id
ON order_items(product_id);

CREATE INDEX idx_order_items_seller_id
ON order_items(seller_id);


-- ============================================================
-- order_payments
-- Source: olist_order_payments_dataset.csv
-- Composite Primary Key: (order_id, payment_sequential)
-- ============================================================
CREATE TABLE order_payments (
    order_id             VARCHAR(50) NOT NULL REFERENCES orders(order_id),
    payment_sequential   INT NOT NULL,
    payment_type         VARCHAR(30) NOT NULL,
    payment_installments INT DEFAULT 1,
    payment_value        NUMERIC(12,2) CHECK (payment_value >= 0),
    PRIMARY KEY (order_id, payment_sequential)
);