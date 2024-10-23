-- Check the running queries
SELECT pid, state, age(clock_timestamp(), query_start), usename, query
FROM pg_stat_activity
WHERE state IS NOT NULL
ORDER BY query_start desc;

-- Check all the blocking queries
select pid, pg_blocking_pids(pid) as blocked_by, query as blocked_query
from pg_stat_activity
where pg_blocking_pids(pid)::text != '{}';

-- Kill a connection
SELECT pg_terminate_backend(:pid);

-- Check all tables and their sizes
SELECT
    schemaname,
    relname,
    pg_size_pretty(pg_total_relation_size(relid)) AS size
FROM
    pg_catalog.pg_statio_user_tables
ORDER BY
    pg_total_relation_size(relid) DESC;


-- *** The pg_stat_statements extension must be installed ***
-- Check the most expensive queries in the database
SELECT query, min_exec_time, calls, rows
FROM pg_stat_statements
ORDER BY min_exec_time DESC
LIMIT 5;

-- Check the most called queries in the database
SELECT query, calls, total_exec_time
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 5;

-- Check the queries with most I/O in the database
SELECT query, shared_blks_read, shared_blks_hit, calls
FROM pg_stat_statements
ORDER BY shared_blks_read DESC
LIMIT 5;

-- Reset the statistics. This will clear all the statistics collected so far.
SELECT pg_stat_statements_reset();

