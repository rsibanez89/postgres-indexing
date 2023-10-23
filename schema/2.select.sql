SET schema 'webstore';

SELECT COUNT(1) as count, 'store' as table FROM store
UNION ALL
SELECT COUNT(1) as count, 'product' as table FROM product
;
