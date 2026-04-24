-- DISTINCT FOR CHEKCING GRANULARITY OR unique values count

SELECT DISTINCT category,subcategory,product_name 
FROM gold.dim_products
ORDER BY 1,2,3;

SELECT DISTINCT country
FROM gold.dim_customers;
