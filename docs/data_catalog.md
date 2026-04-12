# 📊 Data Catalog

## 📌 Overview
This data catalog provides a structured description of the tables and columns used in the **Gold Layer** of the data warehouse. It includes dimension tables and fact tables designed for analytical reporting and business intelligence.

## 🎯 Purpose
The purpose of this document is to:
- Define the schema and structure of analytical tables
- Ensure consistency and understanding across teams
- Serve as a reference for data engineers, analysts, and stakeholders

## 🏗️ Data Model
The data model follows a **Star Schema** design:
- **Dimension Tables**: Store descriptive attributes
  - `dim_customers`
  - `dim_products`
- **Fact Table**: Stores transactional data
  - `fact_sales`

## 🔗 Relationships
- `fact_sales.product_key` → `dim_products.product_key`
- `fact_sales.customer_key` → `dim_customers.customer_key`

These relationships ensure referential integrity between fact and dimension tables.

## 🧠 Key Concepts
- **Surrogate Key**: System-generated unique identifier (e.g., `customer_key`, `product_key`)
- **Business Key**: Original identifier from source systems (e.g., `customer_id`, `product_id`)
- **Fact Table**: Contains measurable, quantitative data (e.g., sales)
- **Dimension Table**: Contains descriptive attributes (e.g., customer, product)

1. gold.dim_customers
   
Purpose
Stores detailed customer information enriched with demographic attributes for analytical reporting.

Columns
Column Name	   |        Data Type	  |Description
customer_key   |          INT	      |Surrogate key uniquely identifying each customer record in the dimension table.
customer_id	   |          INT	      |Business key representing the unique identifier of the customer from the source system.
customer_number|	NVARCHAR(50)	    |External or alphanumeric customer identifier used for tracking and reference.
first_name	   |   NVARCHAR(50)	    |Customer’s first name.
last_name	     |   NVARCHAR(50)     |	Customer’s last name.
country	       |    NVARCHAR(50)	  |Country of residence of the customer.
marital_status |   NVARCHAR(50)     |	Marital status of the customer (e.g., Single, Married).
gender	       |   NVARCHAR(50)     |Gender of the customer (e.g., Male, Female, N/A).
birthdate	     |    DATE            |	Date of birth of the customer.
create_date	   |    DATE	          |Date when the customer record was created in the system.


2. gold.dim_products
   
Purpose
Maintains product-related information including categorization, attributes, and pricing details for analysis.

Columns
Column Name	        | Data Type   |	Description
product_key	        |   INT	     |Surrogate key uniquely identifying each product record.
product_id	        |   INT       |	Business key representing the unique product identifier from the source system.
product_number      | NVARCHAR(50)|Alphanumeric product code used for identification and tracking.
product_name	      | NVARCHAR(50)|Name or description of the product.
category_id	        |NVARCHAR(50) |	Identifier linking the product to its category.
category	          |NVARCHAR(50) |High-level classification of the product (e.g., Bikes, Components).
subcategory	        |NVARCHAR(50) |Detailed classification within a category.
maintenance         |	NVARCHAR(50)|	Indicates whether the product requires maintenance (Yes/No).
cost	              |   INT       |	Base cost of the product.
product_line	      |NVARCHAR(50)	|Product line or series (e.g., Road, Mountain).
start_date	        |DATE         |	Date when the product became available.

3. gold.fact_sales

Purpose
Captures transactional sales data to support analytical queries and reporting.

Columns
Column Name	        | Data Type     |	Description
order_number	      |NVARCHAR(50)	  |Unique identifier for each sales order.
product_key         |  	INT	        |Foreign key referencing dim_products.product_key.
customer_key	      |   INT         |	Foreign key referencing dim_customers.customer_key.
order_date          |	DATE          |	Date when the order was placed.
shipping_date       |	DATE	        |Date when the order was shipped.
due_date	          |DATE           |	Date when payment is due.
sales_amount	      |INT	          |Total sales amount for the order line.
quantity	          |INT            |	Number of units sold.
price	              |INT            |	Price per unit of the product.

🔗 Relationships (Important for Integrity)
fact_sales.product_key → dim_products.product_key
fact_sales.customer_key → dim_customers.customer_key


