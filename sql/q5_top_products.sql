-- =====================================================================
-- Q5: Rank the top 3 products within each category by revenue.
-- Basis: order_items.price
-- =====================================================================

WITH product_revenue AS (
    SELECT
        COALESCE(t.product_category_name_english,
                 p.product_category_name,
                 'unknown')             AS category,
        oi.product_id,
        ROUND(SUM(oi.price), 2)         AS product_revenue,
        COUNT(*)                        AS units_sold,
        COUNT(DISTINCT oi.order_id)     AS num_orders
    FROM order_items oi
    LEFT JOIN products p
           ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t
           ON p.product_category_name = t.product_category_name
    GROUP BY category, oi.product_id
),
ranked AS (
    SELECT
        category,
        product_id,
        product_revenue,
        units_sold,
        num_orders,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY product_revenue DESC, product_id
        ) AS revenue_rank
    FROM product_revenue
)
SELECT
    category,
    product_id,
    product_revenue,
    units_sold,
    num_orders,
    revenue_rank
FROM ranked
WHERE revenue_rank <= 3
ORDER BY category, revenue_rank;

-- 219 rows, NOT 222: two categories have fewer than 3 products with
-- sales (cds_dvds_musicals = 1, security_and_services = 2).
-- Top-3 rows total R$1,706,134.13 = 12.55% of item revenue.

-- PARTITION BY restarts the numbering for each category. It is to a
-- window function what GROUP BY is to an aggregate -- except the rows
-- survive, which is what allows a top-N-per-group filter.

-- The rank filter NEEDS its own CTE. Window functions execute AFTER
-- WHERE and HAVING in the logical order
-- (FROM > WHERE > GROUP BY > HAVING > window > SELECT > ORDER BY),
-- so revenue_rank does not exist yet at WHERE time.

-- ORDER BY product_revenue DESC, product_id
--   The product_id tiebreaker makes the output REPRODUCIBLE. Without
--   it, tied rows are ordered non-deterministically.

-- ROW_NUMBER vs RANK vs DENSE_RANK on revenues 500,400,400,300:
--   ROW_NUMBER 1,2,3,4   always exactly 3 rows per category
--   RANK       1,2,2,4   rank<=3 can return 4+ rows
--   DENSE_RANK 1,2,2,3   rank<=3 returns all products in top 3 levels
-- ROW_NUMBER is used per the capstone specification.


-- ---------------------------------------------------------------------
-- VALIDATION
-- ---------------------------------------------------------------------
-- Categories that cannot fill a top 3
SELECT category, COUNT(*) AS products_with_sales
FROM (
    SELECT COALESCE(t.product_category_name_english,
                    p.product_category_name, 'unknown') AS category,
           oi.product_id
    FROM order_items oi
    LEFT JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t
           ON p.product_category_name = t.product_category_name
    GROUP BY category, oi.product_id
) AS x
GROUP BY category
HAVING COUNT(*) < 3;
-- cds_dvds_musicals 1 | security_and_services 2

-- KNOWN LIMITATION -- ties at the rank 3/4 boundary.
-- Two categories contain equal-revenue products where ROW_NUMBER keeps
-- one and excludes the other with no data-driven justification:
--   fashion_childrens_clothes         rank 3 and 4 both R$110.00
--   furniture_mattress_and_upholstery rank 3 and 4 both R$399.99
-- DENSE_RANK would return 4 rows for each of these categories.

-- Top-3 share of own category, highest to lowest (selected):
--   garden_tools 14.23% | computers_accessories 11.38%
--   health_beauty 11.23% | cool_stuff 11.13% | auto 9.30%
--   furniture_decor 8.50% | watches_gifts 8.39% | bed_bath_table 8.04%
--   housewares 5.44% | sports_leisure 2.79%
