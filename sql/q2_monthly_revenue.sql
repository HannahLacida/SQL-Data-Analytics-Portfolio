-- =====================================================================
-- Q2: What is the monthly revenue trend across the dataset?
-- Basis: order_payments.payment_value
-- =====================================================================

-- ---------------------------------------------------------------------
-- MAIN QUERY
-- ---------------------------------------------------------------------
WITH monthly AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        p.payment_value,
        o.order_id
    FROM orders o
    INNER JOIN order_payments p ON o.order_id = p.order_id
)
SELECT
    order_month,
    ROUND(SUM(payment_value), 2) AS monthly_revenue,
    COUNT(DISTINCT order_id)     AS num_orders,
    ROUND(SUM(payment_value) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM monthly
GROUP BY order_month
ORDER BY order_month;

-- 25 rows. Total R$16,008,872.12 (ties to SUM of order_payments).
-- Highest month : 2017-11, R$1,194,882.80 across 7,544 orders
-- Lowest useful : 2017-01, R$138,488.04 across 800 orders
-- Literal lowest: 2016-12, R$19.62 from 1 order (artifact)

-- %Y-%m is zero-padded and year-first, so ORDER BY on the resulting
-- STRING still sorts chronologically.
--
-- If order_purchase_timestamp is stored as TEXT rather than DATETIME,
-- substitute:  LEFT(o.order_purchase_timestamp, 7) AS order_month


-- ---------------------------------------------------------------------
-- VALIDATION
-- ---------------------------------------------------------------------
-- Date coverage: 2016-09-04 21:15:19 .. 2018-10-17 17:30:18
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- Incomplete months. Returns 2016-09 (4), 2016-12 (1),
-- 2018-09 (16), 2018-10 (4). NOTE 2016-11 is absent entirely.
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
       COUNT(*) AS order_count
FROM orders
GROUP BY order_month
HAVING COUNT(*) < 100
ORDER BY order_month;

-- Payment duplication: 2,961 orders have more than one payment row
-- (max 29). SUM is unaffected; COUNT would be inflated without DISTINCT.
SELECT COUNT(*) AS orders_with_multiple_payments
FROM (SELECT order_id FROM order_payments
      GROUP BY order_id HAVING COUNT(*) > 1) AS t;

-- Reliable analysis window = 2017-01 .. 2018-08 (20 months).
-- Excluded edge months hold R$64,391.55 = 0.40% of revenue.
