/*
==============================================================
Customer Report
==============================================================
Purpose:
     -This report consolidates key customer metrics and behaviors into a single view.

Highlights:
  1. Collects essential customer information such as names, ages, and transaction details.
  2. Segments customers into categories (VIP, Regular, New) and age groups.
  3. Aggregates customer-level metrics:
      - Total orders
      - Total sales
      - Total quantity purchased
      - Total distinct products purchased
      - lifespan (in months)
   4. Calculates key performance indicators (KPIs):
      - Recency (months since last order)
      - Average order value
      - Average monthly spend
=============================================================
*/
/* ---------------------------------------------------
1) Base Query: Retrieves core columns from tables
------------------------------------------------------*/
USE DataWarehouse;

CREATE VIEW gold.report_customers AS
    WITH base_query AS 
    (
        SELECT 
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name,' ',c.last_name) AS customer_name,
        DATEDIFF(year,c.birth_date,GETDATE()) AS age
        FROM gold.fact_sales f LEFT JOIN gold.dim_customers c
        ON c.customer_key = f.customer_key
        WHERE f.order_date IS NOT NULL
    ) ,
    customer_aggregation AS (
            SELECT 
            customer_key,
            customer_number,
            customer_name,
            age,
            COUNT(DISTINCT order_number) AS total_orders,
            SUM(sales_amount) AS total_sales,
            SUM(quantity) AS total_quantity,
            MAX(order_date) AS last_order,
            DATEDIFF(month,MIN(order_date),MAX(order_date)) AS lifespan
            FROM base_query
            GROUP BY customer_key,customer_number,customer_name,age
            )

   SELECT 
   customer_key,
   customer_number,
   customer_name,
   total_orders,
   total_sales,
   total_quantity,
   age,
   CASE WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
   END AS age_group,
   lifespan,
   CASE WHEN lifespan >=12 AND total_sales > 5000 THEN 'VIP'
	    WHEN lifespan >=12 AND total_sales <=5000 THEN 'Regular'
		ELSE 'New'
   END AS customer_segment,
   last_order,
   DATEDIFF(month,last_order,GETDATE()) AS recency,
   CASE WHEN total_orders = 0 THEN 0
        ELSE total_sales/total_orders
   END AS avg_order_value,
   CASE WHEN lifespan = 0 THEN total_sales
        ELSE total_sales/lifespan
   END AS avg_monthly_spending
   FROM customer_aggregation;

