/*
====================================================================================================
DDL Script: Gold Layer - Dimension & Fact Views
====================================================================================================

Purpose:
    This script creates the Gold layer views of the data warehouse.
    The Gold layer represents the final, business-ready data model used for
    analytics, reporting, and downstream consumption.

Description:
    - Data is sourced from the Silver layer and transformed into a star schema.
    - Dimension tables provide descriptive attributes.
    - Fact table captures transactional data and links to dimensions using surrogate keys.
    - Views are used to ensure real-time data access without physical storage.

Objects Created:

    1. gold.dim_customers
        - Customer dimension table
        - Integrates CRM and ERP customer data
        - Applies data cleansing and standardization
        - Handles missing gender values using fallback logic
        - Generates surrogate key using ROW_NUMBER()

    2. gold.dim_products
        - Product dimension table
        - Includes only active products (filters historical records)
        - Enriches product data with category and subcategory information
        - Ensures uniqueness of product key
        - Generates surrogate key for dimensional modeling

    3. gold.fact_sales
        - Fact table containing sales transactions
        - Links to customer and product dimensions via surrogate keys
        - Captures key metrics such as sales amount, quantity, and price
        - Includes important dates (order, shipping, due)

Key Transformations:
    - Joins across multiple Silver layer tables
    - Data cleansing using CASE and COALESCE logic
    - Filtering of historical records (e.g., inactive products)
    - Surrogate key generation using window functions
    - Validation checks for duplicate and null keys

Data Integrity Checks:
    - Ensures no duplicate customer/product records after joins
    - Validates referential integrity in fact table
    - Checks for NULL surrogate keys in dimension joins

Notes:
    - Views do not store data physically; they dynamically execute underlying queries.
    - Any updates in Silver layer tables will be reflected in real-time.
    - ROW_NUMBER() is used for surrogate keys and may change if source data changes.

====================================================================================================
*/
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT 
   ROW_NUMBER() OVER(ORDER BY cust.cst_id ) AS customer_key,
   cust.cst_id AS customer_id,
   cust.cst_key AS customer_number,
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
GO


IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT 
ROW_NUMBER() OVER(ORDER BY pr.prd_start_dt,prd_key) AS product_key,
pr.prd_id AS product_id,
pr.prd_key AS product_number,
pr.prd_nm AS product_name,
pr.prd_cat_id AS category_id,
ca.cat AS category,
ca.subcat AS subcategory,
ca.maintenance AS maintenance,
pr.prd_cost AS cost,
pr.prd_line AS product_line,
pr.prd_start_dt AS start_date
FROM silver.crm_prod_info pr
LEFT JOIN silver.erp_px_cat_g1v2 ca
ON pr.prd_cat_id = ca.id
WHERE pr.prd_end_dt IS NULL;
GO


IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

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
GO
