SELECT COUNT(*)
FROM orders;

CREATE TABLE customers(
    customer_id character varying PRIMARY KEY,
    customer_unique_id character varying,
    customer_zip_code_prefix integer,
    customer__city character varying,
    customer_state character varying
);
SELECT COUNT(*)
FROM customers;

CREATE TABLE order_items (
    order_id character varying,
    order_item_id integer,
    product_id character varying,
    seller_id character varying,
    shipping_limit_date timestamp without time zone,
    price numeric (10,2),
    freight_value numeric (10,2),
    PRIMARY KEY (order_id, order_item_id)
);
SELECT COUNT(*)
FROM order_items;


--this shows that each order is from wich customer and the city and state of the customer.
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp
FROM orders o
JOIN customers c 
ON o.customer_id = c.customer_id 
LIMIT 20;


--sales data JOIN
-- combines orders, customers, and order items to create a transaction level view containing customer, product, and price information.
SELECT 
    o.order_id,
    c.customer_unique_id,
    oi.product_id,
    oi.price,
    oi.freight_value,
    o.order_purchase_timestamp
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id 
LIMIT 20;


-- RAW TOTAL REVENUE
-- calculates total item revenue before filtering by order status.this is used as an initial check and is not the final revenue KPI.
SELECT 
    SUM(oi.price) AS total_revenue
FROM order_items oi;


-- DELIVERED REVENUE
-- calculates total revenue only from delivered orders.
SELECT 
    SUM(oi.price) AS delivered_revenue
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';


--AVARAGE ORDER VALUE
-- calculates the avarage amount spent per delivered ORDER 
--step1: calculate the total value of each delivrerd ORDER 
WITH order_revenue AS (
    SELECT 
        oi.order_id,
        SUM(oi.price) AS order_value
    FROM order_items oi
    JOIN orders o 
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.order_id
)
--step2: calculate the average value across all delivered orders
SELECT 
    ROUND(AVG(order_value), 2) AS average_order_value
    FROM order_revenue;

-- ORDER STATUS ANALYSIS
-- group order by status and count how many orders belong to each status. 
SELECT 
    order_status, COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


--MONTHLY REVENUE 
-- calculates the total revenue for each month 
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price), 2) AS monthly_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;






--the precentage of growth in comparison to the last month for delivered orders.
-- uses LAG() to retrieve the previous months revenue.a
with monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        ROUND(SUM(oi.price), 2) AS monthly_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY month
),
monthly_comparison AS (
    SELECT 
        month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (ORDER BY month) AS previous_month_revenue
    FROM monthly_sales
)




--product analysis
--TOP 10 products by revenue
--which products made the most revenue. 
SELECT 
    product_id,
    SUM(price) AS total_revenue
FROM order_items
GROUP BY product_id
ORDER BY total_revenue DESC
LIMIT 10;

-- CHECK PRODUCTS IMPORT
-- Checks how many product records were successfully imported.

SELECT COUNT(*)
FROM products;

-- TOP 10 PRODUCT CATEGORIES BY REVENUE
-- Joins product information with order items.
-- Groups sales by product category and calculates total revenue.
-- Returns the 10 highest-revenue categories.
SELECT 
    products.product_category_name,
    SUM(oi.price) AS total_revenue
FROM products
JOIN order_items oi
    ON products.product_id = oi.product_id
GROUP BY products.product_category_name
ORDER BY total_revenue DESC
LIMIT 10;


-- TOP 10 PRODUCT CATEGORIES BY NUMBER OF ITEMS SOLD
-- Counts the number of sold items in each product category.
-- Excludes products without a category and returns the top 10.
SELECT 
products.product_category_name,
COUNT(*) AS product_count
FROM order_items oi
JOIN products
    ON oi.product_id = products.product_id
    WHERE products.product_category_name IS NOT NULL
GROUP BY products.product_category_name
ORDER BY product_count DESC
LIMIT 10;


-- CUSTOMER ID CHECK
-- Shows that customer_id is generally unique per order,
-- so it should not be used to identify repeat customers.
SELECT 
    customer_id,
    COUNT(*) AS total_orders  
FROM orders
WHERE order_status = 'delivered'
GROUP BY customer_id
ORDER BY total_orders DESC
LIMIT 20;


-- TOP REPEAT CUSTOMERS
-- Joins orders with customers using customer_id.
-- Uses customer_unique_id to identify the same real customer across multiple orders.
-- Counts delivered orders per customer and returns the most frequent buyers.
SELECT
    c.customer_unique_id,
    COUNT(*) AS total_orders
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY total_orders DESC
LIMIT 20;


--1 order       → New / One-time customer
--2+ orders     → Returning customer
SELECT
    c.customer_unique_id,
    COUNT(*) AS total_orders
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
HAVING COUNT(*) > 1
ORDER BY total_orders DESC;


-- CUSTOMER LOCATION ANALYSIS
-- Counts unique customers in each city.
-- Uses DISTINCT customer_unique_id to avoid counting the same customer multiple times.
-- Sorts cities from highest to lowest number of customers.
SELECT
    customer__city,
    COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers
GROUP BY customer__city
ORDER BY total_customers DESC;

-- CUSTOMER STATE ANALYSIS
SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers
GROUP BY customer_state
ORDER BY total_customers DESC;

-- MONTHLY ORDER TREND
-- Counts delivered orders per month.
SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    COUNT(*) AS total_orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY month
ORDER BY month;

-- MONTHLY REVENUE TREND
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    SUM(oi.price) AS monthly_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;

-- MONTHLY ORDER AND REVENUE TREND
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.price) AS monthly_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;



--returning customers rate
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(*) AS total_orders
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

, customer_segments AS (
    SELECT
        customer_unique_id,
        total_orders,
        CASE
            WHEN total_orders = 1 THEN 'One-time'
            ELSE 'Returning'
        END AS customer_type
    FROM customer_orders
)
--SELECT
 --   customer_type,
--    COUNT(*) AS total_customers
--FROM customer_segments
--GROUP BY customer_type;

SELECT
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE customer_type = 'Returning')
        / COUNT(*),
        2
    ) AS returning_customer_rate
FROM customer_segments;

-- REVENUE BY STATE
-- Calculates delivered-order revenue for each customer state.
-- Sorts states from highest to lowest revenue.

SELECT
    c.customer_state,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC;


-- AVERAGE ORDER VALUE BY STATE
-- Calculates the average value of delivered orders in each state.

WITH order_values AS (
    SELECT
        o.order_id,
        c.customer_state,
        SUM(oi.price) AS order_value
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id, c.customer_state
)

SELECT
    customer_state,
    ROUND(AVG(order_value), 2) AS average_order_value
FROM order_values
GROUP BY customer_state
ORDER BY average_order_value DESC;


-- CATEGORY PERFORMANCE
-- Compares revenue and number of items sold for each product category.

SELECT
    p.product_category_name,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE p.product_category_name IS NOT NULL
    AND o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;

-- AVERAGE ITEM PRICE BY CATEGORY
-- Calculates the average selling price of items in each product category.
-- Uses only delivered orders.
SELECT
    p.product_category_name,
    COUNT(*) AS items_sold,
    ROUND(AVG(oi.price), 2) AS average_item_price,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE p.product_category_name IS NOT NULL
    AND o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY average_item_price DESC;




-- AVERAGE DELIVERY TIME
-- Calculates average delivery time in days for delivered orders.
SELECT
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_delivered_customer_date
                    - order_purchase_timestamp
                )
            ) / 86400
        ),
        2
    ) AS average_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;



-- LATE DELIVERY RATE
-- Calculates the percentage of delivered orders
-- that arrived after the estimated delivery date.

SELECT
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_delivered_customer_date > order_estimated_delivery_date
        ) / COUNT(*),
        2
    ) AS late_delivery_rate
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
