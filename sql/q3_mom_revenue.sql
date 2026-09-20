-- =====================================================================
-- Q3: What is the month-over-month change in revenue?
-- Basis: order_payments.payment_value
-- =====================================================================

-- ---------------------------------------------------------------------
-- MAIN QUERY (full range -- exposes the data artifacts)
-- ---------------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        ROUND(SUM(p.payment_value), 2) AS revenue
    FROM orders o
    INNER JOIN order_payments p ON o.order_id = p.order_id
    GROUP BY order_month
),
with_previous AS (
    SELECT
        order_month,
        revenue,
        LAG(revenue) OVER (ORDER BY order_month) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    order_month,
    revenue,
    previous_month_revenue,
    ROUND(revenue - previous_month_revenue, 2) AS mom_change,
    ROUND((revenue - previous_month_revenue) / previous_month_revenue * 100, 2)
        AS mom_percent_change
FROM with_previous
ORDER BY order_month;

-- WARNING -- 5 of the 24 computed rows are artifacts, not business events:
--   2016-10  +23,326.29%   near-zero base (prior month = R$252.24)
--   2016-12     -99.97%    LAG compared against 2016-10; 2016-11 is MISSING
--   2017-01 +705,751.38%   near-zero base (prior month = R$19.62)
--   2018-09     -99.57%    data collection cutoff
--   2018-10     -86.72%    partial month, ends 2018-10-17
--
-- LAG() returns the PREVIOUS ROW, not the previous calendar month.
-- Because 2016-11 produced no row, LAG silently compares 2016-12
-- against 2016-10. Production fix: LEFT JOIN a calendar/date dimension
-- so every period is guaranteed one row. Here we restrict the window.


-- ---------------------------------------------------------------------
-- ANALYSIS QUERY (trimmed to the dense window)
-- ---------------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        ROUND(SUM(p.payment_value), 2) AS revenue
    FROM orders o
    INNER JOIN order_payments p ON o.order_id = p.order_id
    GROUP BY order_month
),
filtered AS (
    -- Filter BEFORE the window runs, so "previous row" == "previous month"
    SELECT * FROM monthly_revenue
    WHERE order_month BETWEEN '2017-01' AND '2018-08'
),
with_previous AS (
    SELECT
        order_month,
        revenue,
        LAG(revenue) OVER (ORDER BY order_month) AS previous_month_revenue
    FROM filtered
)
SELECT
    order_month,
    revenue,
    previous_month_revenue,
    ROUND(revenue - previous_month_revenue, 2) AS mom_change,
    ROUND((revenue - previous_month_revenue) / previous_month_revenue * 100, 2)
        AS mom_percent_change
FROM with_previous
ORDER BY order_month;

-- 20 rows, 19 computed changes. 12 growth months, 7 declines.
-- Mean +14.66%, median +7.13%.
--   Largest % gain : 2017-02  +110.78%
--   Largest % drop : 2017-12   -26.49%
--   Largest R$ gain: 2017-11  +R$415,204.92
--   Largest R$ drop: 2017-12  -R$316,481.32
--
-- Two regimes inside the window:
--   2017-02..2017-11  mean +28.39%/month  (8 up, 2 down)
--   2017-12..2018-08  mean  -0.60%/month  (4 up, 5 down)
