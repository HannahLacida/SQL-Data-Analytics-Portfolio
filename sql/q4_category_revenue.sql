-- =====================================================================
-- Q4: Which product categories generate the most revenue?
-- Basis: order_items.price
-- =====================================================================
-- BASIS CHANGE: Q1-Q3 used order_payments.payment_value. Payments are
-- recorded per ORDER and carry no product_id, so category revenue can
-- only be measured at item grain.
--   payment basis    R$16,008,872.12  (Q1, Q2, Q3, Q6, Q7)
--   item-price basis R$13,591,643.70  (Q4, Q5, Q8)
-- The R$2,417,228.42 gap is freight (R$2,251,909.54), installment fees,
-- vouchers, and the 775 orders that have payments but no item rows.
-- =====================================================================

SELECT
    COALESCE(t.product_category_name_english,
             p.product_category_name,
             'unknown')                       AS category,
    ROUND(SUM(oi.price), 2)                   AS category_revenue,
    COUNT(*)                                  AS items_sold,
    COUNT(DISTINCT oi.order_id)               AS num_orders,
    COUNT(DISTINCT oi.product_id)             AS num_products,
    ROUND(AVG(oi.price), 2)                   AS avg_item_price
FROM order_items oi
LEFT JOIN products p
       ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
       ON p.product_category_name = t.product_category_name
GROUP BY category
ORDER BY category_revenue DESC;

-- 74 rows. Total R$13,591,643.70.
--   1. health_beauty          1,258,681.34   9.26%
--   2. watches_gifts          1,205,005.68   8.87%
--   3. bed_bath_table         1,036,988.68   7.63%
--   4. sports_leisure           988,048.97   7.27%
--   5. computers_accessories    911,954.32   6.71%
--  21. unknown                  179,535.28   1.32%
-- Top 5 = 39.74%, top 10 = 62.36%, 18 categories to reach 80%.

-- BOTH JOINS MUST BE LEFT:
--   products      -> 610 products have NULL product_category_name,
--                    appearing on 1,603 item rows worth R$179,535.28.
--   translation   -> 2 categories have no translation row
--                    (pc_gamer R$1,545.95;
--                     portateis_cozinha_e_preparadores_de_alimentos
--                     R$3,968.53).
-- An INNER JOIN returns 71 categories instead of 74 and silently
-- deletes R$185,049.76 with no error.

-- COUNT(*) is correct for items_sold: order_items has no quantity
-- column, so repeated rows ARE the quantity. This is genuine data,
-- not join duplication.


-- ---------------------------------------------------------------------
-- VALIDATION
-- ---------------------------------------------------------------------
-- No fan-out: both lookups are many-to-one on unique keys
SELECT COUNT(*) FROM order_items;                              -- 112650
SELECT COUNT(*)
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
       ON p.product_category_name = t.product_category_name;   -- 112650

-- Revenue with no category attribution
SELECT COUNT(*)                       AS item_rows,   -- 1603
       COUNT(DISTINCT oi.product_id)  AS products,    -- 610
       ROUND(SUM(oi.price), 2)        AS revenue      -- 179535.28
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_category_name IS NULL;

-- Categories with no English translation
SELECT p.product_category_name, ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
       ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name;

-- ASSUMPTION: price only, freight excluded. Freight is a logistics
-- cost passed to the customer, not product revenue. Using
-- price + freight_value gives R$15,843,553.24 and leaves the top 5
-- ranking unchanged.
