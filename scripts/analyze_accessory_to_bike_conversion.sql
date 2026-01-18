/*

I tested the hypothesis that Accessories serve as an "On-Ramp" for new customers
to eventually upgrade to Bicycles. The data disproved this completely: 0% of customers
who started with an Accessory ever upgraded. 
This critical finding shifts strategy from "Acquisition" to "Retention."

===============================================================================
Script:       analyze_accessory_to_bike_conversion.sql
Author:       Miroslav Kopáč
Description:  Tests the "On-Ramp" Hypothesis: Do customers who start with 
              low-ticket items (Accessories/Clothing) upgrade to high-ticket 
              items (Bikes)?
Key Finding:  0% Conversion. 9,350 "Accessory Starters" never bought a bike.
Conclusion:   Stop spending ad dollars targeting new customers for Accessories.
              Use Accessories ONLY as cross-sell tools for existing Bike owners.
===============================================================================
*/

WITH FirstOrderContent AS (
    -- 1. Identify the first purchase for every customer
    SELECT 
        s.customer_key,
        MIN(s.order_date) AS first_order_date
    FROM gold.fact_sales s
    GROUP BY s.customer_key
),
StarterBasket AS (
    -- 2. Analyze the category composition of that first order
    SELECT 
        f.customer_key,
        -- Did they buy a Bike on Day 1?
        MAX(CASE WHEN p.category = 'Bikes' THEN 1 ELSE 0 END) AS started_with_bike,
        -- Did they buy Accessories/Clothing on Day 1?
        MAX(CASE WHEN p.category IN ('Accessories', 'Clothing') THEN 1 ELSE 0 END) AS started_with_acc
    FROM gold.fact_sales s
    JOIN FirstOrderContent f ON s.customer_key = f.customer_key 
                            AND s.order_date = f.first_order_date
    LEFT JOIN gold.dim_products p ON s.product_key = p.product_key
    GROUP BY f.customer_key
),
AccessoryStarters AS (
    -- 3. Isolate customers who started ONLY with Accessories (No Bike)
    SELECT customer_key
    FROM StarterBasket
    WHERE started_with_bike = 0 
      AND started_with_acc = 1
)

-- 4. Calculate the "Upgrade Rate" (How many eventually bought a bike?)
SELECT 
    COUNT(DISTINCT a.customer_key) AS total_accessory_starters,
    
    -- Count how many of these specific customers have a Bike transaction LATER
    COUNT(DISTINCT CASE WHEN p.category = 'Bikes' THEN s.customer_key END) AS upgraded_to_bike_count,
    
    -- Conversion Rate %
    CAST(COUNT(DISTINCT CASE WHEN p.category = 'Bikes' THEN s.customer_key END) * 100.0 / 
         NULLIF(COUNT(DISTINCT a.customer_key), 0) AS DECIMAL(10,2)) AS upgrade_rate_pct
         
FROM AccessoryStarters a
LEFT JOIN gold.fact_sales s ON a.customer_key = s.customer_key -- Re-join to check full history
LEFT JOIN gold.dim_products p ON s.product_key = p.product_key;
