-- This script will insert test data in the shema created on 1.schema.sql.
INSERT INTO store (
    name, 
    address, 
    city, 
    state, 
    zipcode, 
    phone, 
    email, 
    website
)
SELECT
    CONCAT('Store ', id),
    CONCAT(id, ' Main St'),
    CONCAT('City ', id),
    ('[0:7]={NSW,VIC,TAS,QLD,SA,WA,NT,AC}'::text[])[trunc(random()*8)],
    CONCAT(TO_CHAR(id, '0000')),
    CONCAT('(02) ', TO_CHAR(trunc(random()*1000), '0000'), ' ',  TO_CHAR(trunc(random()*1000), '0000')),
    CONCAT('store', id, '@example.com'),
    CONCAT('www.store', id, '.com')
FROM generate_series(1, 10) AS id;


INSERT INTO product (
    storeid,
    name,
    description,
    imageurl,
    price,
    cost,
    stock,
    producttype,
    shippingweight,
    ispublished
)
SELECT
    id % 10 + 1,
    CONCAT('Product ', id),
    CONCAT('Description ', id),
    CONCAT('http://example.com/product/', id, '.jpg'),
    id * 10,
    id * 5,
    id * 100,
    ('[0:1]={Physical,Digital}'::text[])[trunc(random()*2)],
    id * 0.1,
    random()>0.5
FROM generate_series(1, 2000000) AS id;