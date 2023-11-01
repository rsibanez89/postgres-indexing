SET schema 'webstore';

-- Postgres page size: 8192 bytes (8 KB)

-- Size of the table product (2M rows)
SELECT pg_size_pretty(pg_table_size('product')); -- 292MB
-- Including indexes and TOAST data
SELECT pg_size_pretty(pg_total_relation_size('product')); -- 335MB

-- Number of pages in the table product
SELECT
    oid, -- Object identifier 
    relname, -- Relation name
    relkind, -- Table (r), Index (i), View (v), TOAST(t)  
    relpages, -- Number of pages
    to_char(reltuples, '999,999,999') as reltuples, -- Number of rows
    relhasindex,  -- Has an index
    reltoastrelid::regclass -- TOAST table
FROM pg_class 
WHERE relname = 'product';

-- We can see the number of pages 37366
-- We can see the number of tuples 1,999,681 (~2M rows)
-- We can see that the table has an index (unique index on id)
-- We cam see that the table has a TOAST table


-- Given that the table product is a Heap, getting the rows that belong to the store with id 1 requires a full table scan.
EXPLAIN SELECT * FROM product WHERE storeid = 1;
--                             QUERY PLAN
-- ------------------------------------------------------------------
--  Seq Scan on product  (cost=0.00..62362.01 rows=202701 width=113)
--    Filter: (storeid = 1)
-- (2 rows)

-- The explain plan shows that the query will perform a sequential scan (Seq Scan) on the table product.
-- Cost 0.00 is the estimated start-up cost.
-- Cost 62362.01 is the estimated total cost.
-- *** The cost is measured in number of disk page fetched. ***
-- Rows 202701 is the estimated number of rows output by this plan node.
-- Width 113 is the estimated average width of rows output by this plan node in bytes.

EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM product WHERE storeid = 1;
--                                                     QUERY PLAN
-- -------------------------------------------------------------------------------------------------------------------
--  Seq Scan on product  (cost=0.00..62366.00 rows=202733 width=113) (actual time=0.065..394.755 rows=200000 loops=1)
--    Filter: (storeid = 1)
--    Rows Removed by Filter: 1800000
--    Buffers: shared hit=64 read=37302
--  Planning:
--    Buffers: shared hit=53 read=1
--  Planning Time: 0.281 ms
--  Execution Time: 403.780 ms
-- (8 rows)