-- [Measure] by [Measure]
-- we are assigning new category based on values ranges of the measure

-- segment products into cost ranges and count how many products fall into each segment
WITH product_segment AS 
(
	SELECT product_key,product_name,cost,
	CASE WHEN cost < 100 THEN 'below 100'
		 WHEN cost BETWEEN 100 AND 500  THEN '100-500'
		 WHEN cost BETWEEN 501 AND 1000 THEN '501-1000'
		 ELSE 'Above 1000'
	END AS cost_range
	FROM gold.dim_products
)
SELECT cost_range,
COUNT(product_key) AS total_products
FROM product_segment
GROUP BY cost_range
ORDER BY total_products DESC;

-- Group customers into three segment based on their spending behaviour.
-- VIP: at least 12 months of history and spending more than $5000.
-- Regular: at least 12 months of history but spending $5000 or less.
-- New:lifespan less than 12 months.
-- we need to get count of customers under each of these three segment

	WITH customer_spending AS
	(
		SELECT c.customer_key,
		SUM(f.sales_amount) AS total_spending,
		MIN(order_date) AS first_order,
		MAX(order_date) AS last_order,
		DATEDIFF(month,MIN(order_date),MAX(order_date)) AS lifespan
		FROM gold.fact_sales f LEFT JOIN gold.dim_customers c
		ON c.customer_key = f.customer_key
		GROUP BY c.customer_key
	)

	 SELECT 
	 customer_segment,
	 COUNT(customer_key) AS total_customers
	 FROM
	 (
		 SELECT customer_key,
		 total_spending,
		 lifespan,
		 CASE WHEN lifespan >=12 AND total_spending > 5000 THEN 'VIP'
			  WHEN lifespan >=12 AND total_spending <=5000 THEN 'Regular'
			  ELSE 'New'
		 END AS customer_segment
		 FROM customer_spending
	 ) t
	 GROUP BY customer_segment
	 ORDER BY total_customers DESC;
