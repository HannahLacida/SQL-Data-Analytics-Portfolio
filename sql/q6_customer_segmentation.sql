-- =====================================================================
-- Q6: Segment customers into spend tiers (Low / Medium / High).
-- Basis: order_payments.payment_value
-- =====================================================================
-- ANALYTICAL ASSUMPTION -- THRESHOLDS
-- The capstone PDF does not specify cut-points. R$100 and R$500 were
-- chosen from the observed distribution:
--   min 0.00 | p25 63.12 | MEDIAN 108.00 | mean 166.59 | p75 183.53
--   p90 319.57 | P95 476.15 | p99 1,122.47 | max 13,664.08
-- R$100 approximates the median; R$500 approximates the 95th percentile.
-- These are round, explainable numbers -- NOT a business standard.
-- Different thresholds produce materially different tier sizes; see the
-- sensitivity note at the foot of this file.
-- =====================================================================

WITH customer_spend AS (
    SELECT
        c.customer_unique_id,
        ROUND(SUM(p.payment_value), 2) AS total_spent,
        COUNT(DISTINCT o.order_id)     AS num_orders
    FROM customers c
    INNER JOIN orders         o ON c.customer_id = o.customer_id
    INNER JOIN order_payments p ON o.order_id    = p.order_id
    GROUP BY c.customer_unique_id
),
segmented AS (
    SELECT
        customer_unique_id,
        total_spent,
        num_orders,
        CASE
            WHEN total_spent <= 100 THEN 'Low'
            WHEN total_spent <= 500 THEN 'Medium'
            ELSE 'High'
        END AS spend_tier
    FROM customer_spend
)
SELECT
    spend_tier,
    COUNT(*)                                   AS num_customers,
    ROUND(SUM(total_spent), 2)                 AS tier_revenue,
    ROUND(AVG(total_spent), 2)                 AS avg_spend_per_customer,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)                 AS pct_of_customers,
    ROUND(SUM(total_spent) * 100.0 / SUM(SUM(total_spent)) OVER (), 2) AS pct_of_revenue
FROM segmented
GROUP BY spend_tier
ORDER BY FIELD(spend_tier, 'Low', 'Medium', 'High');

-- Low    (<=100)  44,394 customers  R$2,680,543.21  avg 60.38  46.20% cust / 16.74% rev
-- Medium (100-500)47,212 customers  R$9,153,775.65  avg 193.89 49.13% cust / 57.18% rev
-- High   (>500)    4,489 customers  R$4,174,553.26  avg 929.95  4.67% cust / 26.08% rev
-- Totals: 96,095 customers, R$16,008,872.12 (ties to Q1/Q2/Q3).

-- Grouped on customer_unique_id, NOT customer_id. Using customer_id
-- would measure ORDER value rather than CUSTOMER value and would move
-- 193 customers out of the High tier along with R$179,534.60.

-- CASE WHEN evaluates top to bottom and stops at the first match, so
-- the second branch implicitly means "> 100 AND <= 500". Branches must
-- run most-restrictive to least; reversing them makes later branches
-- unreachable. ELSE guarantees no row returns NULL.

-- SUM(COUNT(*)) OVER () is the percent-of-total idiom: aggregate per
-- group first, then sum those group values across the whole result.


-- ---------------------------------------------------------------------
-- VALIDATION
-- ---------------------------------------------------------------------
-- 96,095 not 96,096: the customer whose single order has no payment row
-- is excluded by the INNER JOIN. Q7 does not join payments and so
-- returns 96,096. Both are correct for their own question.

-- Repeat rate rises with tier but stays low everywhere:
--   Low 0.66% | Medium 4.89% | High 8.87%
-- Over 91% of customers in EVERY tier ordered exactly once.

-- Two customers total exactly R$0.00 (traceable to the 9 rows in
-- order_payments where payment_value = 0). They fall into Low.

-- THRESHOLD SENSITIVITY -- moving one cut-point by R$200:
--   >R$500  ->  4,489 High customers (4.67%), 26.08% of revenue
--   >R$300  -> 10,768 High customers (11.21%), 40.76% of revenue
-- Tier sizes are a product of the threshold choice, not a discovered
-- property of the customers.


-- ---------------------------------------------------------------------
-- DOCUMENTED ALTERNATIVE: equal terciles
-- ---------------------------------------------------------------------
-- Cuts at R$75.35 / R$152.40 force 33.3% of customers into each tier,
-- splitting revenue 10.00% / 22.01% / 67.99%. Rejected because equal
-- tier sizes carry no information and the cut-points cannot be
-- explained to a non-analyst.
-- WITH customer_spend AS ( ... ),
-- segmented AS (
--     SELECT customer_unique_id, total_spent,
--            CASE WHEN total_spent <= 75.35  THEN 'Low'
--                 WHEN total_spent <= 152.40 THEN 'Medium'
--                 ELSE 'High' END AS spend_tier
--     FROM customer_spend
-- ) ...
