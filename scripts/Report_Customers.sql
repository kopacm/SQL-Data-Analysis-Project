/*
===============================================================================
                            CUSTOMER REPORT
===============================================================================

Purpose:
    - This report consolidates key customer metrics and behaviors into a single 
      view for data analysis and marketing strategies.
    - It answers: Who are our customers? How do they behave? What is their value?

1. Gathers customer details:
    - name
    - age (derived from birth date)
    - country and gender
    - transaction details

2. Aggregates per customer:
    - Total_Orders
    - Total_Sales
    - Total_Quantity
    - Total_Products (distinct products purchased)
    - First_Order_Date
    - Last_Order_Date
    - Lifespan_in_Month (months between first and last order)

3. Computes KPIs:
    - Recency (months since last order)
    - Avg_Order_Value (average sales per order, divide-by-zero safe)
    - Avg_Monthly_Spending (average sales per active month)

4. Segments customers:
    - Age_Group buckets
    - Customer_Segment: VIP, Regular, New (based on spend and lifespan)

Usage:
    SELECT * 
    FROM gold.report_customers 
    WHERE country = 'Australia' 
    ORDER BY Total_Sales DESC;
===============================================================================
*/

IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_customers AS

/*-----------------------------------------------------------------------------
    1. BASE Query: Retrieves core columns from fact_sales and dim_customers
-----------------------------------------------------------------------------*/
WITH base_query AS (
    SELECT
        c.customer_key,
        c.customer_number,
        order_number,
        first_name + ' ' + last_name           AS Customer_Name,
        DATEDIFF(YEAR, birthday, GETDATE())    AS Age,
        country,
        gender,
        product_key,
        order_date,
        sales_amount,
        quantity
    FROM gold.fact_sales      fs
    LEFT JOIN gold.dim_customers c 
        ON c.customer_key = fs.customer_key
    WHERE order_date IS NOT NULL
),

/*-----------------------------------------------------------------------------
    2. Aggregation CTE 
       (total orders, total sales, total quantity, total products, 
        first/last order date, lifespan)
-----------------------------------------------------------------------------*/
customer_aggregation AS (
    SELECT
        customer_key,
        customer_number,
        Customer_Name,
        Age,
        Country,
        Gender,
        COUNT(DISTINCT product_key)                    AS Total_Products,
        COUNT(DISTINCT order_number)                   AS Total_Orders,
        MAX(order_date)                                AS Last_Order_Date,
        MIN(order_date)                                AS First_Order_Date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) 
                                                       AS Lifespan_in_Month,
        SUM(sales_amount)                              AS Total_Sales,
        SUM(quantity)                                  AS Total_Quantity
    FROM base_query
    GROUP BY 
        customer_key,
        customer_number,
        Customer_Name,
        Age,
        Country,
        Gender
)

/*-----------------------------------------------------------------------------
    3. Computation of KPIs 
       - Recency 
       - Average order value 
       - Average monthly spend
       - Age group and customer segment
-----------------------------------------------------------------------------*/
SELECT
    customer_key,
    customer_number,
    Customer_Name,
    Age,
    CASE 
        WHEN Age < 20 THEN 'Below 20'
        WHEN Age BETWEEN 20 AND 29 THEN '20-29' 
        WHEN Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN Age BETWEEN 40 AND 49 THEN '40-49'
        ELSE 'Above 50'
    END                                                 AS Age_Group,
    Country,
    Gender,
    CASE 
        WHEN Total_Sales > 5000 
             AND Lifespan_in_Month >= 12 THEN 'VIP'
        WHEN Total_Sales <= 5000 
             AND Lifespan_in_Month >= 12 THEN 'Regular'
        ELSE 'New'
    END                                                 AS Customer_Segment,
    Total_Sales,
    Total_Orders,
    -- Average order value (guarded against divide-by-zero)
    CASE
        WHEN Total_Orders = 0 THEN 0
        ELSE Total_Sales / Total_Orders
    END                                                 AS Avg_Order_Value,
    Total_Quantity,
    Total_Products,
    -- Average monthly spend (with a special case when lifespan is 0)
    CASE 
        WHEN Lifespan_in_Month = 0 THEN Total_Sales
        ELSE Total_Sales / Lifespan_in_Month
    END                                                 AS Avg_Montly_Spending,
    -- Recency (months since last order)
    DATEDIFF(MONTH, Last_Order_Date, GETDATE())         AS Recency,
    Lifespan_in_Month,
    First_Order_Date,
    Last_Order_Date
FROM customer_aggregation;
