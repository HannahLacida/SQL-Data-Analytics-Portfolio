# Olist Brazilian E-Commerce SQL Analysis

SQL analysis of 99,441 orders from the Olist Brazilian marketplace, answering
eight business questions across revenue trends, product ranking, customer
segmentation and retention.

Capstone project for the **DataSense Analytics SQL Data Analyst certification**
(Module 7 — Data Analysis Capstone).

**Tools:** MySQL 8 · DataGrip
**Dataset:** [Olist Brazilian E-Commerce Public Dataset (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — raw CSVs are not committed to this repository.

---

## 1. Data Overview

The dataset covers 99,441 orders placed on the Olist marketplace in Brazil
between 4 September 2016 and 17 October 2018, spread across nine tables
(orders, order_items, order_payments, order_reviews, customers, products,
sellers, geolocation, and a product-category translation table). Order-level
data joins to payments and items on `order_id`, to customers on `customer_id`,
and items join to products and sellers on `product_id` and `seller_id`;
referential integrity in those directions is complete, with zero orphan rows.
Three data-quality issues shape every result below: Olist issues a **new
`customer_id` for each order**, so `customer_unique_id` is the only valid
person-level key; **2,961 orders carry more than one payment row** (up to 29),
which inflates revenue by 27% if `order_payments` and `order_items` are joined
together; and the date range has **incomplete edges** — November 2016 is absent
entirely, and September–October 2018 hold just 20 orders between them. Trend
analysis is therefore restricted to January 2017 – August 2018, which discards
0.40% of revenue.

---

## 2. Business Questions

| # | Question | Result | Query |
|---|---|---|---|
| Q1 | Who are the top 10 customers by total amount spent? | Top 10 = R$66,804.58, just **0.42%** of revenue | [q1](./sql/q1_top_customers.sql) |
| Q2 | What is the monthly revenue trend across the dataset? | Peak **Nov 2017, R$1,194,882.80** (7,544 orders) | [q2](./sql/q2_monthly_revenue.sql) |
| Q3 | What is the month-over-month change in revenue? | **+28.39%/mo** to Nov 2017, then **−0.60%/mo** | [q3](./sql/q3_mom_revenue.sql) |
| Q4 | Which product categories generate the most revenue? | 74 categories; top is health_beauty at R$1,258,681.34 | [q4](./sql/q4_category_revenue.sql) |
| Q5 | Rank the top 3 products within each category by revenue. | 219 rows; top-3 hold 2.79%–14.23% of their category | [q5](./sql/q5_top_products.sql) |
| Q6 | Segment customers into spend tiers (Low/Medium/High). | Low 46.20% · Medium 49.13% · High 4.67% of customers | [q6](./sql/q6_customer_segmentation.sql) |
| Q7 | How many customers are repeat vs one-time buyers? | **96.88% placed exactly one order** | [q7](./sql/q7_repeat_customers.sql) |
| Q8 | What % of total revenue comes from the top category? | **9.26%** — no category exceeds 10% | [q8](./sql/q8_category_contribution.sql) |

### Two revenue bases

Q1, Q2, Q3, Q6 and Q7 use `order_payments.payment_value` (**R$16,008,872.12**).
Q4, Q5 and Q8 use `order_items.price` (**R$13,591,643.70**), because payments
are recorded per order and carry no `product_id`, so category revenue can only
be measured at item grain. The R$2,417,228.42 difference is freight
(R$2,251,909.54), installment fees, vouchers, and 775 orders that have payments
but no item rows. **The two bases are not interchangeable and figures should
not be compared across them.**

---

## 3. Key Findings

| Q | Result |
|---|---|
| Q1 | Top 10 customers = R$66,804.58, just **0.42%** of revenue. Largest single customer R$13,664.08. Mean spend R$160.99, median R$105.29. |
| Q2 | Revenue peaked in **November 2017 at R$1,194,882.80** (7,544 orders). Lowest meaningful month January 2017 at R$138,488.04. |
| Q3 | Two regimes: **Feb–Nov 2017 averaged +28.39%/month**; **Dec 2017–Aug 2018 averaged −0.60%/month** with 5 declines against 4 gains. |
| Q4 | **74 categories.** Top is `health_beauty` at R$1,258,681.34. Top 5 = 39.74%, top 10 = 62.36%. 18 categories needed to reach 80%. |
| Q5 | 219 rows (two categories have fewer than 3 products). Top-3 share of own category ranges from **2.79%** (`sports_leisure`) to **14.23%** (`garden_tools`). |
| Q6 | Low 44,394 (46.20% cust / 16.74% rev) · Medium 47,212 (49.13% / 57.18%) · High 4,489 (4.67% / **26.08%**). |
| Q7 | **96.88% of customers bought exactly once.** Only 2,997 of 96,096 returned, contributing 5.90% of revenue. |
| Q8 | Top category = **9.26%** of item revenue. No category exceeds 10%. |

---

## 4. Three Business Insights

### Insight 1 — Growth stopped in December 2017, and it is an order-volume problem, not a basket problem

Revenue grew from R$138,488.04 in January 2017 to R$1,194,882.80 in November
2017 — an 8.6× increase averaging +28.39% per month. It then stayed between
R$992,463.34 and R$1,160,785.48 for nine consecutive months, averaging −0.60%
per month. Across that plateau, monthly order count has a standard deviation of
521 on a mean of 6,629, while average order value has a standard deviation of
just R$7.71 on a mean of R$160.48. **Average order value has never been the
variable** — it sits between R$147 and R$182 in every month of the dataset
regardless of what revenue did. Even the record November 2017 month came from
62.9% more orders (4,631 → 7,544) alongside a *lower* AOV (R$168.36 →
R$158.39). Initiatives aimed at basket size — bundling, upselling,
free-shipping thresholds — have no historical evidence here of moving revenue,
because basket size has never moved. The lever that has demonstrably moved
revenue is order count.

### Insight 2 — 96.88% of customers never return, so every month's revenue must be bought fresh

Of 96,096 customers, 93,099 placed exactly one order. The 2,997 repeat buyers
contribute 6.38% of orders and 5.90% of revenue, and 91.6% of them ordered just
twice. The pattern survives every cut: even in the High spend tier (>R$500),
91.1% bought only once. Repeat buyers spend *less per order* than one-time
buyers (R$148.85 vs R$161.82) — their higher lifetime value (R$314.99 vs
R$161.82) comes purely from ordering again. This explains the plateau
mechanically: with acquisition flat and almost no returning base, there is
nothing else holding revenue up, which also makes the current level
structurally fragile. For scale, lifting the repeat rate from 3.12% to 6% would
mean roughly 2,767 more customers placing one additional order each, worth
about **R$445,000** at the observed R$160.99 average order value — around 2.8%
of total revenue. *(Arithmetic on observed figures, not a forecast.)*

### Insight 3 — Revenue is unusually evenly spread, removing the obvious risk and the obvious lever at once

The top category holds 9.26% of item revenue and no category exceeds 10%. It
takes 8 categories to reach half of revenue and 18 to reach 80%, and the gap
between first and second place is only 0.39 percentage points (R$53,675.66).
The same flatness appears at every level: the top 10 customers are 0.42% of
revenue, and inside the fourth-largest category (`sports_leisure`,
R$988,048.97) the top three products hold just 2.79% of it. No product,
customer or category failure would meaningfully dent revenue — but equally,
there is no natural place to concentrate investment, and the bottom 54
categories together hold 15.99%. This rules out the otherwise-obvious
recommendation to reduce dependence on a leading category: **there is no
dependence to reduce.** Separately, R$179,535.28 (1.32%) of revenue sits on 610
products with no category assigned — a bucket that would rank 21st of 74, ahead
of `electronics`.

---

## 5. Recommendations

**1. Build a cohort-based retention report before designing any retention
programme.** With 96.88% of customers buying once, retention holds the largest
untapped revenue, and the arithmetic above sizes a move to a 6% repeat rate at
roughly R$445,000. But the headline 3.12% is not yet decision-grade: it is
inflated by same-day order splits (31.2% of repeat intervals are ≤1 day) and
deflated by observation-window truncation, since customers acquired in August
2018 had only two months in which to return. The concrete step is a report of
repeat-rate-within-90-days by first-order month, which removes both
distortions. This dataset holds no marketing, channel or session data, so it
can justify fixing the measurement but cannot recommend a specific tactic.

**2. Complete product categorisation for the 610 uncategorised products.**
They carry R$179,535.28 (1.32% of item revenue) and would rank 21st of 74
categories. Two further categories — `pc_gamer` and
`portateis_cozinha_e_preparadores_de_alimentos`, R$5,514.48 combined — have no
English translation and vanish entirely from any report built with an inner
join. This is a bounded, low-cost catalogue-hygiene fix, and until it is done
every category ranking carries a 1.32% blind spot of unknown composition.

**3. Instrument the acquisition funnel to diagnose the December 2017 plateau.**
Order volume has been the sole driver of revenue for 25 months and has been
flat for nine. This dataset establishes *that* order acquisition stopped
growing but holds no traffic, marketing-spend, channel or seller-onboarding
data, so it cannot establish *why*. Capture those inputs alongside orders so
the next plateau can be diagnosed rather than merely observed. Nothing in this
data supports attributing the plateau to pricing, assortment or competition.

> **Not recommended:** November 2017's record month is consistent with Brazilian
> Black Friday timing, but the dataset has no promotion flag, campaign field or
> discount column. Recommending "repeat the November promotion" would attribute
> a cause the data cannot support. The observable fact is that the peak was
> volume-driven with a below-trend AOV; the cause is unverified.

---

## 6. SQL Skills Demonstrated

| Technique | Where used |
|---|---|
| `SELECT`, `WHERE`, `ORDER BY`, `LIMIT` | All queries |
| `INNER JOIN` / `LEFT JOIN` (and when each is correct) | Q1–Q8; Q4 shows why `LEFT` is mandatory for lookups |
| `GROUP BY` with `HAVING` | Q4–Q8 |
| `SUM`, `COUNT`, `COUNT(DISTINCT)`, `AVG`, `MIN`, `MAX`, `ROUND` | All queries |
| `COUNT(DISTINCT)` to defend against join fan-out | Q1, Q2, Q6, Q7 |
| Common table expressions (CTEs), including chained CTEs | Q2, Q3, Q5, Q6, Q7, Q8 |
| `CASE WHEN` for classification and segmentation | Q6, Q7 |
| Date functions — `DATE_FORMAT`, `DATEDIFF` | Q2, Q3, Q7 |
| Window function: `LAG()` for period-over-period | Q3, Q7 |
| Window function: `ROW_NUMBER() OVER (PARTITION BY ...)` for top-N-per-group | Q5 |
| Window function: `SUM() OVER ()` for percent-of-total | Q6, Q7, Q8 |
| `COALESCE` with multiple fallbacks | Q4, Q5, Q8 |
| Subqueries and derived tables | Validation queries throughout |
| `ORDER BY FIELD()` for custom sort order | Q6 |

Beyond syntax, each query file documents the grain of its result, the
validation performed, and the assumptions made.

---

## 7. Data Limitations

1. **`customer_id` is not a customer.** Olist issues a new `customer_id` for
   every order, so `orders` and `customers` are 1:1 (99,441 rows each). All
   customer-level analysis uses `customer_unique_id` (96,096 people). Grouping
   on `customer_id` returns **0 repeat buyers** — silently, with no error.

2. **Payment fan-out.** 2,961 orders have multiple payment rows (max 29).
   Joining `order_payments` and `order_items` in one query inflates revenue
   from R$16,008,872.12 to **R$20,308,134.71**, a 27% overstatement. No query
   here joins both without pre-aggregating.

3. **Incomplete months.** November 2016 is absent from the data entirely;
   September 2016 (4 orders), December 2016 (1), September 2018 (16) and
   October 2018 (4) are collection artifacts. Untrimmed, `LAG()` reports a
   +705,751% month and a −99.57% month. Trend analysis is restricted to
   2017-01 – 2018-08, discarding 0.40% of revenue.

4. **`LAG()` is gap-blind.** Because November 2016 produced no row, `LAG`
   compares December 2016 against October 2016 while labelling it
   "month-over-month". A production fix would `LEFT JOIN` a calendar table to
   guarantee one row per period.

5. **Missing product categories.** 610 products have no category, covering
   1,603 item rows worth R$179,535.28 (1.32%). Two further categories have no
   English translation (R$5,514.48). An `INNER JOIN` to the translation table
   returns 71 categories instead of 74 and deletes R$185,049.76 without error.

6. **Two revenue bases that do not reconcile.** Payment basis
   R$16,008,872.12 vs item-price basis R$13,591,643.70. Never mix a numerator
   from one with a denominator from the other.

7. **Spend-tier thresholds are an assumption.** R$100 / R$500 derive from the
   observed distribution (median R$108.00, p95 R$476.15), not from a business
   definition. Moving the upper cut to R$300 more than doubles the High tier
   and raises its revenue share from 26.08% to 40.76%.

8. **Repeat rate is bounded on both sides.** 31.2% of repeat intervals are ≤1
   day, likely same-session splits, making 3.12% an upper bound. Imperfect
   identity matching behind `customer_unique_id` makes it a lower bound.
   Observation-window truncation biases it downward further.

9. **Rank ties.** `ROW_NUMBER()` in Q5 breaks two exact revenue ties at the
   rank 3/4 boundary (`fashion_childrens_clothes` at R$110.00,
   `furniture_mattress_and_upholstery` at R$399.99) with no data-driven
   justification. `DENSE_RANK()` would return 4 rows for those categories.

10. **Order status is unfiltered.** 2,963 orders (3%) never reached
    `delivered` — 625 canceled, 609 unavailable, plus shipped, invoiced,
    processing, created and approved. Included throughout for consistency with
    the capstone worked example.

11. **`order_reviews` is duplicated.** 814 rows share a `review_id`, 551
    `order_id`s have more than one review, and 789 `review_id`s appear against
    multiple orders. Not used in Q1–Q8, but documented.

12. **Lifetime spend within a 25-month window.** Tier membership is partly a
    function of when a customer joined. A production segmentation would use a
    fixed trailing window.

13. **Category is a current product attribute.** If Olist ever recategorised a
    product, its full sales history would move with it. No history table exists
    to test this.

14. **No causal data.** The dataset has no promotion, campaign, marketing-spend,
    traffic or session fields. Patterns described here are correlations and
    observed sequences, not established causes.

---

## 8. Repository Contents

```
├── README.md                        this file
├── sql/
│   ├── q1_top_customers.sql         top 10 customers (+ customer_unique_id variant)
│   ├── q2_monthly_revenue.sql       monthly revenue trend
│   ├── q3_mom_revenue.sql           month-over-month change (full + trimmed)
│   ├── q4_category_revenue.sql      revenue by product category
│   ├── q5_top_products.sql          top 3 products per category
│   ├── q6_customer_segmentation.sql spend tiers (+ tercile alternative)
│   ├── q7_repeat_customers.sql      repeat vs one-time (+ the customer_id trap)
│   └── q8_category_contribution.sql top category share of revenue
└── results/
    └── capstone_summary.md          one-page plain-English insight summary
```

Every `.sql` file contains the main query, inline comments explaining the
technique and the result, and the validation queries used to check it.

### How to run

Load the eight Olist CSVs into a MySQL database, naming the tables
`customers`, `geolocation`, `order_items`, `order_payments`, `order_reviews`,
`orders`, `products`, `sellers`, plus `product_category_name_translation`.
Each `.sql` file then runs independently.
