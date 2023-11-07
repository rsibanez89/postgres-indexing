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

 relname | relpages |  reltuples   | relhasindex |      reltoastrelid      |  indexrelid  | indisunique | indisprimary | indisclustered | indkey | indpred | relpages |  reltuples
---------+----------+--------------+-------------+-------------------------+--------------+-------------+--------------+----------------+--------+---------+----------+--------------
 product |        0 |           -1 | t           | pg_toast.pg_toast_40971 | product_pkey | t           | t            | f              | 1      |         |        1 |       0
(1 row)

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


-- EXPLAINER ANALYSE
EXPLAIN (BUFFERS, ANALYSE) SELECT *
FROM product
WHERE store_id = 5;

--                                                     QUERY PLAN
-- ------------------------------------------------------------------------------------------------------------------
--  Seq Scan on product  (cost=0.00..57768.46 rows=204129 width=95) (actual time=5.061..844.845 rows=200000 loops=1)
--    Filter: (store_id = 5)
--    Rows Removed by Filter: 1800000
--    Buffers: shared read=32769
--  Planning Time: 0.101 ms
--  Execution Time: 852.886 ms
-- (6 rows)

-- Adding Buffers and Analyse to the explain command, we can see the actual time and the actual number of rows.
-- We can see that the query took 844.845 ms to execute.
-- Buffers shows that the query read 32769 pages, as expected.
-- We can see that the query returned 200000 rows, as expected.


-- Let's create an index
CREATE INDEX ix_product
ON product
USING btree (store_id);

-- EXPLAINER ANALYSE
EXPLAIN (BUFFERS, ANALYSE) SELECT *
FROM product
WHERE store_id = 5;

--                                                            QUERY PLAN
-- --------------------------------------------------------------------------------------------------------------------------------
--  Bitmap Heap Scan on product  (cost=2278.46..37599.12 rows=204133 width=95) (actual time=14.175..392.808 rows=200000 loops=1)
--    Recheck Cond: (store_id = 5)
--    Heap Blocks: exact=32769
--    Buffers: shared hit=3 read=32941
--    ->  Bitmap Index Scan on ix_product  (cost=0.00..2227.42 rows=204133 width=0) (actual time=9.767..9.767 rows=200000 loops=1)
--          Index Cond: (store_id = 5)
--          Buffers: shared hit=3 read=172
--  Planning:
--    Buffers: shared hit=76 read=23
--  Planning Time: 4.695 ms
--  Execution Time: 399.020 ms
-- (11 rows)

-- After the index on store_id was created, we can se that the query took 392.808 ms to execute.
-- The query initially use the indes ix_product to find the rows that match the condition store_id = 5.
-- For each row found, the query access the table product to get the other columns.


-- CLUSTERING
CLUSTER product USING ix_product;

-- EXPLAINER ANALYSE
EXPLAIN (BUFFERS, ANALYSE) SELECT *
FROM product
WHERE store_id = 5;

--                                                            QUERY PLAN
-- --------------------------------------------------------------------------------------------------------------------------------
--  Bitmap Heap Scan on product  (cost=2278.46..37599.12 rows=204133 width=95) (actual time=5.576..20.720 rows=200000 loops=1)
--    Recheck Cond: (store_id = 5)
--    Heap Blocks: exact=3278
--    Buffers: shared read=3450
--    ->  Bitmap Index Scan on ix_product  (cost=0.00..2227.42 rows=204133 width=0) (actual time=5.215..5.216 rows=200000 loops=1)
--          Index Cond: (store_id = 5)
--          Buffers: shared read=172
--  Planning:
--    Buffers: shared hit=20 read=2
--  Planning Time: 0.207 ms
--  Execution Time: 25.357 ms

-- After the table has been clustered, we can see that the query took 25.375 ms to execute.  