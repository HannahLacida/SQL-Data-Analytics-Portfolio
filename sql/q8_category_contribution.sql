-- =====================================================================
-- Q8: What % of total revenue comes from the top category?
-- Basis: order_items.price (same as Q4 and Q5)
-- =====================================================================

WITH category_revenue AS (
    SELECT
        COALESCE(t.product_category_name_english,
                 p.product_category_name,
                 'unknown')       AS category,
        SUM(oi.price)             AS category_revenue
    FROM order_items oi
    LEFT JOIN products p
           ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t
           ON p.product_category_name = t.product_category_name
    GROUP BY category
),
with_total AS (
    SELECT
        category,
        category_revenue,
        SUM(category_revenue) OVER () AS total_revenue
    FROM category_revenue
)
SELECT
    category                                           AS top_category,
    ROUND(category_revenue, 2)                         AS top_category_revenue,
    ROUND(total_revenue, 2)                            AS total_revenue,
    ROUND(category_revenue * 100.0 / total_revenue, 2) AS pct_of_total_revenue
FROM with_total
ORDER BY category_revenue DESC
LIMIT 1;

-- health_beauty | 1,258,681.34 | 13,591,643.70 | 9.26
-- (9.2607% to four decimals)
--
-- Second place watches_gifts R$1,205,005.68 (8.87%) trails by only
-- R$53,675.66 -- 0.39 percentage points. "Largest category", not
-- "dominant category".

-- SUM(category_revenue) OVER () -- the empty OVER () makes the window
-- the ENTIRE result set, so every row carries the grand total. This is
-- the defining property of window functions: reference an aggregate
-- without collapsing the rows it came from.
--
-- Preferred over a subquery or CROSS JOIN because the denominator is
-- derived from the SAME CTE as the numerator. If the CTE ever filtered
-- rows, a subquery total taken from order_items directly would include
-- rows absent from the numerator.

-- 100.0 not 100 -- forces floating-point division.
-- ROUND is applied only in the final SELECT; rounding 74 categories
-- before summing would accumulate error.

-- Drop LIMIT 1 to return every category's share. Shares sum to 100.00.


-- ---------------------------------------------------------------------
-- SENSITIVITY TO THE REVENUE DEFINITION
-- ---------------------------------------------------------------------
--   SUM(price), incl. 'unknown'  13,591,643.70 -> 9.26%   [REPORTED]
--   SUM(price), excl. 'unknown'  13,412,108.42 -> 9.38%
--   SUM(price + freight_value)   15,843,553.24 -> 9.10%
--   SUM(payment_value)           16,008,872.12 -> 7.86%   [DO NOT USE]
--
-- The first three cluster tightly and health_beauty ranks first under
-- all of them. The fourth is INVALID: it divides an item-based
-- numerator by a payment-based denominator that includes freight,
-- installment fees and vouchers the category never earned. Numerator
-- and denominator must share a measurement basis.

-- The denominator includes R$179,535.28 (1.32%) of revenue from 610
-- products with no assigned category. Including it is what makes the
-- shares total exactly 100%; the precise phrasing is therefore
-- "9.26% of all item revenue, of which 1.32% is unattributable".

-- CONTEXT: cumulative share
--   top 1   9.26% | top 3  25.76% | top 5  39.74% | top 10 62.36%
--   8 categories reach 50%; 18 reach 80%; no category exceeds 10%.
