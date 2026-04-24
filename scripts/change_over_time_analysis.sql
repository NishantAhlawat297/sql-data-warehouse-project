SELECT order_date,SUM(sales_amount) AS total_sales
FROM gold.fact_sales 
WHERE order_date IS NOT NULL
GROUP BY order_date
ORDER BY order_date;

-- but we need to change its granularity from day to either month or year

-- Granularity in Year
SELECT YEAR(order_date) AS year,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales 
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date) 
ORDER BY YEAR(order_date);

-- or using DATETRUNC()
SELECT DATETRUNC(year,order_date) AS year,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales 
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(year,order_date) 
ORDER BY DATETRUNC(year,order_date);



-- Granularity in month
SELECT MONTH(order_date) AS month,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales 
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date) 
ORDER BY MONTH(order_date);

-- or using DATETRUNC()
SELECT DATETRUNC(month,order_date) AS month,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales 
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date) 
ORDER BY DATETRUNC(month,order_date);

