-- =====================================================================
-- Q7: How many customers are repeat vs one-time buyers?
-- Basis: order counts (no payment join required)
-- =====================================================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS num_orders
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN num_orders = 1 THEN 'One-time buyer'
        ELSE 'Repeat buyer'
    END                                              AS buyer_type,
    COUNT(*)                                         AS num_customers,
    SUM(num_orders)                                  AS total_orders,
    ROUND(AVG(num_orders), 2)                        AS avg_orders_per_customer,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)               AS pct_of_customers,
    ROUND(SUM(num_orders) * 100.0 / SUM(SUM(num_orders)) OVER (), 2) AS pct_of_orders
FROM customer_orders
GROUP BY buyer_type
ORDER BY buyer_type DESC;

-- One-time buyer  93,099 customers  93,099 orders  96.88% cust / 93.62% orders
-- Repeat buyer     2,997 customers   6,342 orders   3.12% cust /  6.38% orders
-- Totals: 96,096 customers, 99,441 orders.
-- Revenue: one-time R$15,064,849.41 (94.10%), repeat R$944,022.71 (5.90%).
-- Repeat buyers spend MORE per customer (R$314.99 vs R$161.82) but
-- LESS per order (R$148.85 vs R$161.82).


-- ---------------------------------------------------------------------
-- THE TRAP -- this is the single most important finding in the project
-- ---------------------------------------------------------------------
-- Olist assigns a NEW customer_id to every order. Grouping on it does
-- not produce a slightly wrong answer -- it produces a structurally
-- impossible one, with no error and no warning.

SELECT COUNT(*) AS repeat_buyers
FROM (
    SELECT customer_id
    FROM orders
    GROUP BY customer_id
    HAVING COUNT(DISTINCT order_id) > 1
) AS x;
-- Returns 0. Every customer_id maps to exactly one order, so
-- HAVING COUNT(order_id) > 1 can never be satisfied.
--
--   GROUP BY customer_id        -> 99,441 customers,     0 repeat
--   GROUP BY customer_unique_id -> 96,096 customers, 2,997 repeat


-- ---------------------------------------------------------------------
-- SUPPORTING ANALYSIS
-- ---------------------------------------------------------------------
-- Distribution of orders per customer
--   1 order  93,099 | 2 orders 2,745 | 3 orders 203 | 4 orders 30
--   5 orders      8 | 6 orders     6 | 7 orders   3 | 9 orders  1
--  17 orders      1  (maximum)
-- 91.6% of repeat buyers ordered exactly twice.

-- Days between consecutive orders -- combines Q3's LAG with Q5's
-- PARTITION BY.
WITH repeat_orders AS (
    SELECT c.customer_unique_id,
           o.order_purchase_timestamp,
           LAG(o.order_purchase_timestamp) OVER (
               PARTITION BY c.customer_unique_id
               ORDER BY o.order_purchase_timestamp
           ) AS previous_order
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
)
SELECT DATEDIFF(order_purchase_timestamp, previous_order) AS days_between
FROM repeat_orders
WHERE previous_order IS NOT NULL;
-- median 28 days | mean 77.9 | p25 0 | p75 119 | max 608
-- 1,042 of 3,345 intervals (31.2%) are <= 1 day, most likely the same
-- shopping session split across sellers rather than a genuine return.

-- CAVEAT: 3.12% is an UPPER bound with respect to same-day order
-- splits, and a LOWER bound with respect to imperfect customer
-- identity matching behind customer_unique_id. It is also biased
-- downward by observation-window truncation: customers acquired in
-- August 2018 had only two months in which to return.
