/*
Using the 18-month threshold, I analyzed churn by monetary value. I uncovered 
a data bias where "New" customers appeared loyal simply because they joined recently. 
I corrected this by filtering for a "Mature Cohort" (12+ months tenure), 
revealing the true risk group.

===============================================================================
Script:       02_mature_cohort_segmentation.sql
Author:       Miroslav Kopáč
Description:  Segments customers by spend and calculates the financial 
              impact of churn using a "Mature Cohort" (12+ months tenure).
===============================================================================
*/

-- Variable Declaration for Dynamic Analysis
DECLARE @AnalysisDate DATE = '2014-01-28'; -- Set this to the "Last Day" in the dataset

WITH MatureStats AS (
    SELECT 
        customer_key,
        SUM(sales_amount) AS total_spend,
        MAX(order_date) AS last_order
    FROM gold.fact_sales
    GROUP BY customer_key
    HAVING MIN(order_date) < DATEADD(MONTH, -12, @AnalysisDate)
),
Segments AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY total_spend) AS quartile,
        CASE WHEN DATEDIFF(MONTH, last_order, @AnalysisDate) > 18 THEN 'Churned' ELSE 'Active' END AS status
    FROM MatureStats
)
SELECT 
    status,
    COUNT(*) AS cust_count,
    CAST(AVG(total_spend) AS DECIMAL(10,2)) AS avg_ltv,
    CAST(SUM(total_spend) AS DECIMAL(12,2)) AS total_impact
FROM Segments
WHERE quartile = 2 -- Focusing on the "Average Spender" risk group
GROUP BY status;
