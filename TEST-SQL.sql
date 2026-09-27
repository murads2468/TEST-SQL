--------------QUESTION 1--------------
---Build the Sales Detail Dataset (6 marks)
--Management needs a detailed sales dataset for analysis. Return one row per order item containing:
--order_id and order_date
--customer full name
--store name
--staff full name
--product name
--category name
--brand name
--quantity, list_price, discount
--calculated net_line_revenue

--Include only completed orders (order_status = 4). Sort the result from newest order to oldest.


SELECT
    o.order_id,
    o.order_date,

    CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name,
    s.store_name,
    CONCAT(st.first_name, ' ', st.last_name) AS staff_full_name,

    p.product_name,
    cat.category_name,
    b.brand_name,

    oi.quantity,
    oi.list_price,
    oi.discount,

    oi.quantity * oi.list_price * (1 - oi.discount) AS net_line_revenue

FROM sales.orders AS o

INNER JOIN sales.customers AS c
    ON o.customer_id = c.customer_id

INNER JOIN sales.stores AS s
    ON o.store_id = s.store_id

INNER JOIN sales.staffs AS st
    ON o.staff_id = st.staff_id

INNER JOIN sales.order_items AS oi
    ON o.order_id = oi.order_id

INNER JOIN production.products AS p
    ON oi.product_id = p.product_id

INNER JOIN production.categories AS cat
    ON p.category_id = cat.category_id

INNER JOIN production.brands AS b
    ON p.brand_id = b.brand_id

WHERE o.order_status = 4

ORDER BY o.order_date DESC;

---------QUESTION 2---------------

--Task 2 — Store Performance Summary (5 marks)
--Create a store-level performance report for completed orders showing:
--store name
--number of distinct orders
--total units sold
--total net revenue
--average order value

--Return one row per store and order the stores from highest to lowest total net revenue.


SELECT
    s.store_name,
    COUNT(DISTINCT o.order_id) AS distinct_orders,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount))
     / COUNT(DISTINCT o.order_id) AS average_order_value
FROM sales.orders AS o
JOIN sales.stores AS s
    ON o.store_id = s.store_id
JOIN sales.order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 4
GROUP BY
    s.store_name
ORDER BY
    total_net_revenue DESC;

        --------QUESTOIN 3-------------


--    Task 3 — High-Value Customers (5 marks)
--Management wants to identify high-value customers. 
--Return customers whose total completed-order spending is greater than the average total spending of customers who have completed orders.

--Show customer_id, customer name, completed order count, and total spending. Order the result by total spending descending.WITH customer_spending AS

    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        COUNT(DISTINCT o.order_id) AS completed_order_count,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spending
    FROM sales.customers AS c
    INNER JOIN sales.orders AS o
        ON c.customer_id = o.customer_id
    INNER JOIN sales.order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 4
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name


            -------QUSTION 4---------

--        Task 4 — Inventory Risk Report (5 marks)
--Operations wants to identify inventory risk. Return products where the stock quantity is below 5 in at least one store.

--Show product name, store name, current quantity, category name, and brand name. Products with zero stock should appear first,
--followed by the lowest remaining quantities.

SELECT
    p.product_name,
    s.store_name,
    st.quantity AS current_quantity,
    c.category_name,
    b.brand_name
FROM production.stocks AS st
INNER JOIN production.products AS p
    ON st.product_id = p.product_id
INNER JOIN sales.stores AS s
    ON st.store_id = s.store_id
INNER JOIN production.categories AS c
    ON p.category_id = c.category_id
INNER JOIN production.brands AS b
    ON p.brand_id = b.brand_id
WHERE st.quantity < 5
ORDER BY
    st.quantity ASC;


         ------QUESTION 5--------

--Task 5 — Top Products Within Each Category (6 marks)
--For each product category, identify the top 3 products by total net revenue from completed orders.

--Return category name, product name, total units sold, total net revenue, 
--and the product's position within its category. Tied products must receive the same position and the next position should not contain gaps.
WITH ProductRevenue AS
(
    SELECT
        c.category_name,
        p.product_name,
        SUM(oi.quantity) AS total_units_sold,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue
    FROM sales.order_items oi
    INNER JOIN sales.orders o
        ON oi.order_id = o.order_id
    INNER JOIN production.products p
        ON oi.product_id = p.product_id
    INNER JOIN production.categories c
        ON p.category_id = c.category_id
    WHERE o.order_status = 4
    GROUP BY
        c.category_name,
        p.product_name
),
RankedProducts AS
(
    SELECT
        category_name,
        product_name,
        total_units_sold,
        total_net_revenue,
        DENSE_RANK() OVER
        (
            PARTITION BY category_name
            ORDER BY total_net_revenue DESC
        ) AS product_position
    FROM ProductRevenue
)
SELECT
    category_name,
    product_name,
    total_units_sold,
    total_net_revenue,
    product_position
FROM RankedProducts
WHERE product_position <= 3
ORDER BY
    category_name,
    product_position;













