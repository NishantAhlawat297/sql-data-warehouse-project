/*
================================================================================================================
Data Quality Checks – Silver Layer
================================================================================================================

Description:
    This script performs a series of data quality validations to ensure
    consistency, accuracy, and standardization within the 'silver' schema.

Validation Checks:
    - Detection of NULL or duplicate values in primary key columns.
    - Identification of leading, trailing, or unnecessary spaces in string fields.
    - Verification of data standardization and formatting consistency.
    - Validation of date ranges and chronological order.
    - Consistency checks across related fields and columns.

Usage Guidelines:
    - Execute this script after completing data loads into the Silver layer.
    - Review any anomalies or discrepancies identified during execution.
    - Perform necessary corrections to maintain data integrity.

================================================================================================================
*/

-- ================================================================================================================
-- Table: silver.crm_cust_info
-- ================================================================================================================

-- Check: NULLs or Duplicates in Primary Key
-- Expected Result: No records returned
-- table bronze.crm_prod_info
--converting nvarchar(50) cst_create_date to date

UPDATE bronze.crm_cust_info
SET cst_create_date = CONVERT(DATE,cst_create_date,105); -- implicitly converted to nvarchar from date


ALTER TABLE bronze.crm_cust_info
ALTER COLUMN cst_create_date DATE;




SELECT cst_id,COUNT(*) AS cnt
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING cst_id IS NULL or COUNT(*)>1;

SELECT * 
FROM bronze.crm_cust_info
WHERE cst_id = 29466
ORDER BY cst_create_date DESC;
--removing null and duplicates from primary key column
SELECT *
FROM
( SELECT *, 
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info				
WHERE cst_id IS NOT NULL) t
WHERE flag_last = 1;

--removing unwanted spaces through trim() and standardizing or normalizing through case for 
--gender and material status

SELECT 
DISTINCT cst_material_status
FROM bronze.crm_cust_info;

SELECT 
DISTINCT cst_gndr
FROM bronze.crm_cust_info;

-------------------------------------------------------------
-- table bronze.crm_prod_info
USE DataWarehouse;
select top 5 * 
from bronze.crm_prod_info;

-- checking if primary key column contains duplicates or NULL
SELECT prd_id,COUNT(*)
FROM bronze.crm_prod_info
GROUP BY prd_id 
HAVING COUNT(*) >1 or prd_id IS NULL;

-- first 5 character of prd_key in bronze.crm_prod_info is category_id used in bronze.erp_px_cat_g1v2
-- remaining character is prd_key used in bronze.crm_sales_details table

SELECT SUBSTRING(TRIM(prd_key),1,5) AS prd_cat_id
FROM bronze.crm_prod_info;
-- convert CO-RF to CO_RF
SELECT REPLACE(SUBSTRING(TRIM(prd_key),1,5),'-','_') AS prd_cat_id
FROM bronze.crm_prod_info;
-- Remaining letters of prd_key as prd_key
SELECT SUBSTRING(TRIM(prd_key),7,LEN(TRIM(prd_key))) AS prd_key
FROM bronze.crm_prod_info;
-- Replace NULL in prd_cost with 0
SELECT ISNULL(prd_cost,0) AS prd_cost
FROM bronze.crm_prod_info;

-- Normalize or standardize low cardinality column prd_line

SELECT DISTINCT prd_line
FROM bronze.crm_prod_info;
SELECT 
CASE UPPER(TRIM(prd_line))
    WHEN 'M' THEN 'Mountain'
    WHEN 'R' THEN 'Road'
    WHEN 'S' THEN 'Other Sales'
    WHEN 'T' THEN 'Touring'
    ELSE 'n/a'
END AS prd_line
FROM bronze.crm_prod_info;

----
-- prd_start_dt should be less than prd_end_dt and there should be no overlapping
-- for same product as prd cost is to be taken.

-- one way to achieve is to first arrange the prd_start_dt in ascending order
-- for same prd and then for first record take the next record start date -1 as end date
-- We use LEAD() to achieve this
SELECT CAST(prd_start_dt AS DATE)
FROM bronze.crm_prod_info;

-- LEAD WORKS WITH INT AND DATETIME DATA TYPE

SELECT prd_id,prd_key,prd_nm ,prd_cost,
CAST(prd_start_dt AS DATE) AS prd_start_dt, CAST(LEAD(CAST(prd_start_dt AS DATETIME)) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
FROM bronze.crm_prod_info ;

-- changing bronze.crm_prod_info DDL
IF OBJECT_ID ('silver.crm_prod_info','U') IS NOT NULL
  DROP TABLE silver.crm_prod_info;
CREATE TABLE silver.crm_prod_info(
   prd_id INT,
   prd_cat_id NVARCHAR(50),
   prd_key NVARCHAR(50),
   prd_nm NVARCHAR(50),
   prd_cost INT,
   prd_line NVARCHAR(50),
   prd_start_dt DATE,
   prd_end_dt DATE,
   dwh_create_date DATETIME2 DEFAULT GETDATE()
   );
  --------------------------

-- Checking table bronze.crm_sales_details
  -- column sls_ord_num 
  USE DataWarehouse;

  SELECT TOP 10 *
  FROM bronze.crm_sales_details;

  SELECT sls_ord_num
  FROM bronze.crm_sales_details
  WHERE NOT sls_ord_num = TRIM(sls_ord_num)

  -- Checking Data Integrity of fact table FOR prd_key

  SELECT sls_prd_key
  FROM bronze.crm_sales_details
  WHERE sls_prd_key NOT IN ( SELECT prd_key FROM silver.crm_prod_info);

  -- Checking Data Integrity of fact table FOR cust_id

  SELECT sls_cust_id
  FROM bronze.crm_sales_details
  WHERE sls_cust_id  NOT IN ( SELECT cst_id FROM bronze.crm_cust_info);

  -- order,shipping,due data are stored in int format like - yyyymmdd 

  SELECT sls_order_dt
  FROM bronze.crm_sales_details
  WHERE sls_order_dt IS NULL OR LEN(sls_order_dt) <> 8 OR sls_order_dt = 0;

  SELECT 
  CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) <> 8 THEN NULL
       ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
  END AS sls_order_dt,

  CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) <> 8 THEN NULL
       ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
  END AS sls_ship_dt,

  CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) <> 8 THEN NULL
       ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
  END AS sls_due_dt

  FROM bronze.crm_sales_details;

  -- Also order_dt should be less than shipping and due date

  SELECT sls_order_dt
  FROM bronze.crm_sales_details
  WHERE sls_order_dt >= sls_ship_dt OR sls_order_dt >= sls_due_dt;

  -- sales, quantitiy and price column are correlated.
  -- sales = quantity *price

  -- Rules
  -- If sales is 0,null,-ve then sales equal to abs(price) * quantity
  -- If sales is not null and not equal to price*quantity then update it to abs(price)*quantity
  -- if price is negative -> abs(price) and if price is zero or null then price = sales/quantity

  select sls_sales,sls_price,sls_quantity
  FROM bronze.crm_sales_details
  WHERE sls_sales ! = (ABS(sls_price)*sls_quantity) OR sls_price < =0 OR sls_price IS NULL OR sls_quantity <=0 OR sls_sales<=0
  ORDER BY sls_sales,sls_price,sls_quantity;

  SELECT 
  CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales ! = (ABS(sls_price)*sls_quantity)
            THEN ABS(sls_price)*sls_quantity
       ELSE sls_sales
  END AS sls_sales,
  CASE WHEN sls_price IS NULL OR sls_price <=0 
          THEN sls_sales/NULLIF(sls_quantity,0)
       ELSE sls_price
  END AS sls_price,
  sls_quantity
  FROM bronze.crm_sales_details
  WHERE sls_sales ! = (ABS(sls_price)*sls_quantity) OR sls_price < =0 OR sls_price IS NULL OR sls_quantity <=0 OR sls_sales<=0;

-------------------------------------------------------
    SELECT TOP 10 *
    FROM silver.crm_sales_details;

-- Table bronze.erp_cust_a212

select top 10 *
from bronze.erp_cust_a212;

-- cid in bronze.erp_cust_a212 is related to cst_key in silver.crm_cust_info where  NAS part is removed


SELECT REPLACE(cid,'NAS','') AS cid
FROM bronze.erp_cust_a212

SELECT REPLACE(cid,'NAS','') AS cid
FROM bronze.erp_cust_a212
WHERE NOT EXISTS 
(
 SELECT 1 
 FROM silver.crm_cust_info
 WHERE cst_key = REPLACE(cid,'NAS','')
);

-- Changing bdate dtype to date


SELECT DISTINCT bdate
FROM bronze.erp_cust_a212
WHERE bdate IS NULL OR CONVERT(DATE,bdate,105)>='2050-01-01';

SELECT 
CASE WHEN CONVERT(DATE,bdate,105)>GETDATE() THEN NULL
     ELSE CONVERT(DATE,bdate,105)
END AS bdate
FROM bronze.erp_cust_a212;

--
SELECT DISTINCT gen
FROM bronze.erp_cust_a212;

SELECT 
CASE 
     WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
     WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
     ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_a212;


-- table bronze.erp_loc_a101
SELECT TOP 10 *
FROM  bronze.erp_loc_a101;
SELECT TOP 10 *
FROM silver.crm_cust_info;

SELECT REPLACE(cid,'-','') AS cid
FROM  bronze.erp_loc_a101;

--
SELECT DISTINCT cntry
FROM  bronze.erp_loc_a101;

SELECT
CASE
     WHEN TRIM(cntry) = 'DE' THEN 'Germany'
     WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
     WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
     ELSE TRIM(cntry)
END AS cntry
FROM  bronze.erp_loc_a101;

-- Table bronze.erp_px_cat_g1v2

select top 10 *
from bronze.erp_px_cat_g1v2;
SELECT TOP 10 *
FROM silver.crm_prod_info;

SELECT id 
FROM bronze.erp_px_cat_g1v2
WHERE id
NOT IN ( SELECT prd_cat_id FROM silver.crm_prod_info);

SELECT  *
FROM bronze.erp_px_cat_g1v2;
