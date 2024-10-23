DROP SCHEMA IF EXISTS webstore CASCADE;
CREATE SCHEMA webstore;

SET schema 'webstore';

-- 1. Create a table with primary key and see the index creation:
CREATE TABLE IF NOT EXISTS customer
(
    id BIGINT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL
);

SELECT
    indexrelid::regclass,
	indisunique, -- Is unique
	indisprimary, -- Is primary key
	indisclustered, -- Is clustered
	indkey, -- Array of columns included in the index
	indpred -- Predicate for the index, example: price > 100
FROM pg_index i
    JOIN pg_class c ON c.oid = i.indrelid
WHERE c.relname = 'customer';


-- 2. Create a table that has plain storage and see the table size:
CREATE TABLE IF NOT EXISTS plain_storage
(
    id BIGINT NOT NULL, -- 8 bytes
    age INTEGER NOT NULL, -- 4 bytes
    deleted BOOLEAN NOT NULL -- 1 byte
);

INSERT INTO plain_storage (id, age, deleted)
SELECT
    id,
    id % 100,
    id % 2 = 0
FROM generate_series(1, 500) AS id; -- 13 bytes x 500 rows = 6500 bytes

VACUUM plain_storage; -- Update statistics

SELECT pg_relation_size('plain_storage'); -- 8192 bytes. Why?

-- Calculation would be:
-- PageHeaderData (24 bytes) 
-- ItemIdData (4 bytes) x 500 rows = 2000 bytes
-- HeapTupleHeaderData (31 bytes) + 13 bytes x 500 rows = 22000 bytes
-- Total = 24 + 2000 + 22000 = 24024 bytes


CREATE EXTENSION pgstattuple;
SELECT * FROM pgstattuple('plain_storage');

SELECT
    attname, -- Column name
    atttypid::regtype, -- Column type
    attnum, -- Column number within the table
    attlen, -- Length of the column type
    attnotnull, -- Not NULL constraint
    attcompression, -- Compression using the Lempel-Ziv algorithm (pglz, lz4 or none).
    attstorage -- plain(p), external (e), main (m), extended (x)
FROM pg_attribute
WHERE attrelid = 'plain_storage'::regclass AND attnum > 0;