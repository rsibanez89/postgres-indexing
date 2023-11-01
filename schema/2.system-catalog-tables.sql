-- Table metadata is stored in system catalogs like:
-- pg_namespace
-- pg_class
-- pg_index
-- pg_attribute

SELECT nspname 
FROM pg_namespace; -- List all schemas

VACUUM customer; -- Update statistics

SELECT
    oid, -- Object identifier 
    relname, -- Relation name
    relkind, -- Table (r), Index (i), View (v), TOAST(t)  
    relpages, -- Number of pages
    reltuples, -- Number of rows
    relhasindex  -- Has an index
FROM pg_class 
WHERE relname = 'customer';

--   oid  | relname  | relkind | relpages | reltuples | relhasindex
-- -------+----------+---------+----------+-----------+-------------
--  32781 | customer | r       |        1 |        40 | f


CREATE INDEX ix_customer ON customer USING btree (id, email);

SELECT
	indisunique, -- Is unique
	indisprimary, -- Is primary key
	indisclustered, -- Is clustered
	indkey, -- Array of columns included in the index
	indpred -- Predicate for the index, example: price > 100
FROM pg_index
WHERE indexrelid = 'ix_customer'::regclass;

--  indisunique | indisprimary | indisclustered | indkey | indpred
-- -------------+--------------+----------------+--------+---------
--  f           | f            | f              | 1 3    |


SELECT
    attname, -- Column name
    atttypid::regtype, -- Column type
    attnum, -- Column number withing the table
    attnotnull, -- Not NULL Constraint
    attcompression, -- Compression
    attstorage -- plain(p), external (e), main (m), extended (x)
FROM pg_attribute
WHERE attrelid = 'customer'::regclass AND attnum > 0;

--   attname  |     atttypid      | attnum | attnotnull | attcompression | attstorage
-- -----------+-------------------+--------+------------+----------------+------------
--  id        | bigint            |      1 | t          |                | p
--  full_name | character varying |      2 | t          |                | x
--  email     | character varying |      3 | t          |                | x