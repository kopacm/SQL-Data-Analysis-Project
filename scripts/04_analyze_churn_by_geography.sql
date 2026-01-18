/*
After identifying that "Average Spenders" were our highest churn risk, I segmented 
this group by geography to check for regional anomalies. I discovered that 74% 
of the churners were concentrated in the United States, compared to only 25% 
of the active customers. This suggests the churn driver might be operational 
rather than purely lack of product interest.

===============================================================================
Script:       04_analyze_churn_by_geography.sql
Author:       Miroslav Kopáč
Description:  Analyzes the geographic distribution of the "Problem Segment" 
              (Average Spenders who Churned).
Objective:    Determine if churn is a global behavior or a regional anomaly.
Key Finding:  United States accounts for 74% of churners but only 25% of active users.
===============================================================================
*/
-- Variable Declaration for Dynamic Analysis
DECLARE @AnalysisDate DATE = '2014-01-28'; -- Set this to the "Last Day" in the dataset


WITH MatureCustomerStats AS (
    -- 1. Get Stats for Mature Customers Only (Joined > 12 months ago)
    SELECT 
        customer_key,
        SUM(sales_amount) AS total_spend,
        MAX(order_date) AS last_order_date
    FROM gold.fact_sales
    GROUP BY customer_key
    HAVING MIN(order_date) < DATEADD(MONTH, -12, @AnalysisDate)
),
SegmentedCustomers AS (
    -- 2. Classify: Identify the "Average Spenders" and their Churn Status
    SELECT 
        customer_key,
        NTILE(4) OVER (ORDER BY total_spend) AS spend_quartile,
        CASE 
            WHEN DATEDIFF(MONTH, last_order_date, @AnalysisDate) > 18 THEN 'Churned' 
            ELSE 'Active' 
        END AS churn_status
    FROM MatureCustomerStats
)
-- 3. Compare Geographic Mix: Churned vs. Active (Within Average Spenders)
SELECT 
    c.country,
    s.churn_status,
    COUNT(*) AS customer_count,
    
    -- Calculate % Share of that Status (What % of Churners are from US?)
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY s.churn_status) 
    AS DECIMAL(10,1)) AS country_share_pct

FROM SegmentedCustomers s
JOIN gold.dim_customers c ON s.customer_key = c.customer_key
WHERE s.spend_quartile = 2 -- Filter for the "Problem Group" (Average Spenders) only
GROUP BY c.country, s.churn_status
ORDER BY s.churn_status, country_share_pct DESC;
