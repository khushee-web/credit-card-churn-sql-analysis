/* ============================================================
   Project: Customer Engagement Segmentation & Churn Analysis
   Author: Khushi
   Tool: Google BigQuery (Standard SQL)
   Dataset: Credit Card Customers (Kaggle - sakshigoyal7)
   Table: amex-churn-analysis.customer_analytics.customers

   Goal: Segment credit card customers by engagement level and
   identify which segments carry the highest churn risk, in
   order to recommend targeted retention actions.
   ============================================================ */


/* ------------------------------------------------------------
   QUERY 1: Baseline Exploration
   Purpose: Understand the overall churn split and how attrited
   customers differ from existing ones on spend and inactivity.
   ------------------------------------------------------------ */
SELECT
  Attrition_Flag,
  COUNT(*) AS num_customers,
  ROUND(AVG(Total_Trans_Amt), 2) AS avg_trans_amt,
  ROUND(AVG(Months_Inactive_12_mon), 2) AS avg_inactive_months
FROM `amex-churn-analysis.customer_analytics.customers`
GROUP BY Attrition_Flag;

-- Result: 8,500 existing vs 1,627 attrited customers (~16% churn).
-- Attrited customers transact ~33% less on average and are
-- slightly more inactive, suggesting spend is a stronger churn
-- signal than inactivity alone.


/* ------------------------------------------------------------
   QUERY 2: Engagement Segmentation
   Purpose: Bucket customers into engagement tiers using
   transaction count and inactivity as behavioral signals.
   ------------------------------------------------------------ */
SELECT
  CLIENTNUM,
  Attrition_Flag,
  Total_Trans_Ct,
  Months_Inactive_12_mon,
  CASE
    WHEN Months_Inactive_12_mon >= 3 AND Total_Trans_Ct < 40 THEN 'Low Engagement'
    WHEN Months_Inactive_12_mon BETWEEN 1 AND 2 THEN 'Medium Engagement'
    ELSE 'High Engagement'
  END AS engagement_segment
FROM `amex-churn-analysis.customer_analytics.customers`;


/* ------------------------------------------------------------
   QUERY 3: Churn Rate by Engagement Segment (Key Insight)
   Purpose: Quantify churn risk across engagement tiers using
   a CTE to reuse the segmentation logic, then aggregate.
   ------------------------------------------------------------ */
WITH segmented AS (
  SELECT
    CLIENTNUM,
    Attrition_Flag,
    Total_Trans_Ct,
    Total_Trans_Amt,
    Months_Inactive_12_mon,
    CASE
      WHEN Months_Inactive_12_mon >= 3 AND Total_Trans_Ct < 40 THEN 'Low Engagement'
      WHEN Months_Inactive_12_mon BETWEEN 1 AND 2 THEN 'Medium Engagement'
      ELSE 'High Engagement'
    END AS engagement_segment
  FROM `amex-churn-analysis.customer_analytics.customers`
)
SELECT
  engagement_segment,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churned_customers,
  ROUND(SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM segmented
GROUP BY engagement_segment
ORDER BY churn_rate_pct DESC;

-- Result:
--   Low Engagement:    38.44% churn (809 customers)
--   High Engagement:   18.70% churn (3,803 customers)
--   Medium Engagement: 10.97% churn (5,515 customers)
--
-- Low Engagement churns at 3.5x the overall rate (~16%) and
-- 3.5x the Medium Engagement rate -- the clearest at-risk group.
-- High Engagement also churns notably more than Medium,
-- suggesting some high-transacting customers are still at risk
-- (worth further investigation via utilization ratio / contact count).


/* ------------------------------------------------------------
   QUERY 4: Risk-Ranked Customer List (Window Function)
   Purpose: Within the highest-risk segment (Low Engagement),
   rank customers by spend to surface the most at-risk accounts
   first -- the list a retention/marketing team would action.
   ------------------------------------------------------------ */
WITH segmented AS (
  SELECT
    CLIENTNUM,
    Attrition_Flag,
    Total_Trans_Amt,
    Total_Trans_Ct,
    Months_Inactive_12_mon,
    CASE
      WHEN Months_Inactive_12_mon >= 3 AND Total_Trans_Ct < 40 THEN 'Low Engagement'
      WHEN Months_Inactive_12_mon BETWEEN 1 AND 2 THEN 'Medium Engagement'
      ELSE 'High Engagement'
    END AS engagement_segment
  FROM `amex-churn-analysis.customer_analytics.customers`
)
SELECT
  CLIENTNUM,
  engagement_segment,
  Total_Trans_Amt,
  Attrition_Flag,
  RANK() OVER (PARTITION BY engagement_segment ORDER BY Total_Trans_Amt ASC) AS risk_rank
FROM segmented
WHERE engagement_segment = 'Low Engagement'
ORDER BY risk_rank;

-- Result: The top-ranked (lowest spend) customers in this segment
-- are almost entirely already-attrited customers -- validating
-- that spend-based risk ranking within the Low Engagement segment
-- is a meaningful early-warning signal for retention targeting.
