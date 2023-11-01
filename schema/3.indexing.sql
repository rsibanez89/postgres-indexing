DROP SCHEMA IF EXISTS webstore CASCADE;
CREATE SCHEMA webstore;

SET schema 'webstore';

CREATE TABLE product
(
    id SERIAL PRIMARY KEY,
    store_id BIGINT NOT NULL,
    name VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    image_url VARCHAR(400) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    stock INTEGER NOT NULL
);

INSERT INTO product (store_id, name, description, image_url, price, stock)
SELECT
    id % 10 + 1,
    CONCAT('Product ', id),
    CONCAT('Description ', id),
    CONCAT('https://example.com/product/', id, '.jpg'),
    random() * 100,
    random() * 100
FROM generate_series(1, 2000000) AS id;

SELECT * FROM product LIMIT 3;
--  id | store_id |   name    |  description  |             image_url             | price | stock
-- ----+----------+-----------+---------------+-----------------------------------+-------+-------
--   1 |        2 | Product 1 | Description 1 | https://example.com/product/1.jpg | 43.27 |     1
--   2 |        3 | Product 2 | Description 2 | https://example.com/product/2.jpg | 57.18 |    96
--   3 |        4 | Product 3 | Description 3 | https://example.com/product/3.jpg | 24.24 |    14

SELECT count(*) FROM product; -- 2M rows


-- Number of pages in the table product
SELECT
    oid, -- Object identifier 
    relname, -- Relation name
    relkind, -- Table (r), Index (i), View (v), TOAST(t)  
    relpages, -- Number of pages
    to_char(reltuples, '999,999,999') as reltuples, -- Number of rows
    relhasindex  -- Has an index
    --,reltoastrelid::regclass -- TOAST table
FROM pg_class 
WHERE relname = 'product';

--   oid  | relname | relkind | relpages |  reltuples   | relhasindex |      reltoastrelid
-- -------+---------+---------+----------+--------------+-------------+-------------------------
--  32809 | product | r       |    32769 |    1,999,957 | t           | pg_toast.pg_toast_32809

-- We can see the number of pages 32769
-- We can see the number of tuples 1,999,957 (~2M rows)
-- We can see that the table has an index (unique index on id)
-- We cam see that the table has a TOAST table