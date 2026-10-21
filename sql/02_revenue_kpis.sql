-- Week 1: Baseline Marketplace Metrics
--
-- Purpose:
-- Establish reliable baseline customer, order, and revenue metrics after
-- validating the relational data foundation.
--
-- These metrics provide the reference point for the deeper marketplace
-- and customer-economics analysis developed in Week 2.


-- Total orders
-- Metric role: establish marketplace transaction scale.
-- Finding: 99,441 orders.
SELECT
    COUNT(*) AS total_orders
FROM orders;


-- Unique customers
-- Metric role:
-- establish the customer population using customer_unique_id,
-- the identifier used for customer-level analysis.
--
-- Finding: 96,096 unique customers.
SELECT
    COUNT(DISTINCT customer_unique_id) AS total_unique_customers
FROM customers;


-- Total merchandise revenue
-- Metric definition:
-- merchandise revenue = item price only; freight excluded.
--
-- Finding: approximately 13.59 million in merchandise revenue.
SELECT
    SUM(price) AS total_merchandise_revenue
FROM order_items;


-- Average merchandise value per order
-- Metric role:
-- establish the baseline merchandise value generated per order represented
-- in order_items.
--
-- Finding: approximately 137.75 per order.
WITH order_totals AS (
    SELECT
        order_id,
        SUM(price) AS order_value
    FROM order_items
    GROUP BY order_id
)

SELECT
    AVG(order_value) AS average_order_value
FROM order_totals;


-- Monthly revenue, order volume, and average order value
-- Purpose:
-- establish an initial view of marketplace performance over time.
--
-- Deeper analysis of the relationship between revenue growth, order volume,
-- and average order value is developed in Week 2.
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    SUM(oi.price) AS monthly_merchandise_revenue,
    COUNT(DISTINCT o.order_id) AS monthly_order_volume,
    SUM(oi.price) / COUNT(DISTINCT o.order_id) AS monthly_average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;


-- One-time vs repeat customer baseline
-- Purpose:
-- establish the prevalence of repeat purchasing before deeper customer-value
-- analysis.
--
-- Customer grain:
-- one row per customer_unique_id.
--
-- Finding:
-- 93,099 one-time customers and 2,997 repeat customers in the full
-- customer population represented in orders.
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(*) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),

customer_types AS (
    SELECT
        customer_unique_id,
        order_count,
        CASE
            WHEN order_count = 1 THEN 'one-time'
            ELSE 'repeat'
        END AS customer_type
    FROM customer_orders
)

SELECT
    customer_type,
    COUNT(*) AS customer_count
FROM customer_types
GROUP BY customer_type
ORDER BY customer_type;