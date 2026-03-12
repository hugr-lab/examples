CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name TEXT
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name TEXT,
    category_id INTEGER REFERENCES categories(id),
    price FLOAT,
    data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name TEXT
);

CREATE TABLE product_tags (
    product_id INTEGER REFERENCES products(id),
    tag_id INTEGER REFERENCES tags(id),
    PRIMARY KEY (product_id, tag_id)
);

CREATE TABLE customer_groups (
    id SERIAL PRIMARY KEY,
    name TEXT
);

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    group_id INTEGER REFERENCES customer_groups(id),
    name TEXT,
    email TEXT UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    deleted_by TEXT
);

CREATE TABLE customer_addresses (
    code TEXT,
    customer_id INTEGER REFERENCES customers(id),
    address TEXT,
    geom GEOMETRY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    deleted_by TEXT,

    PRIMARY KEY (code, customer_id)
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    address_code TEXT,
    geom GEOMETRY,
    status TEXT,
    amount FLOAT
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER,
    price FLOAT,
    discount FLOAT,
    amount FLOAT
);