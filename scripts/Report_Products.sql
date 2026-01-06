/*
===============================================================================
                            PRODUCT PERFORMANCE REPORT
===============================================================================

Purpose:
    - This report consolidates product-level performance metrics across all 
      available years into a single view for inventory management and 
      commercial decision-making.
    - It answers: 
        1. Which products generate the highest total revenue?
        2. How do products perform on a per-order and per-month revenue basis?
        3. Which products have the highest average selling price?
        4. Which categories contain the strongest and weakest products?

Scope:
    - One aggregated record per product across its entire sales history.
    - Time horizon spans from the first to the last recorded order per product.

1. Gathers product attributes:
    - product key
    - product name
    - category and subcategory
    - standard cost

2. Aggregates sales performance per product:
    - Total_Sales (sum of sales_amount)
    - Total_Quantity (sum of quantity)
    - Total_Orders (distinct order count)
    - Total_Customers (distinct customers)
    - Last_Order_Date
    - Lifespan_in_Month (months between first and last order)

3. Computes profitability & intensity metrics:
    - Avg_Selling_Price (revenue-weighted average unit price)
    - Avg_Order_Sales (average revenue per order)
    - Avg_Monthly_Sales (average revenue per active month)

4. Ranks and segments products:
    - Category_Rank: rank within category by Total_Sales
    - Product_segment: High / Mid-Range / Low Performer based on 
      revenue per month and special handling for short-lifespan products.

Usage:
    SELECT * 
    FROM gold.report_products 
    WHERE category = 'Bikes' 
    ORDER BY Total_Sales DESC;
===============================================================================
*/

IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

CREATE VIEW gold.report_products AS


/*-----------------------------------------------------------------------------
    1. BASE Query: Retrieves core columns from fact_sales and dim_products
-----------------------------------------------------------------------------*/
WITH base_query AS (
    SELECT
        c.product_key,
        product_name,
        category,
        subcategory,
        cost,
        price,
        sales_amount,
        quantity,
        order_number,
        order_date,
        customer_key
    FROM gold.fact_sales   fs
    LEFT JOIN gold.dim_products c 
        ON c.product_key = fs.product_key
    WHERE order_date IS NOT NULL
),

/*-----------------------------------------------------------------------------
    2. Aggregation CTE
       (Computes total sales, quantity, orders, customers, last order date, 
        lifespan, avg selling price)
-----------------------------------------------------------------------------*/
product_aggregation AS (
    SELECT 
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        SUM(sales_amount)                           AS Total_Sales,
        SUM(quantity)                               AS Tolal_Quantity,
        COUNT(DISTINCT order_number)                AS Total_Orders,
        COUNT(DISTINCT customer_key)                AS Total_Customers,
        MAX(order_date)                             AS Last_Order_Date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) 
                                                    AS Lifespan_in_Month,
        ROUND(
            SUM(CAST(sales_amount AS FLOAT)) 
            / NULLIF(SUM(NULLIF(quantity, 0)), 0),
            2
        )                                           AS Avg_Selling_Price
    FROM base_query
    GROUP BY 
        product_key,
        product_name,
        category,
        subcategory,
        cost
)

/*-----------------------------------------------------------------------------
    3. Computation of Final KPIs & Rankings
       - average order revenue (AOR)
       - average monthly revenue
       - category_rank 
       - product segmentation 
       - recency
-----------------------------------------------------------------------------*/
SELECT 
    product_key,
    product_name,
    category,
    subcategory,
    RANK() OVER (
        PARTITION BY category 
        ORDER BY Total_Sales DESC
    )                                               AS Category_Rank,
    Total_Sales,
    CASE 
        WHEN Total_Orders = 0 
            THEN NULL
        ELSE Total_Sales / Total_Orders
    END                                             AS Avg_Order_Sales,
    CASE 
        WHEN Lifespan_in_Month = 0 
            THEN Total_Sales
        ELSE Total_Sales / Lifespan_in_Month
    END                                             AS Avg_Monthly_Sales,
    Avg_Selling_Price,
    Tolal_Quantity,
    Total_Orders,
    cost,
    Total_Customers,
    Last_Order_Date,
    Lifespan_in_Month,
    DATEDIFF(MONTH, Last_Order_Date, GETDATE())     AS Recency,
    CASE 
        WHEN Lifespan_in_Month = 0 
             AND Total_Sales >= 10000 
            THEN 'High Performer'
        WHEN Lifespan_in_Month = 0 
             AND Total_Sales >= 5000  
            THEN 'Mid-Range Performer'
        WHEN Lifespan_in_Month = 0 
            THEN 'Low Performer'
        WHEN Total_Sales / NULLIF(Lifespan_in_Month, 0) > 10000 
            THEN 'High Performer'
        WHEN Total_Sales / NULLIF(Lifespan_in_Month, 0) > 5000  
            THEN 'Mid-Range Performer'
        ELSE 'Low Performer'
    END                                             AS Product_segment
FROM product_aggregation

