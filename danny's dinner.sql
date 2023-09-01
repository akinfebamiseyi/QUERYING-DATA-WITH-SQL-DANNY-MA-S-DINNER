CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  select * from members
  select * from menu
  select * from sales
  
  /* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant
select customer_id, sum(price)as total_amount  from sales
left join menu
on sales.product_id = menu.product_id
group by customer_id
order by sum(price)desc

-- 2. How many days has each customer visited the restaurant
select customer_id, count(order_date)as num_of_times_visited
from
	(select order_date, customer_id, count(order_date) as num_times_visited
	from sales
	group by customer_id, order_date
	order by count(order_date)desc) date
	group by customer_id
	order by 2 desc



--3. What was the first item from the menu purchased by each customer?
select distinct customer_id, min(order_date), product_name
from 
	(select s.customer_id, min(s.order_date) as order_date, product_name,
	 RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date) as rank
	from sales s
	left join menu m
	on s.product_id = m.product_id
	 group by s.customer_id, product_name, s.order_date
	order by s.order_date
	)sales
	where rank = 1
	group by  customer_id, product_name
	order by min(order_date) 


--4.What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_name, count(sales.product_id) as No_of_time_purchased
from menu
join sales
on menu.product_id = sales.product_id
group by product_name
order by count(sales.product_id) desc
limit 1

--5.Which item was the most popular for each customer?

select customer_id, product_name,product_count
from 
	(select s.customer_id, m.product_name, count(m.product_name)as product_count,
	 RANK() OVER(PARTITION BY s.customer_id ORDER BY product_name) as rank
	 from sales s
	 join menu m
	 on s.product_id = m.product_id
	 group by s.customer_id, m.product_name
	 order by count(m.product_name)desc)order_count
	 where rank = 1
	 group by customer_id, product_name, product_count
	 order by product_count desc

--6. Which item was purchased first by the customer after they became a member?
select customer_id, product_name
from 
	(select s.customer_id, s.order_date, m.product_name, me.join_date,
	Rank()over (partition by s.customer_id order by s.order_date) as rank
	from sales s
	left join menu m
	on s.product_id = m.product_id
	left join members me
	on s.customer_id = me.customer_id
	where 
	s.order_date > me.join_date) join_date
	where rank = 1

-- 7.Which item was purchased just before the customer became a member?
select customer_id, product_name
from 
	(select s.customer_id, s.order_date, m.product_name, me.join_date,
	Rank()over (partition by s.customer_id order by s.order_date) as rank
	from sales s
	left join menu m
	on s.product_id = m.product_id
	left join members me
	on s.customer_id = me.customer_id
	where 
	s.order_date < me.join_date) join_date
	where rank = 1
	
--8. What is the total items and amount spent for each member before they became a member?
	select distinct s.customer_id, m.product_name,s.order_date,count(s.product_id), sum(m.price),me.join_date
	from sales s
	left join menu m
	on s.product_id = m.product_id
	left join members me
	on s.customer_id = me.customer_id
	where s.order_date < me.join_date
	group by 1,2,3,me.join_date
	order by 1
	
--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id, sum(points)as total_point
from
(SELECT s.customer_id, m.product_name, COUNT(s.product_id), SUM(m.price) as total_spent,
	CASE WHEN m.product_name= 'sushi' THEN 2 * 10 * SUM(m.price)
		 ELSE 10 * SUM(m.price) end as points
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
	LEFT JOIN dannys_diner.members mb
	ON s.customer_id = mb.customer_id
	GROUP BY 1,2) point
	group by 1
	order by 1
	
--10.In the first week after a customer joins the program (including their join date), they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? 
With CTE AS (
	SELECT s.customer_id, m.product_name,s.order_date, mb.join_date, 
	COUNT(s.product_id), SUM(m.price) AS total_spent,
	CASE WHEN s.order_date BETWEEN mb.join_date - 1 AND mb.join_date + 7
		 OR m.product_name= 'sushi' THEN 2 * 10 * SUM(m.price)
		 ELSE 10 * SUM(m.price) END AS points
	FROM dannys_diner.sales s
	LEFT JOIN dannys_diner.menu m
	ON s.product_id = m.product_id
	LEFT JOIN dannys_diner.members mb
	ON s.customer_id = mb.customer_id
	GROUP BY 1,2,3,4
	) 
SELECT customer_id, SUM(points) as total_points
FROM CTE
GROUP BY 1
ORDER BY 1



	
	
	
	