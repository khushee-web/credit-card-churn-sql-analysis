# Customer Engagement Segmentation & Churn Analysis (SQL / BigQuery)

## Problem Statement
Credit card issuers lose significant revenue when engaged customers quietly disengage and eventually churn. This project analyzes 10,000 credit card customer records to identify which engagement segments carry the highest churn risk, and surfaces a ranked list of at-risk customers within the highest-risk segment for targeted retention action.

## Dataset
[Credit Card Customers](https://www.kaggle.com/datasets/sakshigoyal7/credit-card-customers) (Kaggle, ~10,000 customers, 18 features including demographics, transaction behavior, and attrition status).

## Tools
- **Google BigQuery** (Standard SQL)
- CTEs, `CASE WHEN` logic, aggregate functions, and window functions (`RANK() OVER PARTITION BY`)

## Approach
1. **Baseline exploration** — quantified the overall churn rate and compared spend/inactivity between existing and attrited customers.
2. **Engagement segmentation** — bucketed customers into Low / Medium / High engagement tiers using transaction count and months inactive as behavioral proxies.
3. **Churn rate by segment** — used a CTE to reuse segmentation logic, then aggregated churn rate per tier.
4. **Risk ranking** — applied a window function to rank customers within the highest-risk segment by transaction spend, producing an actionable, prioritized list for retention outreach.

## Key Findings
| Engagement Segment | Customers | Churn Rate |
|---|---|---|
| Low Engagement | 809 | **38.44%** |
| High Engagement | 3,803 | 18.70% |
| Medium Engagement | 5,515 | 10.97% |

- The **Low Engagement segment churns at ~3.5x the overall rate** (16%) and 3.5x the Medium Engagement segment — the clearest actionable target for retention campaigns.
- Notably, **High Engagement customers churn more than Medium Engagement ones**, suggesting some frequent transactors are still flight-risk — a signal worth investigating further (e.g. credit utilization, service contact frequency).
- Risk-ranking the Low Engagement segment by spend showed that the lowest-spending customers in this tier are almost entirely customers who have already churned — validating spend-based risk ranking as a meaningful early-warning signal.

## Business Recommendation
Prioritize retention outreach (offers, re-engagement campaigns) toward the Low Engagement segment, starting with the lowest-spend customers identified by the risk ranking. Separately, investigate why some High Engagement customers still churn, to catch a second at-risk pattern that simple engagement scoring misses.

## Files
- `customer_engagement_churn_analysis.sql` — full commented query set (4 queries: exploration, segmentation, aggregation, window function ranking)
