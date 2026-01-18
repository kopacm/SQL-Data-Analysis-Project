# SQL Data Analysis Portfolio: Churn Analysis
> **From Data Discovery to Actionable Strategy – A Complete Analytics Workflow**

[![SQL Server](https://img.shields.io/badge/SQL_Server-2016%2B-CC2927?logo=microsoft-sql-server)](https://www.microsoft.com/sql-server)
[![Impact](https://img.shields.io/badge/Business_Impact-High-success)](https://github.com)
[![Portfolio](https://img.shields.io/badge/Type-Professional_Portfolio-blue)](https://github.com)

## **🚴 Optimizing Customer Retention: The "Bridge Strategy" Analysis**

#### **Executive Summary**

In this SQL-based analysis, I investigated a churn problem for a bicycle retailer. By moving beyond standard churn reporting, I uncovered a **$907,006 revenue leak** driven by "One-and-Done" buyers. The analysis showed that a popular acquisition hypothesis was wrong ("The On-Ramp") and identified a specific cross-selling behavior ("The Bridge") that increases customer retention by **1.57x**.

* **Role:** Lead Data Analyst
* **Tools:** SQL (Window Functions, CTEs, Segmentations), Data Visualization
* **Impact:** Identified a $907k opportunity and pivoted marketing strategy from Acquisition to Retention.

---

### **📉 The Business Problem**

The company suspected high churn among its customer base but lacked a precise definition of "churn" for durable goods (bicycles). Marketing was planning a campaign to acquire new customers via low-cost items (Accessories) to fix this.

**My Goal:** Determine the *true* churn rate, identify the root cause, and validate the proposed marketing strategy.

---

### **🕵️‍♂️ The Analysis: A 4-Step Story**

#### **Step 1: Establishing the Baseline (Defining Churn)** [01_churn_threshold.sql](scripts/01_churn_threshold.sql)

* **The Challenge:** Bicycles are not monthly subscriptions. A 3-month silence isn't churn; it's normal.
* **The Analysis:** I performed an Inter-Purchase Time (IPT) analysis using SQL Window Functions (LAG) to calculate the natural "heartbeat" of the customer base.
* **The Finding:** The 75th percentile of repeat purchases occurs at **522 days (approx. 17 months)**.
* **Decision:** I set the Churn Threshold at **18 months** to avoid false positives.

#### **Step 2: Diagnosing the Patient (Who is leaving?)** [02_mature_cohort_segmentation.sql](scripts/02_mature_cohort_segmentation.sql)


* **The Challenge:** New customers often look "active" simply because they joined recently.
* **The Analysis:** I filtered for a "Mature Cohort" (tenure > 12 months) and segmented customers by Monetary Value (Quartiles).
* **The Finding:**
* **VIPs (Top Spenders):** 0% Churn.
* **The Leak:** The "Average Spender" segment (Quartile 2) had the highest churn rate.
* **Revenue Impact:** These 255 churned customers represented a **$907k loss** in Lifetime Value.



#### **Step 3: The Strategic Pivot (Busting the "On-Ramp" Myth)** [03_analyze_accessory_to_bike_conversion.sql](scripts/03_analyze_accessory_to_bike_conversion.sql)

* **The Hypothesis:** Management believed selling Accessories (helmets, jerseys) to new customers would act as an "On-Ramp" to buying Bicycles later.
* **The Analysis:** I tracked 9,350 customers who started their journey with an Accessory purchase.
* **The Finding:** **0.00%** of these customers upgraded to a bike.
* **The Pivot:** I recommended **stopping** ad spend on this acquisition strategy immediately.

#### **Step 4: The Solution (The "Bridge" Strategy)** [05_bridge_strategy_lift.sql](scripts/05_bridge_strategy_lift.sql)

* **The Hypothesis:** If Accessories don't work for *Acquisition*, do they work for *Retention*?
* **The Analysis:** I compared the repurchase rates of "Pure Bike" buyers vs. "Mixed Basket" buyers (Bike + Accessory).
* **The Finding:**
* **Pure Bike Buyers:** 37% Repurchase Rate.
* **Mixed Basket Buyers:** 58% Repurchase Rate.
* **Insight:** Getting a bike owner to buy a "Bridge Item" (Accessory) increases their likelihood of buying a second bike by **1.57x**.



---

#### **🌍 Critical Operational Insight** [04_analyze_churn_by_geography.sql](scripts/04_analyze_churn_by_geography.sql)

While analyzing the "Average Spender" churn group, I performed a geographic segmentation to rule out regional anomalies.

* **The Discovery:** **74% of the lost revenue** came specifically from the **United States** market.
* **The Context:** The US accounts for only 25% of the active user base.
* **Recommendation:** This disproportionate churn suggests an **Operational/Logistics failure** in the US region (maybe shipping delays), rather than a purely product-based failure.

---

### **💡 Recommendations**

Based on this analysis, I presented three strategic recommendations to the executive team:

1. **Launch "The Bridge Program":** Shift marketing budget from "On-Ramp" acquisition (which failed) to cross-selling Accessories to the **1,455 active "Pure Bike" customers**.
2. **Stop "On-Ramp" Spend:** Cease acquisition campaigns targeting low-value Accessory buyers, as they have a 0% conversion rate to high-value items.
3. **US Operations Audit:** Pause aggressive scaling in the US until a "Voice of Customer" survey confirms if logistics/shipping issues are driving the 74% revenue bleed in that region.

---

### **🛠️ Technical Skills Demonstrated**

* **Advanced SQL:** CTEs, Window Functions (LAG, NTILE, SUM OVER), Date Math (DATEDIFF), Segmentation logic.
* **Business Logic:** Cohort Analysis, Churn Definition, Lifetime Value (LTV) Calculation.
* **Strategic Thinking:** Hypothesis testing (Acquisition vs. Retention) and Geographic anomaly detection.

---
## 📬 **Contact**
**Miroslav Kopac** *Data Analyst* [LinkedIn](https://www.linkedin.com/in/miroslavkopac/) | [Email](mailto:kopacmiroslav@gmail.com)

*Check out the [SQL folder](scripts) in this repository to see the foundational scripts used to generate these insights.*
