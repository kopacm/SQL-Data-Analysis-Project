/*
Since the "Average" customers (One-Time Bike Buyers) were the leak, I tested if 
"Engagement" (buying Accessories/Clothing) predicted survival. The results were definitive.

===============================================================================
Script 3: Cross-Sell Lift Analysis (The Bridge Effect)
-------------------------------------------------------------------------------
Script:       05_bridge_strategy_lift.sql
Author:       Miroslav Kopáč
Description:  Compares the "Bike Repurchase Rate" of two distinct segments:
              1. Pure Bike Buyers (High Risk)
              2. Mixed Basket Buyers (High Value - Bike + Acc/Clothing)
Key Finding:  Mixed Basket customers are 1.57x more likely to buy a second bike.
Strategy:     Pivot marketing from "Acquisition" to "Cross-Selling" to drive retention.
===============================================================================
*/

WITH BikeActivity AS (
    -- Identify customers who bought at least one bike
    SELECT 
        s.customer_key,
        COUNT(s.order_number) AS total_bikes_bought
    FROM gold.fact_sales s
    JOIN gold.dim_products p ON s.product_key = p.product_key
    WHERE p.category = 'Bikes'
    GROUP BY s.customer_key
),
CrossSellStatus AS (
    -- Identify "Bridge" Customers (Bought Accessories OR Clothing)
    SELECT DISTINCT s.customer_key
    FROM gold.fact_sales s
    JOIN gold.dim_products p ON s.product_key = p.product_key
    WHERE p.category IN ('Accessories', 'Clothing')
)
SELECT 
    CASE 
        WHEN c.customer_key IS NOT NULL THEN 'Mixed Basket (Bike + Acc/Clothing)'
        ELSE 'Pure Bike (Bike Only)' 
    END AS customer_segment,
    
    COUNT(b.customer_key) AS total_customers,
    
    -- Metric: Bike Repurchase Rate (Buying a 2nd Bike)
    CAST(
        SUM(CASE WHEN b.total_bikes_bought > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(b.customer_key) 
    AS DECIMAL(10,1)) AS bike_repurchase_rate_pct
    
FROM BikeActivity b
LEFT JOIN CrossSellStatus c ON b.customer_key = c.customer_key
GROUP BY 
    CASE 
        WHEN c.customer_key IS NOT NULL THEN 'Mixed Basket (Bike + Acc/Clothing)'
        ELSE 'Pure Bike (Bike Only)' 
    END;


