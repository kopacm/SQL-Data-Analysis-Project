/*
Before measuring churn, I needed to define it scientifically. 
Standard 12-month windows are often too short for durable goods. 
I performed an Inter-Purchase Time (IPT) analysis to find the "Natural Limit" of our customer cycle.

===============================================================================
Script:       01_churn_threshold.sql
Project:      Customer Retention Analysis (The Bridge Strategy)
Author:       Miroslav Kopáč
Description:  Calculates Inter-Purchase Time (IPT) to establish a data-driven 
              churn threshold for durable goods.
Logic:        Uses Window Functions (LAG) to measure the gap between orders 
              and calculates percentiles to find the "natural heartbeat."
Key Finding:  The 75th percentile of repeat purchases occurs at ~522 days (17 months).
              Strategy: Set Churn Threshold at 18 Months to avoid false positives.
===============================================================================
*/

WITH OrderGaps AS (
    SELECT 
        customer_key,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_key ORDER BY order_date) AS prev_date,
        DATEDIFF(DAY, LAG(order_date) OVER (PARTITION BY customer_key ORDER BY order_date), order_date) AS gap_days
    FROM (SELECT DISTINCT customer_key, order_date FROM gold.fact_sales) AS DistinctOrders
)
SELECT DISTINCT
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY gap_days) OVER () AS median_gap,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY gap_days) OVER () AS p75_gap_days, -- Threshold evidence
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY gap_days) OVER () AS p90_gap_days
FROM OrderGaps
WHERE gap_days IS NOT NULL;
