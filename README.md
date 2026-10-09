# Customer & Marketing Analytics: An End-to-End SQL, Statistics & ML Project

## Overview

I built this project to practice the full analytics and data science workflow on a realistic relational e-commerce dataset.

Rather than jumping straight into modeling, I started by validating the underlying data structure, customer identifiers, missingness, and table relationships. From there, I moved into PostgreSQL and SQL-based analysis of revenue, order trends, product performance, seller performance, and customer purchasing behavior.

The project is built around a simple idea: **good analysis starts with trustworthy data**.

My goal is to demonstrate the full analytical process — from raw relational data to business insight, and ultimately to statistical and machine-learning decision support.

---

## Key Results

So far, the analysis has found:

- **99,441 orders**
- **96,096 unique customers**
- approximately **13.59 million** in merchandise revenue, excluding freight
- approximately **137.75** average merchandise value per order
- only **3.1% of customers** purchased more than once
- **2,745 of 2,997 repeat customers** placed exactly two orders
- the highest-frequency customer placed **17 orders**
- revenue growth across most complete months was driven primarily by increasing order volume rather than major changes in average order value
- November 2017 showed approximately **62.9% month-over-month order growth**

These findings establish the baseline for deeper customer, retention, segmentation, and predictive analysis.

---

## Business Questions

The analysis completed so far focuses on questions such as:

- How many orders and unique customers are represented in the data?
- How much merchandise revenue was generated?
- What is the average merchandise value per order?
- How did revenue and order volume change over time?
- Was revenue growth driven more by order volume or order value?
- Which product categories generated the most merchandise revenue?
- Which sellers generated the most merchandise revenue?
- How much did revenue and order volume change month over month?
- How common is repeat purchasing?
- How frequently do repeat customers return?
- Which customers placed the most orders?

---

## Tech Stack

**Data Analysis**
- Python
- pandas
- Jupyter Notebook

**Database & Querying**
- PostgreSQL
- SQL

**Development**
- VS Code
- Git
- GitHub

---

## Dataset

This project uses the **Olist Brazilian E-Commerce Public Dataset**, an anonymized commercial e-commerce dataset.

Seven core tables are currently used:

- `customers`
- `orders`
- `order_items`
- `products`
- `payments`
- `reviews`
- `sellers`

| Table | Rows |
|---|---:|
| Customers | 99,441 |
| Orders | 99,441 |
| Order Items | 112,650 |
| Products | 32,951 |
| Payments | 103,886 |
| Reviews | 99,224 |
| Sellers | 3,095 |

Together, these tables describe customer identities, purchases, order status, products, sellers, payments, and reviews.

---

## Data Model

The project uses a relational e-commerce schema.

```text
customers
    |
    | customer_id
    v
orders
    |
    | order_id
    +----------------------+
    |                      |
    v                      v
order_items             payments
    |
    | product_id
    v
products

order_items
    |
    | seller_id
    v
sellers

orders
    |
    | order_id
    v
reviews
```

### Customer Identity

One of the first things I investigated was the difference between `customer_id` and `customer_unique_id`.

- `customer_id` identifies customer records and is used to join customers to orders.
- `customer_unique_id` represents the underlying customer across records and is used for repeat-purchase and customer-level analysis.

This distinction matters because multiple customer records can correspond to the same underlying customer. Using the wrong identifier would distort repeat-customer metrics.

---

## Methodology

The project is structured as an end-to-end analytical workflow.

```text
Raw CSV files
        ↓
Python / pandas audit
        ↓
Key and relationship validation
        ↓
PostgreSQL database
        ↓
Database quality checks
        ↓
SQL business analysis
        ↓
Customer behavior analysis
```

Additional completed stages — such as segmentation, statistical inference, predictive modeling, and dashboarding — can be inserted into this workflow as the project evolves.

---

## 1. Data Quality Audit

Before performing business analysis, I audited the seven source tables in Python using pandas.

The audit included:

- row and column counts
- data-type inspection
- missing-value analysis
- duplicate-row checks
- primary and composite-key validation
- customer-identity validation
- order-lifecycle investigation
- relationship and join-risk checks
- monetary distribution analysis

### Key Findings From the Audit

- `customers` contains 99,441 records with no missing or fully duplicated rows.
- `customer_id` is unique, while `customer_unique_id` can repeat across records.
- `orders` contains 99,441 unique order IDs.
- Missing delivery-related timestamps are mostly associated with orders that had not completed the delivery lifecycle.
- `order_id + order_item_id` uniquely identifies rows in `order_items`.
- `order_id + payment_sequential` uniquely identifies rows in `payments`.
- `product_id` is unique in the product table.
- `seller_id` is unique in the seller table.
- Review records require care because neither `review_id` nor `order_id` is unique at the row level.
- Price and freight distributions are right-skewed.
- Some product metadata is missing.
- Sellers are heavily concentrated in São Paulo state.

### Analytical Decisions

Based on the audit:

- I use `customer_unique_id` for customer-level repeat-purchase analysis.
- I use `customer_id` to join customers to orders.
- I interpret missing delivery timestamps in the context of order status rather than automatically treating them as bad data.
- I account for the fact that not every order appears in `order_items`.
- I use caution when joining review records.
- I consider medians alongside means for strongly skewed monetary variables.

The data is sufficiently structured for downstream customer and revenue analysis provided these identity, missingness, and relationship considerations are handled carefully.

---

## 2. PostgreSQL Validation

After auditing the source data in Python, I loaded the seven core tables into PostgreSQL.

I then performed database-level checks to verify that the database load was consistent with the source data.

Validation included:

- table row counts
- order-status distribution
- payment-type distribution

The PostgreSQL results matched the earlier pandas audit, providing an additional validation step before business analysis.

---

## 3. SQL Business Analysis

The SQL analysis is organized around explicit business questions and documented findings.

### Core Business Metrics

Key results:

- **99,441 total orders**
- **96,096 unique customers**
- approximately **13.59 million** in merchandise revenue, excluding freight
- approximately **137.75** average merchandise value per order

---

### Revenue and Order Trends

Monthly merchandise revenue and monthly order volume were analyzed together.

Revenue increased substantially through 2017 and remained relatively high through much of 2018.

Across most complete months, average order value remained comparatively stable while order volume increased. This suggests that revenue growth was driven primarily by higher transaction volume rather than a large increase in order value.

Partial months at the beginning and end of the dataset were treated cautiously because unusually low activity can distort comparisons.

---

### Month-over-Month Growth

I used SQL window functions, including `LAG()`, to calculate month-over-month changes in revenue and order volume.

The analysis showed substantial variation across months.

November 2017 was a particularly strong growth period, with order volume increasing by approximately **62.9%** compared with the previous available month.

Very small or partial comparison months produced extreme percentage changes, so those periods were not interpreted as normal business trends.

---

### Product Category Performance

Product categories were ranked by merchandise revenue.

The top categories included:

1. Health & Beauty
2. Watches & Gifts
3. Bed Bath & Table
4. Sports & Leisure
5. Computers & Accessories

These results provide an initial view of which product groups contribute most strongly to merchandise revenue.

---

### Seller Performance

Sellers were ranked by merchandise revenue.

The leading seller generated approximately **229.5 thousand** in merchandise revenue.

This provides an initial view of seller concentration within the marketplace.

---

## 4. Customer Behavior

### One-Time vs Repeat Customers

The dataset contains **96,096 unique customers**.

- **93,099** customers placed one order.
- **2,997** customers placed more than one order.
- Repeat customers represent approximately **3.1%** of the customer base.

This suggests that repeat purchasing is relatively uncommon in the observed data.

---

### Purchase Frequency

Customer purchase frequency is heavily concentrated at low levels.

| Orders per Customer | Number of Customers |
|---:|---:|
| 1 | 93,099 |
| 2 | 2,745 |
| 3 | 203 |
| 4 | 30 |
| 5 | 8 |
| 6 | 6 |
| 7 | 3 |
| 9 | 1 |
| 17 | 1 |

Among repeat customers, most placed exactly two orders. Only a very small number purchased three or more times, indicating that deeper repeat-purchase behavior is rare.

---

### Customer Ranking

I used the SQL `RANK()` window function to identify the highest-frequency customers.

The highest-frequency customer placed **17 orders**, followed by:

- one customer with **9 orders**
- three customers tied at **7 orders**
- several customers with **6 orders**

Using `RANK()` allowed customers with tied purchase frequencies to receive the same rank.

---

## Business Implications

The current analysis suggests several areas worth deeper investigation:

- repeat purchasing is uncommon, making retention and second-purchase behavior an important customer problem
- most repeat customers only purchase twice, indicating limited deeper engagement
- revenue growth appears more closely associated with increasing transaction volume than large changes in average order value
- product and seller performance are unevenly distributed, suggesting potential opportunities for segmentation and concentration analysis
- data-quality decisions around customer identity, order lifecycle, and joins materially affect downstream metrics

These findings provide a foundation for more advanced customer and decision-focused analysis.

---

## Limitations

A few limitations are important when interpreting the current analysis:

- The dataset represents historical Olist activity in Brazil and should not automatically be generalized to other markets.
- Some months at the beginning and end of the dataset contain incomplete activity.
- Merchandise revenue is currently defined using item price and excludes freight unless otherwise stated.
- Some orders do not contain corresponding order-item records.
- Product metadata contains missing values.
- Review records require careful joins because identifiers are not unique at the row level.
- Observational patterns in the data should not be interpreted as causal effects without an appropriate experimental or causal design.

---

## Repository Structure

```text
olist-customer-growth-analytics/
│
├── data/
│   └── raw/
│       └── [local Olist CSV files — not tracked in Git]
│
├── notebooks/
│   └── data_audit.ipynb
│
├── sql/
│   ├── 01_data_quality.sql
│   └── 02_revenue_kpis.sql
│
├── .gitignore
└── README.md
```

---

## Why I Built This Project

I wanted this project to reflect the kind of work I would expect to do in an analytics or data science role: understand relational data, validate it, answer business questions, document analytical decisions, apply appropriate quantitative methods, and communicate what matters.

This project is designed to demonstrate an end-to-end analytical workflow rather than a single dashboard or model, connecting raw data preparation and analysis to business decision-making.