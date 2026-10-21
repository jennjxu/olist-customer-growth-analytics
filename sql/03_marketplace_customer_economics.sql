-- Week 2: Marketplace & Customer Economics
--
-- Purpose:
-- Explain how marketplace value is generated and concentrated before
-- moving into customer segmentation and predictive modeling.
--
-- Core questions:
-- 1. What drives revenue growth: order volume, average order value, or both?
-- 2. How do product categories differ in their volume-value economics?
-- 3. Why are repeat customers more valuable?
-- 4. How unevenly is customer value distributed?
-- 5. How concentrated is revenue across customers and sellers?
--
-- Metric definitions:
-- Merchandise revenue = SUM(order_items.price), excluding freight.
-- Order volume = COUNT(DISTINCT order_id).
-- Average order value = merchandise revenue / distinct orders represented
-- in order_items.


-- ============================================================
-- 1. MARKETPLACE PERFORMANCE OVER TIME
-- ============================================================

-- Question:
-- How closely do revenue and order volume move together month to month?
WITH monthly_performance AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(oi.price) AS revenue,
        COUNT(DISTINCT o.order_id) AS order_volume
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY month
)

SELECT
    month,
    order_volume,
    LAG(order_volume) OVER (
        ORDER BY month
    ) AS previous_month_order_volume,
    ROUND(
        (
            order_volume
            - LAG(order_volume) OVER (ORDER BY month)
        )
        /
        LAG(order_volume) OVER (ORDER BY month)::NUMERIC
        * 100,
        2
    ) AS order_volume_percentage_change,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        LAG(revenue) OVER (
            ORDER BY month
        ),
        2
    ) AS previous_month_revenue,
    ROUND(
        (
            revenue
            - LAG(revenue) OVER (ORDER BY month)
        )
        /
        LAG(revenue) OVER (ORDER BY month)
        * 100,
        2
    ) AS revenue_percentage_change
FROM monthly_performance
ORDER BY month;


-- Question:
-- How much does average order value vary relative to revenue and order volume?
WITH monthly_aov AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(oi.price) AS revenue,
        COUNT(DISTINCT o.order_id) AS order_volume,
        SUM(oi.price) / COUNT(DISTINCT o.order_id) AS average_order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY month
)

SELECT
    month,
    order_volume,
    ROUND(revenue, 2) AS revenue,
    ROUND(average_order_value, 2) AS average_order_value,
    ROUND(
        LAG(average_order_value) OVER (
            ORDER BY month
        ),
        2
    ) AS previous_month_average_order_value,
    ROUND(
        (
            average_order_value
            - LAG(average_order_value) OVER (ORDER BY month)
        )
        /
        LAG(average_order_value) OVER (ORDER BY month)
        * 100,
        2
    ) AS average_order_value_percentage_change
FROM monthly_aov
ORDER BY month;


-- ============================================================
-- 2. PRODUCT CATEGORY ECONOMICS
-- ============================================================

-- Question:
-- How do categories differ in revenue, sales volume, and average item value?
WITH category_performance AS (
    SELECT
        p.product_category_name AS product_category,
        SUM(oi.price) AS revenue,
        COUNT(DISTINCT oi.order_id) AS distinct_order_volume,
        COUNT(*) AS items_sold,
        AVG(oi.price) AS average_item_value
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    GROUP BY p.product_category_name
)

SELECT
    product_category,
    ROUND(revenue, 2) AS revenue,
    distinct_order_volume,
    items_sold,
    ROUND(average_item_value, 2) AS average_item_value,
    ROUND(
        revenue / SUM(revenue) OVER () * 100,
        2
    ) AS revenue_share
FROM category_performance
ORDER BY revenue DESC;


-- Question:
-- How concentrated is merchandise revenue across product categories?
WITH category_performance AS (
    SELECT
        p.product_category_name AS product_category,
        SUM(oi.price) AS revenue
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    GROUP BY p.product_category_name
),

category_shares AS (
    SELECT
        product_category,
        revenue,
        revenue / SUM(revenue) OVER () * 100 AS revenue_share
    FROM category_performance
)

SELECT
    product_category,
    ROUND(revenue, 2) AS revenue,
    ROUND(revenue_share, 2) AS revenue_share,
    ROUND(
        SUM(revenue_share) OVER (
            ORDER BY revenue DESC
        ),
        2
    ) AS cumulative_revenue_share
FROM category_shares
ORDER BY revenue DESC;


-- ============================================================
-- 3. CUSTOMER ECONOMICS
-- ============================================================

-- Customer grain:
-- one row per customer_unique_id represented in order_items.


-- Validation:
-- confirm the customer-level analytical table has the expected row count.
WITH customer_performance AS (
    SELECT
        c.customer_unique_id AS customer_id,
        SUM(oi.price) AS total_customer_revenue,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.price) / COUNT(DISTINCT o.order_id) AS average_order_value,
        MIN(o.order_purchase_timestamp) AS first_purchase_date,
        MAX(o.order_purchase_timestamp) AS last_purchase_date,
        CASE
            WHEN COUNT(DISTINCT o.order_id) = 1 THEN 'one-time'
            ELSE 'repeat'
        END AS repeat_status
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)

SELECT
    COUNT(*) AS customer_rows
FROM customer_performance;


-- Validation:
-- confirm one-time and repeat customer counts.
WITH customer_performance AS (
    SELECT
        c.customer_unique_id AS customer_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        CASE
            WHEN COUNT(DISTINCT o.order_id) = 1 THEN 'one-time'
            ELSE 'repeat'
        END AS repeat_status
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)

SELECT
    repeat_status,
    COUNT(*) AS customer_count
FROM customer_performance
GROUP BY repeat_status
ORDER BY repeat_status;


-- Validation:
-- confirm repeat-status logic is internally consistent.
WITH customer_performance AS (
    SELECT
        c.customer_unique_id AS customer_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        CASE
            WHEN COUNT(DISTINCT o.order_id) = 1 THEN 'one-time'
            ELSE 'repeat'
        END AS repeat_status
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)

SELECT
    customer_id,
    order_count,
    repeat_status
FROM customer_performance
WHERE
    (repeat_status = 'one-time' AND order_count <> 1)
    OR
    (repeat_status = 'repeat' AND order_count <= 1);


-- Question:
-- Why are repeat customers more valuable than one-time customers?
WITH customer_performance AS (
    SELECT
        c.customer_unique_id AS customer_id,
        SUM(oi.price) AS total_customer_revenue,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.price) / COUNT(DISTINCT o.order_id) AS average_order_value,
        CASE
            WHEN COUNT(DISTINCT o.order_id) = 1 THEN 'one-time'
            ELSE 'repeat'
        END AS repeat_status
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)

SELECT
    repeat_status,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_customer_revenue), 2) AS total_revenue,
    ROUND(AVG(total_customer_revenue), 2) AS average_revenue_per_customer,
    ROUND(AVG(order_count), 2) AS average_order_count,
    ROUND(AVG(average_order_value), 2) AS average_order_value
FROM customer_performance
GROUP BY repeat_status
ORDER BY repeat_status;


-- Question:
-- How unevenly is customer merchandise revenue distributed?
WITH customer_performance AS (
    SELECT
        c.customer_unique_id AS customer_id,
        SUM(oi.price) AS total_customer_revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)

SELECT
    ROUND(
        MIN(total_customer_revenue),
        2
    ) AS minimum_customer_revenue,

    ROUND(
        PERCENTILE_CONT(0.50) WITHIN GROUP (
            ORDER BY total_customer_revenue
        )::NUMERIC,
        2
    ) AS median_customer_revenue,

    ROUND(
        AVG(total_customer_revenue),
        2
    ) AS average_customer_revenue,

    ROUND(
        PERCENTILE_CONT(0.75) WITHIN GROUP (
            ORDER BY total_customer_revenue
        )::NUMERIC,
        2
    ) AS percentile_75_customer_revenue,

    ROUND(
        PERCENTILE_CONT(0.90) WITHIN GROUP (
            ORDER BY total_customer_revenue
        )::NUMERIC,
        2
    ) AS percentile_90_customer_revenue,

    ROUND(
        PERCENTILE_CONT(0.95) WITHIN GROUP (
            ORDER BY total_customer_revenue
        )::NUMERIC,
        2
    ) AS percentile_95_customer_revenue,

    ROUND(
        MAX(total_customer_revenue),
        2
    ) AS maximum_customer_revenue
FROM customer_performance;


-- ============================================================
-- 4. CUSTOMER REVENUE CONCENTRATION
-- ============================================================

-- Question:
-- What share of merchandise revenue is generated by the highest-value customers?
WITH customer_performance AS (
    SELECT
        c.customer_unique_id AS customer_id,
        SUM(oi.price) AS total_customer_revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
),

ranked_customers AS (
    SELECT
        customer_id,
        total_customer_revenue,
        NTILE(100) OVER (
            ORDER BY total_customer_revenue DESC
        ) AS customer_percentile
    FROM customer_performance
)

SELECT
    ROUND(
        SUM(
            CASE
                WHEN customer_percentile = 1
                THEN total_customer_revenue
                ELSE 0
            END
        )
        /
        SUM(total_customer_revenue)
        * 100,
        2
    ) AS top_1_percent_revenue_share,

    ROUND(
        SUM(
            CASE
                WHEN customer_percentile <= 5
                THEN total_customer_revenue
                ELSE 0
            END
        )
        /
        SUM(total_customer_revenue)
        * 100,
        2
    ) AS top_5_percent_revenue_share,

    ROUND(
        SUM(
            CASE
                WHEN customer_percentile <= 10
                THEN total_customer_revenue
                ELSE 0
            END
        )
        /
        SUM(total_customer_revenue)
        * 100,
        2
    ) AS top_10_percent_revenue_share
FROM ranked_customers;


-- ============================================================
-- 5. SELLER REVENUE CONCENTRATION
-- ============================================================

-- Question:
-- How concentrated is marketplace merchandise revenue across sellers?
WITH seller_performance AS (
    SELECT
        s.seller_id,
        SUM(oi.price) AS total_seller_revenue
    FROM sellers s
    JOIN order_items oi
        ON s.seller_id = oi.seller_id
    GROUP BY s.seller_id
),

ranked_sellers AS (
    SELECT
        seller_id,
        total_seller_revenue,
        NTILE(100) OVER (
            ORDER BY total_seller_revenue DESC
        ) AS seller_percentile
    FROM seller_performance
)

SELECT
    ROUND(
        SUM(
            CASE
                WHEN seller_percentile = 1
                THEN total_seller_revenue
                ELSE 0
            END
        )
        /
        SUM(total_seller_revenue)
        * 100,
        2
    ) AS top_1_percent_revenue_share,

    ROUND(
        SUM(
            CASE
                WHEN seller_percentile <= 5
                THEN total_seller_revenue
                ELSE 0
            END
        )
        /
        SUM(total_seller_revenue)
        * 100,
        2
    ) AS top_5_percent_revenue_share,

    ROUND(
        SUM(
            CASE
                WHEN seller_percentile <= 10
                THEN total_seller_revenue
                ELSE 0
            END
        )
        /
        SUM(total_seller_revenue)
        * 100,
        2
    ) AS top_10_percent_revenue_share
FROM ranked_sellers;