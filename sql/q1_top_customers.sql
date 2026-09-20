-- =====================================================================
-- Q1: Who are the top 10 customers by total amount spent?
-- Dataset : Olist Brazilian E-Commerce (MySQL)
-- Basis   : order_payments.payment_value
-- =====================================================================

-- ---------------------------------------------------------------------
-- MAIN QUERY (capstone specification)
-- ---------------------------------------------------------------------
SELECT
    c.customer_id,
    ROUND(SUM(p.payment_value), 2) AS total_spent,
    COUNT(DISTINCT o.order_id)     AS num_orders
FROM customers c
INNER JOIN orders         o ON c.customer_id = o.customer_id
INNER JOIN order_payments p ON o.order_id    = p.order_id
GROUP BY c.customer_id
ORDER BY total_spent DESC
LIMIT 10;

-- Result: top customer R$13,664.08. All ten show num_orders = 1.
-- Top 10 combined = R$66,804.58 = 0.42% of R$16,008,872.12 total.

-- Notes:
--   SUM(payment_value) is bare because split payments on one order
--     must be added together.
--   COUNT(DISTINCT o.order_id) is required because the payments join
--     produces one row per payment instrument, not per order.


-- ---------------------------------------------------------------------
-- VARIANT: grouped on the real person identifier
-- ---------------------------------------------------------------------
-- Olist issues a NEW customer_id for every order (99,441 customer_id
-- values for 99,441 orders, 1:1). customer_unique_id is the stable
-- person key: 96,096 distinct people.
--
-- The query above therefore ranks the ten largest single ORDERS.
-- This variant ranks the ten highest-spending PEOPLE.

SELECT
    c.customer_unique_id,
    ROUND(SUM(p.payment_value), 2) AS total_spent,
    COUNT(DISTINCT o.order_id)     AS num_orders
FROM customers c
INNER JOIN orders         o ON c.customer_id = o.customer_id
INNER JOIN order_payments p ON o.order_id    = p.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;

-- Two genuine repeat buyers surface (3 orders / R$9,553.02 and
-- 2 orders / R$7,571.63) and one customer enters at rank 2 who does
-- not appear in the customer_id version at all.


-- ---------------------------------------------------------------------
-- VALIDATION
-- ---------------------------------------------------------------------
-- Confirm the 1:1 grain of orders to customer_id
SELECT COUNT(*)                    AS order_rows,        -- 99441
       COUNT(DISTINCT order_id)    AS distinct_orders,   -- 99441
       COUNT(DISTINCT customer_id) AS distinct_customers -- 99441
FROM orders;

-- One order has no payment row and is dropped by the INNER JOIN
SELECT COUNT(*) AS orders_without_payment
FROM orders o
LEFT JOIN order_payments p ON o.order_id = p.order_id
WHERE p.order_id IS NULL;                                -- 1
