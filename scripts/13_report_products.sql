/*
=============================================================
Product Report
=============================================================
Purpose:
   - This report consolidates key product metrics and behaviors.

Highlights:
  1. Gathers essential fields such as product name, category, subcategory, and cost.
  2. Segments products by revenue to identify High Performers, Mid-Range, and Low Performers.
  3. Aggregates product-level metrics:
      - Total orders
      - Total sales
      - Total quantity sold
      - Total customers (unique)
      - lifespan (in months)
  4. Calculates key performance indicators (KPIs):
        - Recency (months since last sale)
        - Average order revenue (AOR)
        - Average monthly revenue
============================================================
*/
USE DataWarehouse;

CREATE VIEW gold.report_products AS
WITH product_aggregations AS 
(
    SELECT 
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost,
        COUNT(DISTINCT f.order_number) AS total_orders,
        SUM(f.sales_amount) AS total_sales,
        SUM(f.quantity) AS total_quantity,
        COUNT(DISTINCT f.customer_key) AS total_customers,
        MAX(f.order_date) AS last_order,
        DATEDIFF(month,MIN(f.order_date),MAX(order_date)) AS lifespan
    FROM gold.fact_sales f LEFT JOIN gold.dim_products p 
    ON p.product_key = f.product_key
    GROUP BY 
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
)
SELECT 
product_key,
product_name,
category,
subcategory,
cost,
DATEDIFF(month,last_order,GETDATE()) AS recency,
CASE WHEN total_orders = 0 THEN 0
     ELSE total_sales/total_orders 
END AS avg_order_value,
CASE WHEN lifespan = 0 THEN total_sales
     ELSE total_sales/lifespan 
END AS avg_monthly_revenue
FROM product_aggregations;


