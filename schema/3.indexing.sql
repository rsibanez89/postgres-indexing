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
    t.relname, -- Relation name
    t.relpages, -- Number of pages
    to_char(t.reltuples, '999,999,999') as reltuples, -- Number of rows
    t.relhasindex,  -- Has an index
    t.reltoastrelid::regclass, -- TOAST table
    ---
    i.indexrelid::regclass, -- Index name
    i.indisunique, -- Is unique index
    i.indisprimary, -- Is primary index
    i.indisclustered, -- Is clustered index
    i.indkey, -- Array of columns included in the index
    i.indpred,
    --
    ti.relpages, -- Number of pages of the index
    to_char(ti.reltuples, '999,999,999') as reltuples -- Number of rows of the index
FROM pg_class t
    JOIN pg_index i ON i.indrelid = t.oid
    JOIN pg_class ti ON i.indexrelid = ti.oid
WHERE t.relname = 'product';

--  relname | relpages |  reltuples   | relhasindex |      reltoastrelid      |  indexrelid  | indisunique | indisprimary | indisclustered | indkey | indpred
-- ---------+----------+--------------+-------------+-------------------------+--------------+-------------+--------------+----------------+--------+---------
--  product |    32769 |    1,999,957 | t           | pg_toast.pg_toast_32809 | product_pkey | t           | t            | f              | 1      |

-- We can see the number of pages 32769
-- We can see the number of tuples 1,999,957 (~2M rows)
-- We can see that the table has an index (unique index on id)
-- We cam see that the table has a TOAST table

SELECT
    t.relname, -- Relation name
    t.relpages, -- Number of pages
    to_char(t.reltuples, '999,999,999') as reltuples, -- Number of rows
    t.relhasindex,  -- Has an index
    t.reltoastrelid::regclass -- TOAST table
FROM
    pg_class t
WHERE relname = 'product_pkey';


-- EXPLAINER
EXPLAIN SELECT *
FROM product
WHERE store_id = 5;

--                            QUERY PLAN
-- -----------------------------------------------------------------
--  Seq Scan on product  (cost=0.00..57768.46 rows=204129 width=95)
--    Filter: (store_id = 5)
-- (2 rows)

-- The explain plan shows that the query will perform a sequential scan (Seq Scan) on the table product.
-- Cost 0.00 is the estimated start-up cost.
-- Cost 57768.46 is the estimated total cost.
-- Rows 204129 is the estimated number of rows output by this plan node.
-- Width 95 is the estimated average width of rows output by this plan node in bytes.

-- The cost is measured in units of disk page fetched.
-- More precicely, the cost formula: 
--   cost = seq_page_cost * #pages + cpu_tuple_cost * #total rows + cpu_operator_cost * #total rows
-- 
-- By default: 
--   seq_page_cost = 1.0
--   cpu_tuple_cost = 0.01 
--   cpu_operator_cost = 0.0025
-- 
-- Then: cost = 1.0 * 32769 + 0.01 * 1,999,957 + 0.0025 * 1,999,957 = 57768.4625 
