-- cumulative means increase in quantity by successive additions

SELECT 
month,
total_sales,
--ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW AND order by month
-- cumulative of year wise so we used partition by year(month)
SUM(total_sales) OVER(PARTITION by YEAR(month) order by month) running_total_year_wise
FROM
( SELECT DATETRUNC(month,order_date) AS month,
SUM(sales_amount) AS  total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
) t;


SELECT 
year,
avg_price,
SUM(avg_price) OVER( order by year) running_total_price
FROM
( SELECT DATETRUNC(year,order_date) AS year,
AVG(price) AS  avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(year,order_date)
) t;
