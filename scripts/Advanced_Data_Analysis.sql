/* 
===============================================================================
                        ADVANCED DATA ANALYSIS
===============================================================================

This script provides a library of reusable analytical patterns over gold.fact_sales,
gold.dim_products, and gold.dim_customers, organized by analysis type:

1. Change over time
   - Daily, monthly, yearly, and year-month sales snapshots
   - Period-level performance metrics (orders, customers, quantity)

2. Cumulative analysis
   - Running totals by month and year
   - Moving averages over time

3. Performance vs. benchmarks
   - Product performance vs its own historical average
   - Year-over-year product performance

4. Part-to-whole analysis
   - Category contribution to total sales

5. Data segmentation
   - Product cost bands
   - Customer segments based on spend and lifespan

All queries operate directly on the Gold layer views:
- gold.fact_sales  (order_date, sales_amount, quantity, price, product_key, customer_key)
- gold.dim_products (product_name, category, cost, product_key)
- gold.dim_customers (customer_number, customer_key)

===============================================================================
*/


/* 
===============================================================================
1. CHANGE OVER TIME ANALYSIS
   - Time series views at different granularities
===============================================================================
*/

-- 1.1 Daily sales trend ------------------------------------------------------
SELECT 
    Order_Date,
    SUM(Sales_Amount) AS Total_Sales
FROM gold.fact_sales
WHERE Order_Date IS NOT NULL
GROUP BY Order_Date
ORDER BY Order_Date ASC;


-- 1.2 Yearly sales trend -----------------------------------------------------
SELECT 
    YEAR(Order_Date)      AS Order_Year,
    SUM(Sales_Amount)     AS Total_Sales
FROM gold.fact_sales
WHERE Order_Date IS NOT NULL
GROUP BY YEAR(Order_Date)
ORDER BY Order_Year ASC;


-- 1.3 Yearly performance: sales, orders, customers ---------------------------
SELECT 
    YEAR(Order_Date)              AS Order_Year,
    SUM(Sales_Amount)             AS Total_Sales,
    COUNT(DISTINCT order_number)  AS Total_Orders,
    COUNT(DISTINCT customer_key)  AS Total_Customers
FROM gold.fact_sales
WHERE Order_Date IS NOT NULL
GROUP BY YEAR(Order_Date)
ORDER BY Order_Year ASC;


-- 1.4 Monthly performance (month aggregated across all years) ---------------
SELECT 
    MONTH(Order_Date)             AS Order_Month,
    SUM(Sales_Amount)             AS Total_Sales,
    COUNT(DISTINCT order_number)  AS Total_Orders,
    COUNT(DISTINCT customer_key)  AS Total_Customers,
    SUM(quantity)                 AS Total_Quantity
FROM gold.fact_sales
WHERE Order_Date IS NOT NULL
GROUP BY MONTH(Order_Date)
ORDER BY Order_Month ASC;


-- 1.5 Year–month performance (YYYY-MM) --------------------------------------
SELECT 
    YEAR(Order_date)              AS Order_Year,
    MONTH(Order_Date)             AS Order_Month,
    SUM(Sales_Amount)             AS Total_Sales,
    COUNT(DISTINCT order_number)  AS Total_Orders,
    COUNT(DISTINCT customer_key)  AS Total_Customers,
    SUM(quantity)                 AS Total_Quantity
FROM gold.fact_sales
WHERE Order_Date IS NOT NULL
GROUP BY YEAR(Order_date), MONTH(Order_Date)
ORDER BY Order_Year ASC, Order_Month ASC;


-- 1.6 Monthly trend using DATETRUNC (preferred for time series) -------------
SELECT 
    DATETRUNC(MONTH, Order_Date)  AS Order_Date,
    SUM(Sales_Amount)             AS Total_Sales
FROM gold.fact_sales
WHERE Order_Date IS NOT NULL
GROUP BY DATETRUNC(MONTH, Order_Date)
ORDER BY Order_Date;


-- 1.7 Presentation-only formatted month labels (avoid for calculations) -----
SELECT 
    FORMAT(Order_Date, 'yyyy-MMM') AS Order_Date,
    SUM(Sales_Amount)              AS Total_Sales
FROM gold.fact_sales
WHERE Order_Date IS NOT NULL
GROUP BY FORMAT(Order_Date, 'yyyy-MMM')
ORDER BY Order_Date;


/* 
===============================================================================
2. CUMULATIVE ANALYSIS
   - Running totals and moving averages over time
===============================================================================
*/

-- 2.1 Monthly running total of sales ----------------------------------------
SELECT
    Order_Date,
    Total_Sales,
    SUM(Total_Sales) OVER (
        ORDER BY Order_Date
    ) AS Running_Total_Sales
FROM (
    SELECT 
        DATETRUNC(MONTH, Order_Date) AS Order_Date,
        SUM(Sales_Amount)            AS Total_Sales
    FROM gold.fact_sales
    WHERE Order_Date IS NOT NULL
    GROUP BY DATETRUNC(MONTH, Order_Date)
) t;


-- 2.2 Monthly running total reset each year ---------------------------------
SELECT
    Order_Date,
    Total_Sales,
    SUM(Total_Sales) OVER (
        PARTITION BY YEAR(Order_Date)
        ORDER BY Order_Date
    ) AS Running_Total_Sales
FROM (
    SELECT 
        DATETRUNC(MONTH, Order_Date) AS Order_Date,
        SUM(Sales_Amount)            AS Total_Sales
    FROM gold.fact_sales
    WHERE Order_Date IS NOT NULL
    GROUP BY DATETRUNC(MONTH, Order_Date)
) t;


-- 2.3 Annual running total (yearly grain) -----------------------------------
SELECT
    Order_Date,
    Total_Sales,
    SUM(Total_Sales) OVER (
        ORDER BY Order_Date
    ) AS Running_Total_Sales
FROM (
    SELECT 
        DATETRUNC(YEAR, Order_Date) AS Order_Date,
        SUM(Sales_Amount)           AS Total_Sales
    FROM gold.fact_sales
    WHERE Order_Date IS NOT NULL
    GROUP BY DATETRUNC(YEAR, Order_Date)
) t;


-- 2.4 Annual running total + moving average price ---------------------------
SELECT
    Order_Date,
    Total_Sales,
    SUM(Total_Sales) OVER (
        ORDER BY Order_Date
    )                                  AS Running_Total_Sales,
    AVG(Avg_price) OVER (
        ORDER BY Order_Date
    )                                  AS Moving_Avg_Price
FROM (
    SELECT 
        DATETRUNC(YEAR, Order_Date) AS Order_Date,
        SUM(Sales_Amount)           AS Total_Sales,
        AVG(Price)                  AS Avg_Price
    FROM gold.fact_sales
    WHERE Order_Date IS NOT NULL
    GROUP BY DATETRUNC(YEAR, Order_Date)
) t;


/* 
===============================================================================
3. PERFORMANCE VS BENCHMARKS
   - Product vs its own average
   - Year-over-year product comparison
===============================================================================
*/

-- 3.1 Product vs its own historical average (by year) -----------------------
WITH current_sales AS (
    SELECT 
        YEAR(fs.Order_Date)          AS Order_Year,
        p.Product_Name,
        SUM(fs.Sales_Amount)         AS Current_Sales
    FROM gold.fact_sales fs
    LEFT JOIN gold.dim_products p 
        ON fs.Product_Key = p.Product_Key
    WHERE fs.Order_Date IS NOT NULL
    GROUP BY YEAR(fs.Order_Date), p.Product_Name
)
SELECT
    Order_Year,
    Product_Name,
    Current_Sales,
    AVG(Current_sales) OVER (
        PARTITION BY Product_Name
    )                                 AS Avg_Sales,
    Current_Sales 
        - AVG(Current_sales) OVER (
            PARTITION BY Product_Name
        )                             AS Diff_to_Average,
    CASE 
        WHEN Current_Sales < AVG(Current_sales) OVER (PARTITION BY Product_Name) 
            THEN 'Below Average'
        WHEN Current_Sales > AVG(Current_sales) OVER (PARTITION BY Product_Name) 
            THEN 'Above Average'
        ELSE 'Same as Average'
    END                               AS Sales_status
FROM current_sales
ORDER BY Product_Name, Order_Year;


-- 3.2 Year-over-year (YoY) product performance ------------------------------
WITH yearly_sales AS (
    SELECT 
        YEAR(fs.Order_Date)          AS Order_Year,
        p.Product_Name,
        SUM(fs.Sales_Amount)         AS Current_Sales
    FROM gold.fact_sales fs
    LEFT JOIN gold.dim_products p 
        ON fs.Product_Key = p.Product_Key
    WHERE fs.Order_Date IS NOT NULL
    GROUP BY YEAR(fs.Order_Date), p.Product_Name
)
SELECT
    Order_Year,
    Product_Name,
    Current_Sales,
    LAG(Current_Sales) OVER (
        PARTITION BY Product_Name 
        ORDER BY Order_Year
    )                                 AS Previous_year_sales,
    Current_Sales 
        - LAG(Current_Sales) OVER (
            PARTITION BY Product_Name 
            ORDER BY Order_Year
        )                             AS Diff_from_Previous_year,
    CASE 
        WHEN Current_Sales 
             - LAG(Current_Sales) OVER (
                 PARTITION BY Product_Name 
                 ORDER BY Order_Year
               ) > 0 
            THEN 'Increase'
        WHEN Current_Sales 
             - LAG(Current_Sales) OVER (
                 PARTITION BY Product_Name 
                 ORDER BY Order_Year
               ) < 0 
            THEN 'Decrease'
        ELSE 'Same'
    END                               AS Sales_status
FROM yearly_sales
ORDER BY Product_Name, Order_Year;


/* 
===============================================================================
4. PART-TO-WHOLE ANALYSIS
   - Category contribution to total sales
===============================================================================
*/

-- 4.1 Category share of total sales -----------------------------------------
WITH category_sales AS (
    SELECT 
        category,
        SUM(fs.Sales_Amount) AS Total_Category_Sales
    FROM gold.fact_sales fs
    LEFT JOIN gold.dim_products p 
        ON fs.Product_Key = p.Product_Key
    WHERE fs.Order_Date IS NOT NULL
    GROUP BY category
)
SELECT 
    category,
    Total_Category_Sales,
    SUM(Total_Category_Sales) OVER()                              AS Total_Sales,
    CONCAT(
        ROUND(
            CAST(Total_Category_Sales AS FLOAT) 
            / SUM(Total_Category_Sales) OVER() * 100, 
            2
        ),
        ' %'
    )                                                             AS Pct_Total_sales
FROM category_sales
ORDER BY Total_Category_Sales DESC;


/* 
===============================================================================
5. DATA SEGMENTATION
   - Product cost ranges
   - Customer segments by spend and lifespan
===============================================================================
*/

-- 5.1 Product segmentation by cost bands ------------------------------------
WITH cost_ranges AS (
    SELECT 
        product_name,
        cost,
        CASE 
            WHEN cost <= 100   THEN 'Below 100'
            WHEN cost <= 500   THEN '100-500'
            WHEN cost <= 1000  THEN '500-1000'
            ELSE                    'Above 1000' 
        END AS cost_range
    FROM gold.dim_products
)
SELECT 
    cost_range,
    COUNT(DISTINCT product_name) AS Nm_of_Products
FROM cost_ranges
GROUP BY cost_range
ORDER BY Nm_of_Products DESC;


-- 5.2 Customer segmentation by spend & lifespan -----------------------------
/*
Segments:
  - VIP:     lifespan >= 12 months AND total_sales > 5000
  - Regular: lifespan >= 12 months AND total_sales <= 5000
  - New:     lifespan  < 12 months
Returns total number of customers per group.
*/
WITH customer_grouping AS (
    SELECT
        customer_number,
        CASE 
            WHEN SUM(sales_amount) > 5000 
                 AND DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) >= 12 
                THEN 'VIP'
            WHEN SUM(sales_amount) <= 5000 
                 AND DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) >= 12 
                THEN 'Regular'
            ELSE 'New'
        END AS customer_group
    FROM gold.fact_sales fs
    LEFT JOIN gold.dim_customers c 
        ON fs.customer_key = c.customer_key
    GROUP BY customer_number
)
SELECT
    COUNT(customer_number) AS Nm_of_Customers,
    customer_group
FROM customer_grouping
GROUP BY customer_group
ORDER BY Nm_of_Customers DESC;
