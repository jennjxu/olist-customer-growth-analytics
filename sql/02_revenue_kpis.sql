-- Total number of orders
-- Business question: How many orders are in the dataset?
-- Finding: The dataset contains 99,441 orders.
SELECT
    COUNT(*) AS total_orders
FROM orders;


-- Total number of unique customers
-- Business question: How many unique customers are in the dataset?
-- Finding: The dataset includes 96,096 unique customers.
SELECT
    COUNT(DISTINCT customer_unique_id) AS total_unique_customers
FROM customers;


-- Total merchandise revenue, excluding freight
-- Business question: How much merchandise revenue was generated?
-- Finding: Total merchandise revenue was approximately 13.59 million, excluding freight charges.
SELECT
    SUM(price) AS total_merchandise_revenue
FROM order_items;


-- Average merchandise value per order represented in order_items
-- Business question: What is the average merchandise value per order?
-- Finding: Average merchandise value per order was approximately 137.75.
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


-- Monthly merchandise revenue
-- Business question: How did merchandise revenue change over time?
-- Finding: Merchandise revenue increased substantially across 2017 and remained at relatively high levels through much of 2018, while edge months contained incomplete or very low activity.
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    SUM(oi.price) AS monthly_merchandise_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;


-- Monthly order volume
-- Business question: How did order volume change over time?
-- Finding: Monthly order volume generally increased through 2017 and remained elevated in 2018, with partial edge months showing unusually low counts.
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(*) AS monthly_order_volume
FROM orders o
GROUP BY month
ORDER BY month;


-- Monthly revenue, order volume, and average order value
-- Business question: How did monthly revenue, order volume, and average order value move together?
-- Finding: Revenue growth was driven primarily by higher order volume, while monthly average order value remained comparatively stable across most full months.
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


-- Product categories ranked by merchandise revenue
-- Business question: Which product categories generated the most merchandise revenue?
-- Finding: Health & Beauty generated the highest merchandise revenue, followed by Watches & Gifts, Bed Bath & Table, Sports & Leisure, and Computers & Accessories.
SELECT
    p.product_category_name AS product_category,
    SUM(oi.price) AS category_revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY category_revenue DESC;


-- Sellers ranked by merchandise revenue
-- Business question: Which sellers generated the most merchandise revenue?
-- Finding: Merchandise revenue was concentrated among a relatively small set of top-performing sellers, with the leading seller generating approximately 229.5 thousand.
SELECT
    oi.seller_id AS seller_id,
    SUM(oi.price) AS merchandise_revenue
FROM order_items oi
GROUP BY oi.seller_id
ORDER BY merchandise_revenue DESC;


-- Month-over-month merchandise revenue growth
-- Business question: How much did merchandise revenue increase or decrease from month to month?
-- Finding: Month-over-month revenue growth varied considerably, including a strong increase in November 2017 and a decline in December 2017. Extremely large percentage changes in partial or very low-volume months should be interpreted cautiously.
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(oi.price) AS monthly_merchandise_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY month
    ORDER BY month
)

SELECT
    month,
    monthly_merchandise_revenue,
    LAG(monthly_merchandise_revenue) OVER (
        ORDER BY month
    ) AS previous_month_revenue,
    (
        monthly_merchandise_revenue
        - LAG(monthly_merchandise_revenue) OVER (
            ORDER BY month
        )
    )
    /
    LAG(monthly_merchandise_revenue) OVER (
        ORDER BY month
    )
    * 100 AS percentage_change
FROM monthly_revenue;


-- Month-over-month order volume growth
-- Business question: How much did order volume increase or decrease from month to month?
-- Finding: Monthly order growth fluctuated over time, with November 2017 showing a notable increase of about 62.9%. Partial months produced extreme percentage changes and should not be treated as normal business trends.
WITH monthly_orders AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        COUNT(*) AS monthly_order_volume
    FROM orders o
    GROUP BY month
    ORDER BY month
)

SELECT
    month,
    monthly_order_volume,
    LAG(monthly_order_volume) OVER (
        ORDER BY month
    ) AS previous_month_order_volume,
    (
        monthly_order_volume
        - LAG(monthly_order_volume) OVER (
            ORDER BY month
        )
    )
    /
    LAG(monthly_order_volume) OVER (
        ORDER BY month
    )::NUMERIC
    * 100 AS percentage_change
FROM monthly_orders;


-- One-time vs repeat customer counts
-- Business question: How many customers purchased once versus more than once?
-- Finding: Of 96,096 unique customers, 93,099 purchased once and 2,997 purchased more than once. Repeat customers represented about 3.1% of the customer base.
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
GROUP BY customer_type;


-- Customer purchase frequency distribution
-- Business question: How many customers placed 1, 2, 3, or more orders?
-- Finding: Purchase frequency was heavily concentrated among one-time customers. Among repeat customers, 2,745 placed exactly two orders, while only a small number placed three or more orders.
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(*) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)

SELECT
    order_count,
    COUNT(*) AS customer_count
FROM customer_orders
GROUP BY order_count
ORDER BY order_count;


-- Customers ranked by purchase frequency
-- Business question: Which customers placed the most orders?
-- Finding: The highest-frequency customer placed 17 orders, followed by one customer with 9 orders and three customers tied at 7 orders. High-frequency purchasing was rare relative to the broader customer base.
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(*) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    order_count,
    RANK() OVER (
        ORDER BY order_count DESC
    ) AS customer_rank
FROM customer_orders
ORDER BY order_count DESC;