--case study questions

--1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS totalprice
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id


--2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT (order_date)) AS days_visited
FROM sales
GROUP BY customer_id
ORDER BY customer_id ASC


--3. What was the first item from the menu purchased by each customer?
WITH first_item AS
(
  SELECT customer_id, order_date, product_id, DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS rank_num
  FROM sales 
)

SELECT f.customer_id, m.product_name
FROM first_item f
INNER JOIN .menu m
ON f.product_id = m.product_id
WHERE rank_num = 1


--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 s.product_id, m.product_name, COUNT(s.product_id) AS purchase_count
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY m.product_name, s.product_id
ORDER BY purchase_count DESC


--5. Which item was the most popular for each customer?
WITH cte AS 
(SELECT s.customer_id, s.product_id, m.product_name, COUNT(s.product_id) AS product_count, 
        DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS rank_num
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id, s.product_id, m.product_name)

SELECT customer_id, product_id, product_name, product_count
FROM cte
WHERE rank_num = 1


--6. Which item was purchased first by the customer after they became a member?
WITH cte AS
(
  SELECT s.customer_id, s.order_date, s.product_id, 
  DENSE_RANK() OVER(PARTITION BY  s.customer_id ORDER BY s.order_date)
  AS rank_num
  FROM sales s
  INNER JOIN members m
  ON s.customer_id = m.customer_id
  WHERE s.order_date >= m.join_date
)

SELECT c.customer_id, m.product_name
FROM cte c
JOIN menu m
ON c.product_id = m.product_id
WHERE rank_num = 1
ORDER BY c.customer_id


--7. Which item was purchased just before the customer became a member?
WITH orderbeforemember AS 
(
  SELECT s.customer_id, s.order_date, s.product_id,
  RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS
  rank_num
  FROM sales s
  JOIN members m
  ON s.customer_id = m.customer_id
  WHERE s.order_date < m.join_date
)

SELECT o.customer_id, m.product_name
FROM orderbeforemember o
JOIN menu m
ON o.product_id = m.product_id
WHERE o.rank_num = 1
ORDER BY o.customer_id


--8. What is the total items and amount spent for each member before they became a member?
WITH totalorderbeforemember AS
(
  SELECT s.customer_id, s.order_date, s.product_id
  FROM sales s
  JOIN members m
  ON s.customer_id = m.customer_id
  WHERE s.order_date < m.join_date
)

SELECT t.customer_id, COUNT(*) AS total_items, SUM(m.price) AS amount_spend
FROM totalorderbeforemember t
JOIN menu m
ON t.product_id = m.product_id
GROUP BY t.customer_id
ORDER BY t.customer_id


--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id,
       SUM(CASE WHEN m.product_name = 'sushi' THEN m.price*20
       ELSE m.price*10
       END) AS points
FROM sales s
JOIN menu m 
ON s.product_id = m.product_id
GROUP BY s.customer_id


--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id,SUM( mu.price * 20) AS points
FROM sales s
JOIN menu mu
ON s.product_id = mu.product_id
JOIN members m 
ON s.customer_id = m.customer_id
WHERE s.order_date >= m.join_date AND MONTH(s.order_date) = 1
GROUP BY s.customer_id, m.join_date


-- Bonus Questions-Join All The Things
SELECT s.customer_id, s.order_date, m.product_name, m.price, 
       CASE WHEN s.order_date >= mb.join_date THEN 'Y'
       ELSE 'N'
       END AS member
FROM sales s
LEFT JOIN menu m
ON s.product_id = m.product_id
LEFT JOIN members mb
ON s.customer_id = mb.customer_id
WHERE s.customer_id IN ('A','B','C')
ORDER BY s.customer_id, s.order_date


--Bonus Questions-Rank All The Things
WITH productrank AS
( SELECT s.customer_id, s.order_date, m.product_name, m.price, 
       CASE WHEN s.order_date >= mb.join_date THEN 'Y'
       ELSE 'N'
       END AS member
  FROM sales s
  LEFT JOIN menu m
  ON s.product_id = m.product_id
  LEFT JOIN members mb
  ON s.customer_id = mb.customer_id
  WHERE s.customer_id IN ('A','B','C')),

productrank1 AS
( SELECT customer_id, order_date, product_name, price, member,
       DENSE_RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) AS rank_num
  FROM productrank )

SELECT customer_id, order_date, product_name, price, member, 
       CASE WHEN member = 'N' THEN NULL
       ELSE rank_num 
       END AS ranking
FROM productrank1
ORDER BY customer_id, order_date;
