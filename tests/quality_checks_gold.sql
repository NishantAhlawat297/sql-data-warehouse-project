/*
====================================================================================================
Quality Checks Script: Gold Layer (quality_checks_gold.sql)
====================================================================================================

Purpose:
    This script performs data quality and validation checks on the Gold layer views
    to ensure data accuracy, consistency, and integrity before consumption for
    reporting and analytics.

Description:
    - Validates dimension and fact views created in the Gold layer.
    - Ensures that data transformations from the Silver layer are correct.
    - Confirms that surrogate keys and relationships are properly maintained.

Quality Checks Performed:

    1. Uniqueness Checks
        - Verifies that primary/business keys (e.g., customer_id, product_number)
          remain unique after joins and transformations.

    2. Duplicate Detection
        - Identifies duplicate records caused by joins across multiple sources.

    3. Data Standardization Validation
        - Confirms correct application of transformation logic
          (e.g., gender handling using CASE and COALESCE).

    4. Referential Integrity Checks
        - Ensures that all foreign keys in fact table (customer_key, product_key)
          correctly map to dimension tables.

    5. Null Checks
        - Detects missing surrogate keys or critical fields in the fact table.

    6. Filtering Validation
        - Verifies that only relevant records are included
          (e.g., active products with NULL end date).

Notes:
    - These checks are based on test queries executed during development.
    - The script helps ensure the Gold layer is reliable and production-ready.
    - No data is modified; this script is strictly for validation purposes.

====================================================================================================
*/



SELECT top 5 *
FROM [silver].[crm_cust_info];
SELECT TOP 5 *
FROM [silver].[erp_cust_a212];
SELECT TOP 5 *
FROM [silver].[erp_loc_a101];


-- Primary key count should be 1 after data integration
SELECT 
   cust.cst_id,count(*) AS new_col
FROM silver.crm_cust_info cust 
LEFT JOIN silver.erp_cust_a212 birth
ON cust.cst_key = birth.cid
LEFT JOIN silver.erp_loc_a101 loc
ON cust.cst_key = loc.cid
GROUP BY cust.cst_id
HAVING count(*) > 1;

-- gndr column occurs two times and master data is from source crm 

SELECT 
   DISTINCT
   cust.cst_gndr,
   birth.gen
FROM silver.crm_cust_info cust 
LEFT JOIN silver.erp_cust_a212 birth
ON cust.cst_key = birth.cid
LEFT JOIN silver.erp_loc_a101 loc
ON cust.cst_key = loc.cid

SELECT 
   DISTINCT
   cust.cst_gndr,
   birth.gen,
   CASE WHEN cust.cst_gndr ='n/a' THEN birth.gen --CRM is the Mater for gender information
        ELSE COALESCE(cust.cst_gndr,birth.gen) 
   END AS new_gender
FROM silver.crm_cust_info cust 
LEFT JOIN silver.erp_cust_a212 birth
ON cust.cst_key = birth.cid
LEFT JOIN silver.erp_loc_a101 loc
ON cust.cst_key = loc.cid;

-- Rename columns and creating its view

SELECT 
   cust.cst_id AS customer_id,
   cust.cst_key AS customer_key,
   cust.cst_firstname AS first_name,
   cust.cst_lastname AS last_name,
   cust.cst_material_status AS marital_status,
   CASE WHEN cust.cst_gndr ='n/a' THEN birth.gen --CRM is the Mater for gender information
        ELSE COALESCE(cust.cst_gndr,birth.gen) 
   END AS gender,
   birth.bdate AS birth_date,
   loc.cntry AS country,
   cust.cst_create_date AS create_date
FROM silver.crm_cust_info cust 
LEFT JOIN silver.erp_cust_a212 birth
ON cust.cst_key = birth.cid
LEFT JOIN silver.erp_loc_a101 loc
ON cust.cst_key = loc.cid;


SELECT * 
FROM gold.dim_customers;
-- for products related table view

select top 10 *
from [silver].[crm_prod_info];
select top 5 *
from [silver].[erp_px_cat_g1v2];

-- selecting only latest product price by cutting off the history
-- prd_key should be unique as it will be used to connect with sales table
SELECT *
FROM silver.crm_prod_info
WHERE prd_end_dt IS NULL;

SELECT 
pr.prd_id,
pr.prd_cat_id,
pr.prd_key,
pr.prd_nm,
pr.prd_cost,
pr.prd_line,
pr.prd_start_dt,
ca.cat,
ca.subcat,
ca.maintenance
FROM silver.crm_prod_info pr
LEFT JOIN silver.erp_px_cat_g1v2 ca
ON pr.prd_cat_id = ca.id
WHERE pr.prd_end_dt IS NULL;

SELECT 
pr.prd_key,count(*)
FROM silver.crm_prod_info pr
LEFT JOIN silver.erp_px_cat_g1v2 ca
ON pr.prd_cat_id = ca.id
WHERE pr.prd_end_dt IS NULL
GROUP BY pr.prd_key
HAVING count(*)>1;

SELECT TOP 5 *
FROM silver.crm_sales_details;
SELECT TOP 5 *
FROM gold.dim_customers;
SELECT TOP 5 *
FROM gold.dim_products;

-- We only fetched the customer_key and product_key from dimension tables

SELECT 
sal.sls_ord_num AS order_number,
prd.product_key,
cus.customer_key,
sal.sls_order_dt AS order_date,
sal.sls_ship_dt AS shipping_date,
sal.sls_due_dt AS due_date,
sal.sls_sales AS sales_amount,
sal.sls_quantity AS quantity,
sal.sls_price AS price
FROM silver.crm_sales_details sal
LEFT JOIN gold.dim_products prd
ON prd.product_number = sal.sls_prd_key
LEFT JOIN gold.dim_customers cus
ON cus.customer_id = sal.sls_cust_id;


CREATE VIEW gold.fact_sales AS
SELECT 
sal.sls_ord_num AS order_number,
prd.product_key,
cus.customer_key,
sal.sls_order_dt AS order_date,
sal.sls_ship_dt AS shipping_date,
sal.sls_due_dt AS due_date,
sal.sls_sales AS sales_amount,
sal.sls_quantity AS quantity,
sal.sls_price AS price
FROM silver.crm_sales_details sal
LEFT JOIN gold.dim_products prd
ON prd.product_number = sal.sls_prd_key
LEFT JOIN gold.dim_customers cus
ON cus.customer_id = sal.sls_cust_id;


-- checking data integrity by joining using surrogate (our own created primary keys )
select  count(*) AS null_cnt
from gold.fact_sales sal
LEFT JOIN gold.dim_products pro
ON pro.product_key = sal.product_key
LEFT JOIN gold.dim_customers cus
ON cus.customer_key = sal.customer_key
WHERE cus.customer_key IS NULL OR pro.product_key IS NULL;

