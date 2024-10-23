-- System administration functions are functions that are used to manage the system.

-- Examples (calculate the size of a table):
--  * pg_relation_size('customer') → The size of the main data.
--  * pg_table_size('customer') → Will include main data + free space map (FSM) + visibility map (VM) + init.
--  * pg_total_relation_size('customer') → Is the table size + index size

-- The free space map (FSM) is used to keep track of available space in the relation, which PostgreSQL uses when deciding where to insert new rows.
-- The visibility map (VM) for the relation is used to keep track of which pages contain only rows that are visible to all active transactions. Useful for vacuuming and index-only scans. If all rows on a page are visible to all transactions, PostgreSQL can skip reading the heap page when scanning an index.
-- The init is only for unlogged tables and indexes, used to store the initial state of the relation so that PostgreSQL can restore it after a crash

-- Visual example:
-- |-------------------------
-- |       table size       |  
-- |------------------------------------------| 
-- | main | fsm | vm | init | toast | indexes |
-- |------------------------------------------|
-- |           total relation size            |
-- |------------------------------------------|


-- Also note that:
-- The table size includes the main data, the free space map, the visibility map and the init fork. Excluding the toast table and the indexes.
-- Total relation size = main + fsm + vm + init + toast + indexes
SELECT
  pg_relation_size('customer') as main, -- This returns the size of the main data by default.
  pg_relation_size('customer', 'main') as main, -- The size of the main data.
  pg_relation_size('customer', 'fsm') as fsm, -- The free space map size. (FSM)
  pg_relation_size('customer', 'vm') as vm, -- The size of the visibility map (VM)
  pg_relation_size('customer', 'init') as init, -- The size of the init fork. 
  pg_table_size('customer') as table, -- Main data + FSM + VM + init
  pg_indexes_size('customer') as indexes,
  pg_total_relation_size('customer') as total -- Table size + indexes size
;

-- Pretty size
SELECT
  pg_size_pretty(pg_relation_size('customer')) as main,
  pg_size_pretty(pg_relation_size('customer', 'main')) as main,
  pg_size_pretty(pg_relation_size('customer', 'fsm')) as fsm,
  pg_size_pretty(pg_relation_size('customer', 'vm')) as vm,
  pg_size_pretty(pg_relation_size('customer', 'init')) as init,
  pg_size_pretty(pg_table_size('customer')) as table,
  pg_size_pretty(pg_indexes_size('customer')) as indexes,
  pg_size_pretty(pg_total_relation_size('customer')) as total
;


-- There is also an extension that can help you to see the table statistics.
CREATE EXTENSION pgstattuple;
SELECT * FROM pgstattuple('customer');
-- table_len: 8192 bytes
-- tuple_count: 40
-- tuple_len: 2582 bytes / 40 rows = 64.55 bytes per row
-- tuple_percent: 31.52% (2582 / 8192)
-- dead_tuple_count: 0 (No dead tuples)
-- dead_tuple_percent: 0.00%
-- free_space: 5196 bytes (63.42%) (8192 - 2582)

-- Get the size of a tuple by adding the size of each column
-- Keep in mind that this approach gives you an estimate of the size of the tuple 
-- It only considers the actual data and doesn't include any additional overhead or padding
SELECT 
  pg_column_size(id) +
  pg_column_size(full_name) +
  pg_column_size(email) AS tuple_size
FROM customer;
