DROP SCHEMA IF EXISTS webstore CASCADE;
CREATE SCHEMA webstore;

SET schema 'webstore';

CREATE TABLE customer
(
    id BIGINT NOT NULL, -- 8 bytes
    full_name VARCHAR(100) NOT NULL, -- 100 bytes
    email VARCHAR(100) NOT NULL -- 100 bytes
); -- 208 bytes
