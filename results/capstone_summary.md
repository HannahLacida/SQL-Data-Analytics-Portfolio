# Olist Brazilian E-Commerce — Insight Summary

*One-page summary. Plain English, no SQL.*

---

## Data Overview

This analysis covers 99,441 orders placed on the Olist marketplace in Brazil
between September 2016 and October 2018, across nine linked tables covering
orders, items, payments, customers, products, sellers and reviews. Three data
issues shape every figure below: Olist assigns a new customer ID to each order,
so only a separate "unique customer" field can identify a returning buyer;
2,961 orders were paid with more than one payment method, which double-counts
revenue if payment and item tables are combined carelessly; and the date range
has incomplete edges, with November 2016 missing entirely and the final two
months holding only 20 orders between them. Trend analysis is therefore limited
to January 2017 – August 2018, which covers 99.6% of revenue.

---

## Three Business Insights

**1. Growth stopped in December 2017, and the problem is order volume, not
basket size.** Revenue grew 8.6× between January and November 2017, from
R$138,488 to R$1,194,883, averaging 28% growth per month. It then held between
R$992,463 and R$1,160,785 for nine straight months, averaging −0.6% per month
with more declining months than growing ones. Across that plateau, average
order value barely moved — a standard deviation of R$7.71 around a mean of
R$160.48 — while order volume swung by ten times as much proportionally. In
fact average order value has stayed between R$147 and R$182 in every month of
the dataset, regardless of what revenue did. Even the record November 2017
month came from 63% more orders at a *lower* average basket. This means
initiatives aimed at getting customers to spend more per order have no
historical evidence of working here; the only lever that has ever moved revenue
is the number of orders.

**2. Almost no one comes back, so every month's revenue has to be won from
scratch.** Of 96,096 customers, 93,099 — 96.88% — placed exactly one order
ever. The 2,997 who returned account for just 5.90% of revenue, and 92% of them
ordered only twice. The pattern holds even among the highest spenders: of
customers who spent over R$500, 91% still bought only once. Repeat customers
are worth more over their lifetime (R$314.99 vs R$161.82) purely because they
order again — per order they actually spend slightly *less*. This explains the
plateau directly: with customer acquisition flat and virtually no returning
base, there is nothing else holding revenue up, which also makes the current
level fragile. For scale, moving the repeat rate from 3.1% to 6% would be worth
roughly R$445,000, about 2.8% of total revenue.

**3. Revenue is spread unusually thin, which removes both the obvious risk and
the obvious opportunity.** The largest product category accounts for only 9.26%
of revenue, and no category exceeds 10%. It takes 8 categories to reach half of
all revenue and 18 to reach 80%, while first and second place are separated by
less than half a percentage point. The same flatness appears everywhere: the
ten biggest customers together represent 0.42% of revenue, and within the
fourth-largest category the three best-selling products hold under 3% of it. No
single category, product or customer failing would meaningfully dent the
business — but equally, there is no concentration to build a strategy around,
and investment in any one category is diluted across a very long tail. One
fixable problem sits inside this: R$179,535 of revenue (1.32%) belongs to 610
products with no category recorded at all, a group that would rank 21st of 74
if it were a category.

---

## Recommendations

**1. Fix how retention is measured before spending anything on improving it.**
With 97% of customers never returning, retention is the largest untapped
opportunity in this data, worth roughly R$445,000 for a move to a 6% repeat
rate. But the current 3.1% figure is not yet reliable enough to plan against:
31% of apparent "repeat purchases" happened within a single day and are
probably one shopping trip split into two orders, while customers who joined in
the final months had almost no time to return. A report showing repeat rate
within 90 days, broken out by the month a customer first ordered, would remove
both distortions and show whether retention is improving or getting worse.

**2. Complete the product categorisation for the 610 uncategorised products.**
These carry R$179,535 in sales — enough to rank 21st out of 74 categories,
ahead of electronics. Two further categories are missing from the English
translation table and disappear entirely from any standard category report.
This is a small, bounded catalogue clean-up, and until it is done every
category-level decision the business makes is working with a blind spot of
unknown composition.

**3. Start capturing the data needed to explain the plateau.** Order volume has
driven every revenue movement for 25 months and has been flat for nine of them.
This dataset can show *that* customer acquisition stopped growing, but it holds
no marketing spend, traffic, channel or seller-onboarding information, so it
cannot show *why*. Capturing those alongside orders would make the next
plateau diagnosable instead of merely visible. Nothing in the current data
supports blaming pricing, product range or competition.

---

*Note: November 2017's record month is consistent with Brazilian Black Friday
timing, but the dataset contains no promotion or campaign field, so this remains
an untested hypothesis rather than a finding.*
