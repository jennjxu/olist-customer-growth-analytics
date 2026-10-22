-- Pre-Week 3 Quality Assurance
--
-- Check 1: Order-status eligibility
--
-- Question:
-- How is merchandise value distributed across order statuses?

WITH status_revenue AS (
    SELECT
        o.order_status,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.price) AS merchandise_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.order_status
)

SELECT
    order_status,
    merchandise_value,
    ROUND(
        merchandise_value / SUM(merchandise_value) OVER () * 100,
        2
    ) AS merchandise_share_pct
FROM status_revenue
ORDER BY merchandise_value DESC;

-- Finding:
-- Delivered orders account for approximately 97.28% of
-- recorded merchandise value.
-- Canceled and unavailable orders account for approximately 0.72%.
--
-- Decision:
-- Retain the all-status merchandise-value definition for
-- historical Week 2 reporting.
--
-- Limitation:
-- Recorded merchandise value is not equivalent to recognized revenue.
-- Point-in-time order eligibility will be defined separately
-- for customer segmentation and predictive modeling.

WITH customer_merchandise_value AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS customer_merchandise_value
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
),

customer_total AS (
    SELECT
        COUNT(*) AS customer_count,
        SUM(customer_merchandise_value) AS sum_customer_merchandise_value
    FROM customer_merchandise_value
),

marketplace_total AS (
    SELECT
        SUM(price) AS marketplace_merchandise_value
    FROM order_items
)

SELECT
    ct.customer_count,
    ct.sum_customer_merchandise_value,
    mt.marketplace_merchandise_value,
    mt.marketplace_merchandise_value
        - ct.sum_customer_merchandise_value AS difference
FROM customer_total ct
CROSS JOIN marketplace_total mt;

-- Finding:
-- Customer-level merchandise value reconciles exactly to
-- marketplace merchandise value (R$13,591,643.70).
-- The customer-level population contains 95,420 unique customers.
-- The reconciliation difference is R$0.00.
--
-- Interpretation:
-- Customer-level aggregation preserves total recorded
-- merchandise value with no net reconciliation discrepancy.
-- Combined with prior key and relationship checks, this
-- supports the reliability of Week 2 customer economics.
-- Week 3 snapshot features require separate temporal validation.