-- Postgres page size: 8192 bytes (8 KB)

DROP SCHEMA IF EXISTS webstore CASCADE;
CREATE SCHEMA webstore;

SET schema 'webstore';

CREATE TABLE customer
(
    id BIGINT NOT NULL, -- 8 bytes
    full_name VARCHAR(100) NOT NULL, -- 100 bytes
    email VARCHAR(100) NOT NULL -- 100 bytes
); -- 208 bytes


INSERT INTO customer (id, full_name, email)
SELECT
    id,
    CONCAT('Customer ', id),
    CONCAT('customer', id, '@gmail.com')
FROM generate_series(1, 10) AS id;

-- 208 bytes x 10 rows = 2080 bytes

SELECT * FROM customer;

-- Most table statistics are updated by VACUUM, ANALYZE, and a few DDL commands such as CREATE INDEX.
VACUUM customer; -- Update statistics

SELECT pg_relation_size('customer'); -- 8192 bytes. Why?
-- The table main data size is 8192 bytes because it is the minimum size of a page in PostgreSQL.


INSERT INTO customer (id, full_name, email)
SELECT
    id,
    CONCAT('Customer ', id),
    CONCAT('customer', id, '@gmail.com')
FROM generate_series(11, 40) AS id;

-- 40 rows x 208 bytes = 8320 bytes

VACUUM customer; -- Update statistics

SELECT pg_relation_size('customer'); -- 8192 bytes. Why?
-- The table main data size is still 1 page, because some rows columns are using compression.
-- To see that let's go to the next script.



-- Also note that the total table size includes the main data, the free space map, the visibility map, the init fork, and the TOAST data. (except indexes)
SELECT pg_size_pretty(pg_relation_size('customer'));
SELECT
  pg_relation_size('customer', 'main') as main, -- The size of the main data.
  pg_relation_size('customer', 'fsm') as fsm, -- The free space map size. (FSM) is used to keep track of available space in the relation.
  pg_relation_size('customer', 'vm') as vm, -- The size of the visibility map (VM) for the relation. (VM) is used to keep track of which pages contain only tuples that are known to be visible to all active transactions
  pg_relation_size('customer', 'init') as init, 
  pg_table_size('customer'), 
  pg_indexes_size('customer') as indexes,
  pg_total_relation_size('customer') as total; -- Table size + indexes size

-- There is also an extension that can help you to see the table statistics.
CREATE EXTENSION pgstattuple;
SELECT * FROM pgstattuple('customer');