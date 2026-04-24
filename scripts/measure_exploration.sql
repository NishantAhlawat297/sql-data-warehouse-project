
SELECT 'Total Sales' AS measure_name,SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity' AS measure_name,SUM(quantity) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Average Price' AS measure_name,AVG(price) AS measure_value FROM gold.fact_sales
UNION ALL
-- Find the distinct order number which is a particular number placed by a user for a single cart,
-- usually its same for the same date for a particular customer with different products in it.
-- A single customer can have multiple order_number if he places order on multiple different cart
SELECT 'Total Orders' AS measure_name, COUNT( DISTINCT order_number) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Products' AS measure_name, COUNT( DISTINCT product_key) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Customers' AS measure_name,COUNT( DISTINCT customer_key) AS measure_value FROM gold.fact_sales;
