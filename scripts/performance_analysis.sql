-- Comparing the current value to a target value

/* Analyze the yearly performance of products by comparing their sales
to both the average sales performance of the product and the previous year's sales */

WITH yearly_product_sales AS
(
	SELECT YEAR(f.order_date) AS year,p.product_name,SUM(f.sales_amount) AS current_sales
	FROM gold.fact_sales f LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
	WHERE order_date IS NOT NULL
	GROUP BY YEAR(f.order_date),p.product_name
) 
SELECT
year,
product_name,
current_sales,
AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'below avg'
	 WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'above avg'
	 ELSE 'avg'
END AS avg_change,
LAG(current_sales) OVER(PARTITION BY product_name ORDER BY year) AS py_sales,
current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY year) AS diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY year) < 0 THEN 'decreasing'
	 WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY year) > 0 THEN 'increasing'
	 ELSE 'no change'
END AS py_change
FROM yearly_product_sales
ORDER BY product_name,year;
