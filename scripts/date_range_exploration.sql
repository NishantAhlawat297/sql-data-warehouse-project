
-- Getting first order date
SELECT MIN(order_date) AS first_order
FROM gold.fact_sales;

SELECT DATEDIFF(year,MIN(order_date),GETDATE())  AS first_order_time
FROM gold.fact_sales;

SELECT MAX(order_date) AS last_order
FROM gold.fact_sales;

SELECT DATEDIFF(year,MAX(order_date),GETDATE())  AS latest_order_time
FROM gold.fact_sales;

-- range of time from given order dates
SELECT DATEDIFF(year,MIN(order_date),MAX(order_date)) AS range_year
FROM gold.fact_sales;

-- getting birthdate

-- getting oldest person birthdate and his age
SELECT MIN(birth_date) AS oldest_birth_date
FROM gold.dim_customers;

SELECT DATEDIFF(year,MIN(birth_date),GETDATE()) As oldest_person_age
FROM gold.dim_customers;

SELECT MAX(birth_date) AS youngest_birth_date
FROM gold.dim_customers;


SELECT DATEDIFF(year,MAX(birth_date),GETDATE()) As youngest_person_age
FROM gold.dim_customers;
