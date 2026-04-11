
/*
================================================================================================================
Stored Procedure: Load Silver Layer (Bronze → Silver)
================================================================================================================

Description:
    This stored procedure executes the ETL (Extract, Transform, Load) process
    to populate tables in the 'silver' schema using data from the 'bronze' schema.

Operations Performed:
    - Clears existing data from Silver tables.
    - Loads transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None.
    This procedure does not accept input parameters and does not return any values.

Execution:
    EXEC silver.load_silver;

================================================================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
  BEGIN TRY

        

        PRINT '===========================================';
        PRINT 'Loading Silver Layer';
        PRINT '===========================================';

        DECLARE @batch_start_time DATETIME,
                @batch_end_time DATETIME,
                @start_time DATETIME,
                @end_time DATETIME;
        SET @batch_start_time = GETDATE();
        PRINT '-------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '-------------------------------------------';

         -------------------- CRM CUSTOMER ------------------
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table : silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        PRINT '>> Inserting Data into : silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_material_status,
        cst_gndr,
        cst_create_date)
        SELECT 
        cst_id,
        TRIM(cst_key) AS cst_key,
        TRIM(cst_firstname) AS cst_firstname,
        TRIM(cst_lastname) AS cst_lastname,
        CASE 
           WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
           WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
           ELSE 'n/a' 
        END AS cst_material_status,
        CASE 
           WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
           WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
           ELSE 'n/a' 
        END AS cst_gndr,
        cst_create_date
        FROM
        ( SELECT *, 
        ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
        FROM bronze.crm_cust_info				
        WHERE cst_id IS NOT NULL) t
        WHERE flag_last = 1;

        SET @end_time = GETDATE();
        PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' sec';

         -------------------- CRM PRODUCT ------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table : silver.crm_prod_info';
        TRUNCATE TABLE silver.crm_prod_info;
        PRINT '>> Inserting Data into : silver.crm_prod_info';


         INSERT INTO silver.crm_prod_info(
           prd_id,
           prd_cat_id,
           prd_key,
           prd_nm,
           prd_cost,
           prd_line,
           prd_start_dt,
           prd_end_dt)
           SELECT prd_id,
           REPLACE(SUBSTRING(TRIM(prd_key),1,5),'-','_') AS prd_cat_id,
           SUBSTRING(TRIM(prd_key),7,LEN(TRIM(prd_key))) AS prd_key,
           prd_nm,
           ISNULL(prd_cost,0) AS prd_cost,
           CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
           END AS prd_line,
           CAST(prd_start_dt AS DATE) AS prd_start_dt, 
           CAST(LEAD(CAST(prd_start_dt AS DATETIME)) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
           FROM bronze.crm_prod_info;

           SET @end_time = GETDATE();
           PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' sec';
           
           -------------------- CRM SALES ------------------
           SET @start_time = GETDATE();
           PRINT '>> Truncating Table : silver.crm_sales_details';
           TRUNCATE TABLE silver.crm_sales_details;
           PRINT '>> Inserting Data into : silver.crm_sales_details';
             INSERT INTO silver.crm_sales_details
            ( 
              sls_ord_num,
              sls_prd_key,
              sls_cust_id,
              sls_order_dt,
              sls_ship_dt,
              sls_due_dt,
              sls_sales,
              sls_quantity,
              sls_price
            )
            SELECT 
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
     
            CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) <> 8 THEN NULL
                 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,

            CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) <> 8 THEN NULL
                 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,

            CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) <> 8 THEN NULL
                 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt ,

            CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales ! = (ABS(sls_price)*sls_quantity)
                      THEN ABS(sls_price)*sls_quantity
                 ELSE sls_sales
            END AS sls_sales,
             sls_quantity,
            CASE WHEN sls_price IS NULL OR sls_price <=0 
                    THEN sls_sales/NULLIF(sls_quantity,0)
                 ELSE sls_price
            END AS sls_price
            FROM bronze.crm_sales_details;

            SET @end_time = GETDATE();
            PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' sec';


            PRINT '-------------------------------------------';
            PRINT 'Loading ERP Tables';
            PRINT '-------------------------------------------';

             -------------------- ERP CUSTOMER ------------------
            SET @start_time = GETDATE();
            PRINT '>> Truncating Table : silver.erp_cust_a212';
            TRUNCATE TABLE silver.erp_cust_a212;
            PRINT '>> Inserting Data into : silver.erp_cust_a212';

            INSERT INTO silver.erp_cust_a212
        ( 
         cid,
         bdate,
         gen
        )
        SELECT REPLACE(cid,'NAS','') AS cid,
        CASE 
             WHEN CONVERT(DATE,bdate,105)>GETDATE() THEN NULL
             ELSE CONVERT(DATE,bdate,105)
        END AS bdate,
        CASE 
             WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
             WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
             ELSE 'n/a'
        END AS gen
        FROM bronze.erp_cust_a212;

        SET @end_time = GETDATE();
        PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' sec';
        
        -------------------- ERP LOCATION ------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table : silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;
        PRINT '>> Inserting Data into : silver.erp_loc_a101';

        INSERT INTO silver.erp_loc_a101
        (
         cid,
         cntry
        )
        SELECT REPLACE(cid,'-','') AS cid,
        CASE
             WHEN TRIM(cntry) = 'DE' THEN 'Germany'
             WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
             WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
             ELSE TRIM(cntry)
        END AS cntry
        FROM  bronze.erp_loc_a101;

        SET @end_time = GETDATE();
        PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' sec';

        -------------------- ERP CATEGORY ------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table : silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        PRINT '>> Inserting Data into : silver.erp_px_cat_g1v2';

        INSERT INTO silver.erp_px_cat_g1v2
        (
         id,
         cat,
         subcat,
         maintenance
        )
        SELECT id,cat,subcat,maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' sec';

        ---------------------------------------------------
        SET @batch_end_time = GETDATE();
        PRINT 'Total Load Duration: ' + 
              CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) + ' sec';

  END TRY

  BEGIN CATCH
      PRINT '===========================================';
            PRINT 'ERROR OCCURRED DURING SILVER LOAD';
            PRINT ERROR_MESSAGE();
            PRINT CAST(ERROR_NUMBER() AS NVARCHAR);
            PRINT CAST(ERROR_STATE() AS NVARCHAR);
            PRINT '===========================================';
  END CATCH
END
