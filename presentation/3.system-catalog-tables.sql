-- Table metadata is stored in system catalogs like:
-- pg_namespace
-- pg_class
-- pg_index
-- pg_attribute

SELECT nspname 
FROM pg_namespace; -- List all schemas

--       nspname       
-- --------------------
--  pg_toast
--  pg_catalog
--  public
--  information_schema
--  webstore

-- The default schemas are:
-- * pg_toast: TOAST (The Oversized-Attribute Storage Technique) tables are used to store large values that are compressed and/or broken up into smaller pieces.
-- * pg_catalog: System catalog tables are stored in this schema. For example, pg_namespace, pg_class, pg_attribute, pg_index, pg_type, etc.
-- * public: The default schema for new tables.
-- * information_schema: A standard schema that is part of the SQL standard. It contains views that provide information about the database system.

SELECT
    table_catalog, -- Database name
    table_schema, -- Schema name
    table_name, -- Table name
    table_type, -- BASE TABLE, VIEW, TEMPORARY, etc
    is_insertable_into -- Is read-only or not
FROM information_schema.tables;

VACUUM customer; -- Update statistics

SELECT
    oid, -- Object identifier 
    relnamespace::regnamespace, -- Schema
    relname, -- Relation name
    relkind, -- Table (r), Index (i), View (v), TOAST(t)  
    relpages, -- Number of pages
    reltuples, -- Number of rows
    relhasindex,  -- Has an index
    relfilenode -- File node number, start of the relation.
FROM pg_class 
WHERE relnamespace::regnamespace = 'webstore'::regnamespace;

--   oid  | relnamespace | relname  | relkind | relpages | reltuples | relhasindex | relfilenode 
-- -------+--------------+----------+---------+----------+-----------+-------------+-------------
--  16514 | webstore     | customer | r       |        1 |        40 | f           |       16514


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
    attnum, -- Column number within the table
    attlen, -- Length of the column type
    attnotnull, -- Not NULL constraint
    attcompression, -- Compression using the Lempel-Ziv algorithm (pglz, lz4 or none).
    attstorage -- plain(p), external (e), main (m), extended (x)
FROM pg_attribute
WHERE attrelid = 'customer'::regclass AND attnum > 0;

--   attname  |     atttypid      | attnum | attlen | attnotnull | attcompression | attstorage 
-- -----------+-------------------+--------+--------+------------+----------------+------------
--  id        | bigint            |      1 |      8 | t          |                | p
--  full_name | character varying |      2 |     -1 | t          |                | x
--  email     | character varying |      3 |     -1 | t          |                | x

-- attlen: -1 means variable length

-- For attstorage, the storage strategy types are:
--  * plain (p): prevents either compression or out-of-line storage. Is used for fixed value length like INTEGER, CHAR, BOOLEAN, etc.
--  * external (e) allows out-of-line storage but not compression. It could be used for BLOB data if we need to store it uncompressed on a different file.
--  * main allows compression but not out-of-line storage. Is used for numeric and decimal.  (* it will allow out-of-line storage when the row is too big to fit in 1 page, postgres won’t break for this).
--  * extended (x) allows both compression and out-of-line storage. Is the default strategy for TOAST-able data types like VARCHAR, TEXT, JSON. Compression will be attempted first, then out-of-line storage if the row is still too big.

-- The default storage strategy for BLOB (BYTEA) is extended (x).
-- You can change the storage strategy for a column using ALTER TABLE your_table ALTER COLUMN your_column SET STORAGE EXTERNAL;


-- Let's see what is the default storage strategy for each data type

SELECT
    typname, -- Data type name
    typtype, -- b (base), c (composite), d (domain), e (enum), p (pseudo-type), r (range)
    typstorage -- plain(p), external (e), main (m), extended (x)
FROM pg_type;

--                 typname                 | typtype | typstorage
-- ----------------------------------------+---------+------------
--  bool                                   | b       | p
--  bytea                                  | b       | x
--  char                                   | b       | p
--  name                                   | b       | p
--  int8                                   | b       | p
--  int2                                   | b       | p
--  int2vector                             | b       | p
--  int4                                   | b       | p
--  regproc                                | b       | p
--  text                                   | b       | x
--  oid                                    | b       | p
--  tid                                    | b       | p
--  xid                                    | b       | p
--  cid                                    | b       | p
--  oidvector                              | b       | p
--  pg_type                                | c       | x
--  pg_attribute                           | c       | x
--  pg_proc                                | c       | x
--  pg_class                               | c       | x
--  json                                   | b       | x
--  xml                                    | b       | x
--  pg_node_tree                           | b       | x
--  pg_ndistinct                           | b       | x
--  pg_dependencies                        | b       | x
--  pg_mcv_list                            | b       | x
--  pg_ddl_command                         | p       | p
--  xid8                                   | b       | p
--  point                                  | b       | p
--  lseg                                   | b       | p
--  path                                   | b       | x
--  box                                    | b       | p
--  polygon                                | b       | x
--  line                                   | b       | p
--  float4                                 | b       | p
--  float8                                 | b       | p
--  unknown                                | p       | p
--  circle                                 | b       | p
--  money                                  | b       | p
--  macaddr                                | b       | p
--  inet                                   | b       | m
--  cidr                                   | b       | m
--  macaddr8                               | b       | p
--  aclitem                                | b       | p
--  bpchar                                 | b       | x
--  varchar                                | b       | x
--  date                                   | b       | p
--  time                                   | b       | p
--  timestamp                              | b       | p
--  timestamptz                            | b       | p
--  interval                               | b       | p
--  timetz                                 | b       | p
--  bit                                    | b       | x
--  varbit                                 | b       | x
--  numeric                                | b       | m
--  refcursor                              | b       | x
--  regprocedure                           | b       | p
--  regoper                                | b       | p
--  regoperator                            | b       | p
--  regclass                               | b       | p
--  regcollation                           | b       | p
--  regtype                                | b       | p
--  regrole                                | b       | p
--  regnamespace                           | b       | p
--  uuid                                   | b       | p
--  pg_lsn                                 | b       | p
--  tsvector                               | b       | x
--  gtsvector                              | b       | p
--  tsquery                                | b       | p
--  regconfig                              | b       | p
--  regdictionary                          | b       | p
--  jsonb                                  | b       | x
--  jsonpath                               | b       | x
--  txid_snapshot                          | b       | x
--  pg_snapshot                            | b       | x
--  int4range                              | r       | x
--  numrange                               | r       | x
--  tsrange                                | r       | x
--  tstzrange                              | r       | x
--  daterange                              | r       | x
--  int8range                              | r       | x
--  int4multirange                         | m       | x
--  nummultirange                          | m       | x
--  tsmultirange                           | m       | x
--  tstzmultirange                         | m       | x
--  datemultirange                         | m       | x
--  int8multirange                         | m       | x
--  record                                 | p       | x
--  _record                                | p       | x
--  cstring                                | p       | p
--  any                                    | p       | p
--  anyarray                               | p       | x
--  void                                   | p       | p
--  trigger                                | p       | p
--  event_trigger                          | p       | p
--  language_handler                       | p       | p
--  internal                               | p       | p
--  anyelement                             | p       | p
--  anynonarray                            | p       | p
--  anyenum                                | p       | p
--  fdw_handler                            | p       | p
--  index_am_handler                       | p       | p
--  tsm_handler                            | p       | p
--  table_am_handler                       | p       | p
--  anyrange                               | p       | x
--  anycompatible                          | p       | p
--  anycompatiblearray                     | p       | x
--  anycompatiblenonarray                  | p       | p
--  anycompatiblerange                     | p       | x
--  anymultirange                          | p       | x
--  anycompatiblemultirange                | p       | x
--  pg_brin_bloom_summary                  | b       | x
--  pg_brin_minmax_multi_summary           | b       | x


CREATE TABLE simple_type_check (
    oid OID NOT NULL,
    boolean BOOLEAN NOT NULL,
    integer INTEGER NOT NULL,
    bigint BIGINT NOT NULL,
    numeric NUMERIC(10,2) NOT NULL,
    decimal DECIMAL(10,2) NOT NULL,
    json JSON NOT NULL,
    jsonb JSONB NOT NULL,
    text TEXT NOT NULL,
    varchar VARCHAR(100) NOT NULL,
    uuid UUID NOT NULL,
    inet INET NOT NULL,
    blob BYTEA NOT NULL
);

SELECT
    attname, -- Column name
    attstorage -- plain(p), external (e), main (m), extended (x)
FROM pg_attribute
WHERE attrelid = 'simple_type_check'::regclass AND attnum > 0;

--  attname | attstorage
-- ---------+------------
--  boolean | p
--  integer | p
--  bigint  | p
--  numeric | m
--  decimal | m
--  json    | x
--  jsonb   | x
--  text    | x
--  varchar | x
--  uuid    | p
--  inet    | m
--  blob    | x --> defualt storage is extended (x). You can set it manually to external if you need it.