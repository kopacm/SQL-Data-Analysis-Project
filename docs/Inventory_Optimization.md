# 🚴‍♂️ Inventory Optimization: Capturing Missed Revenue in Peak Season

### 📌 The Business Problem
The company is experiencing explosive growth (**214% YoY** revenue increase in Q4 2013), but inventory planning has not scaled to match. The best-selling products run out of stock during the critical holiday season.

**The Goal:** Quantify the "Opportunity Cost" of these stockouts and build a data-driven purchasing plan to capture missed revenue next season.

---

### 📊  Summary of findings
My analysis identified a **$897,000 revenue gap** caused by stockouts on the company's Top 10 products. 

By analyzing sales velocity vs. zero-sales days, I proved that while Q4 was a success ($5.3M Revenue), company lost ~15% of potential revenue because key items were physically unavailable during peak shopping days.

| Metric | Insight |
| :--- | :--- |
| **Growth Surge** | Q4 Revenue tripled (+214%) vs previous year. |
| **Operational Gap** | Inventory planning remained flat, leading to critical shortages. |
| **Missed Opportunity** | **~$897k** in estimated uncaptured demand. |

💡**Recommendation:** Increasing safety stock by 20% can capture at least **$450,000** of this lost value next year.

---

### 🔍 Key Findings

**1. Seasonality is Drastic**
Demand for the "Bikes" category spikes. Q4 sales alone account for a massive portion of the yearly revenue.

**2. The "Stockout" Pattern**
Despite high store traffic, the **Top 10 Best-Selling Products** frequently registered **Zero Sales** on high-traffic days. 
* This wasn't due to lack of demand (store traffic was high).
* It was due to availability: The most popular bikes were sold out.

**3. The Financial Impact**
Using analysis where I counted stockouts only when a product was active, I calculated the specific lost value for the Top 10 SKUs:
* **Realized Revenue:** $1.8M (Top 10 Products)
* **Missed Revenue:** $897k (Estimated)
* **Recommendation:** Increasing safety stock by 20% can capture at least **$450,000** of this lost value next year.

---

### 🛠️ The Analysis [SQL Code]()


To reach these conclusions, I moved beyond simple aggregations and used advanced SQL techniques to isolate "True Stockouts" from simple low-demand days.

#### 1. Defining the "Active Window"
I calculated the number of days a product was *actually* live in the catalog (between its first and last sale) to avoid counting pre-launch days as stockouts.

#### 2. Calculating Sales Velocity
I determined how many units a product sells on a *normal* in-stock day to estimate what we *should* have sold on the out-of-stock days.
