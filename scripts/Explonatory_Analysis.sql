/* 
===============================================================================
                    EXPLORATORY DATA & BUSINESS INSIGHTS
===============================================================================

This script provides a set of reusable queries to explore the Gold layer model
and answer core business questions about customers, products, and sales.

Analysis themes:

1. Data discovery
   - Listing tables and columns
   - Basic structural / metadata checks

2. Dimensional exploration
   - Geographic distribution of customers
   - Product category hierarchy
   - Time span of the dataset
   - Customer age distribution

3. KPI overview
   - One-table summary of key global metrics (revenue, orders, customers, products)

4. Descriptive breakdowns
   - Customers by country and gender
   - Products and costs by category
   - Category-level revenue

5. Top-N and rankings
   - Top customers by revenue
   - Best and worst-selling products
   - Countries by total revenue and average order value
   - Best-performing subcategories within Bikes

All queries read from:
- gold.fact_sales
- gold.dim_customers
- gold.dim_products

===============================================================================
*/


/*==============================================================================
1. DATA DISCOVERY
   - Tables and columns in the Gold schema
==============================================================================*/

-- 1.1 List all tables in the database ---------------------------------------
SELECT *
FROM INFORMATION_SCHEMA.TABLES;


-- 1.2 List all columns in the gold schema -----------------------------------
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold';


-- 1.3 List columns for a specific table (dim_customers) ---------------------
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';


/*==============================================================================
2. DIMENSIONAL EXPLORATION
   - Geography, products, time span, customers' age
==============================================================================*/

-- 2.1 Geographic distribution of customers ----------------------------------
SELECT DISTINCT 
    Country
FROM gold.dim_customers
ORDER BY Country;


-- 2.2 Hierarchical product categorization -----------------------------------
SELECT DISTINCT 
    Category,
    Subcategory,
    Product_Name
FROM gold.dim_products
ORDER BY Category, Subcategory, Product_Name;


-- 2.3 First and last order dates (dataset time span) ------------------------
SELECT
    MIN(order_date)                                   AS first_order,
    MAX(order_date)                                   AS last_order,
    DATEDIFF(YEAR, MIN(order_date), MAX(order_date))  AS database_years_span
FROM gold.fact_sales;


-- 2.4 Youngest and oldest customers (in years) ------------------------------
SELECT 
    DATEDIFF(YEAR, MAX(birthday), GETDATE()) AS youngest_customer,
    DATEDIFF(YEAR, MIN(birthday), GETDATE()) AS oldest_customer
FROM gold.dim_customers;


-- 2.5 Age distribution analysis ---------------------------------------------
SELECT 
    DATEDIFF(YEAR, birthday, GETDATE()) AS Current_Age,
    COUNT(*)                            AS Customer_Count
FROM gold.dim_customers
WHERE birthday IS NOT NULL
GROUP BY DATEDIFF(YEAR, birthday, GETDATE())
ORDER BY Current_Age;


/*==============================================================================
3. KPI OVERVIEW
   - Single table with global measures (revenue, orders, counts)
==============================================================================*/

-- 3.1 Global KPI overview ----------------------------------------------------
SELECT 
    'Total Revenue' AS measure_name,
    SUM(sales_amount) AS measure_value
FROM gold.fact_sales

UNION ALL 
SELECT 
    'Total sales' AS measure_name,       
    SUM(quantity) AS measure_value
FROM gold.fact_sales

UNION ALL 
SELECT 
    'Avg Price' AS measure_name,         
    AVG(Price) AS measure_value
FROM gold.fact_sales

UNION ALL 
SELECT 
    'Avg Order Price' AS measure_name,   
    SUM(sales_amount) / COUNT(DISTINCT order_number) AS measure_value
FROM gold.fact_sales

UNION ALL 
SELECT 
    'Total Orders' AS measure_name,
    COUNT(DISTINCT order_number) AS measure_value
FROM gold.fact_sales

UNION ALL 
SELECT 
    'Total Customers' AS measure_name,
    COUNT(customer_key) AS measure_value
FROM gold.dim_customers

UNION ALL 
SELECT 
    'Total Products' AS measure_name,
    COUNT(product_number) AS measure_value
FROM gold.dim_products;


/*==============================================================================
4. DESCRIPTIVE BREAKDOWNS
   - Customers, products, cost, and revenue by dimension
==============================================================================*/

-- 4.1 Total customers by country --------------------------------------------
SELECT 
    country,
    COUNT(customer_key) AS Total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY Total_customers DESC;


-- 4.2 Total customers by gender ---------------------------------------------
SELECT 
    gender,
    COUNT(customer_key) AS Total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY Total_customers DESC;


-- 4.3 Total products by category --------------------------------------------
SELECT
    category,
    COUNT(DISTINCT product_number) AS Total_Products
FROM gold.dim_products
GROUP BY category
ORDER BY Total_Products DESC;


-- 4.4 Average cost per category ---------------------------------------------
SELECT
    category,
    AVG(cost) AS Avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY Avg_cost DESC;


-- 4.5 Total revenue per category --------------------------------------------
SELECT
    category,
    SUM(sales_amount) AS Total_Revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p 
    ON p.product_key = s.product_key 
GROUP BY category
ORDER BY Total_Revenue DESC;


/*==============================================================================
5. TOP-N & RANKING ANALYSIS
   - Top customers, products, and markets
==============================================================================*/

-- 5.1 Top 5 customers by total revenue --------------------------------------
SELECT TOP 5
    dc.Customer_Key,
    dc.First_Name + ' ' + dc.Last_Name AS Customer_Name,
    SUM(fs.Sales_Amount)               AS Total_Revenue
FROM gold.fact_sales fs
JOIN gold.dim_customers dc 
    ON fs.Customer_Key = dc.Customer_Key
GROUP BY 
    dc.Customer_Key, 
    dc.First_Name, 
    dc.Last_Name
ORDER BY Total_Revenue DESC;


-- 5.2 Distribution of sold quantity across countries ------------------------
SELECT
    country,
    SUM(quantity) AS Quantity
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c 
    ON c.customer_key = s.customer_key
GROUP BY country
ORDER BY Quantity DESC;


-- 5.3 Best-selling products (top 3 by revenue) ------------------------------
SELECT TOP 3
    product_name,
    SUM(sales_amount) AS Total_revenue 
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p 
    ON p.product_id = s.product_key
GROUP BY product_name
ORDER BY Total_revenue DESC;


-- 5.4 Worst-selling products (bottom 3 by revenue) --------------------------
SELECT TOP 3
    product_name,
    SUM(sales_amount) AS Total_revenue 
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p 
    ON p.product_id = s.product_key
GROUP BY product_name
ORDER BY Total_revenue ASC;


-- 5.5 Countries ranked by total revenue -------------------------------------
SELECT 
    country,
    SUM(sales_amount) AS Total_revenue 
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c 
    ON c.customer_key = s.customer_key
GROUP BY country
ORDER BY Total_revenue DESC;


-- 5.6 Countries by average order value --------------------------------------
SELECT
    country,
    SUM(Total_revenue) / SUM(Total_orders) AS Average_order
FROM (
    SELECT 
        country,
        COUNT(DISTINCT order_number) AS Total_orders,
        SUM(sales_amount)           AS Total_revenue 
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_customers c 
        ON c.customer_key = s.customer_key
    WHERE country IS NOT NULL
    GROUP BY country
) t
GROUP BY country
ORDER BY Average_order DESC;


-- 5.7 Best-performing subcategories within Bikes ----------------------------
SELECT
    category,
    subcategory,
    SUM(sales_amount) AS Total_revenue
FROM gold.fact_sales s 
LEFT JOIN gold.dim_products p 
    ON p.product_key = s.product_key
GROUP BY category, subcategory
HAVING category = 'Bikes' 
ORDER BY Total_revenue DESC;
