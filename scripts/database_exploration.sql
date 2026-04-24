-- Getting All the database objects like tables ,views etc.

SELECT *
FROM INFORMATION_SCHEMA.TABLES;

-- Getting All column names for a particular table
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE	TABLE_NAME = 'fact_sales';
