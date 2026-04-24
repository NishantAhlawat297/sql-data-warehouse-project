
-- Which 5 products generate the highest - revenue
SELECT TOP 5 
p.product_name,SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- OR we can also use window function to find the products with highest revenue
-- ROW_NUMBER() arranges the output acc. to specific group by column with rank from 1 to increasing
-- but order of the group by in inorder
SELECT * FROM (
SELECT p.product_name,SUM(f.sales_amount) AS revenue,
ROW_NUMBER() OVER( ORDER BY SUM(f.sales_amount) DESC) AS revenue_rank
FROM gold.fact_sales f LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.product_name ) t
WHERE revenue_rank<=5;



-- Top 5 worst-performing products in terms of sales?
SELECT TOP 5 
p.product_name,SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue ;

-- Customer with fewest order placed

SELECT TOP 5 c.customer_key,c.first_name,c.last_name,
COUNT( DISTINCT f.order_number) AS order_placed
FROM gold.fact_sales f LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY c.customer_key,c.first_name,c.last_name
ORDER BY order_placed ;
