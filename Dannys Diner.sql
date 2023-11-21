use dannys_diner;

#################### All Tables ####################
select * from sales;
select * from menu;
select * from members;

# What is the total amount each customer spent at the restaurant?
select 
  s.customer_id, 
  sum(mn.price) as total_amount 
from 
  sales s 
  join menu mn using(product_id) 
group by 
  s.customer_id;

# How many days has each customer visited the restaurant?
select 
  customer_id, 
  count(distinct order_date) as visited_restaurant 
from 
  sales 
group by 
  customer_id;

# What was the first item from the menu purchased by each customer?
with cte as (
  select 
    s.customer_id, 
    mn.product_name, 
    s.order_date, 
    dense_rank() over(
      partition by s.customer_id 
      order by 
        s.order_date
    ) as first_purchase 
  from 
    sales s 
    join menu mn using(product_id)
) 
select 
  customer_id, 
  product_name 
from 
  cte 
where 
  first_purchase = 1 
group by 
  customer_id, 
  product_name;

# What is the most purchased item on the menu and how many times was it purchased by all customers?
with cte as (
  select 
    product_id, 
    product_name, 
    count(product_id) as most_purchase, 
    dense_rank() over(
      order by 
        count(product_id) desc
    ) as rn 
  from 
    sales s 
    join menu mn using(product_id) 
  group by 
    1, 
    2
) 
select 
  product_name, 
  most_purchase 
from 
  cte 
where 
  rn = 1;

# Which item was the most popular for each customer
with cte as (
  select 
    customer_id, 
    product_name, 
    count(product_id) as counts, 
    dense_rank() over(
      partition by customer_id 
      order by 
        count(product_id) desc
    ) as rn 
  from 
    sales s 
    join menu mn using (product_id) 
  group by 
    1, 
    2
) 
select 
  customer_id, 
  product_name 
from 
  cte 
where 
  rn = 1;

# Which item was purchased first by the customer after they became a member?
with cte as (
  select 
    s.customer_id, 
    mn.product_name as first_purchase, 
    s.order_date, 
    m.join_date, 
    dense_rank() over(
      partition by s.customer_id 
      order by 
        s.order_date
    ) as rn 
  from 
    sales s 
    join menu mn on s.product_id = mn.product_id 
    join members m on s.customer_id = m.customer_id 
  where 
    s.order_date >= m.join_date
) 
select 
  customer_id, 
  first_purchase 
from 
  cte 
where 
  rn = 1;

# Which item was purchased just before the customer became a member?
with cte as (
  select 
    s.customer_id, 
    mn.product_name, 
    s.order_date, 
    m.join_date, 
    dense_rank() over(
      partition by s.customer_id 
      order by 
        s.order_date desc
    ) as rn 
  from 
    sales s 
    join menu mn on s.product_id = mn.product_id 
    join members m on s.customer_id = m.customer_id 
  where 
    s.order_date < m.join_date
) 
select 
  customer_id, 
  product_name 
from 
  cte 
where 
  rn = 1;

# What is the total items and amount spent for each member before they became a member?
select 
  s.customer_id, 
  count(distinct s.product_id) as total_items, 
  sum(mn.price) as spent_amount 
from 
  sales s 
  join menu mn on s.product_id = mn.product_id 
  join members m on s.customer_id = m.customer_id 
where 
  s.order_date < m.join_date 
group by 
  s.customer_id;

# If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select 
  s.customer_id, 
  sum(
    case when mn.product_name = 'sushi' then mn.price * 20 else mn.price * 10 end
  ) as points 
from 
  sales s 
  join menu mn on s.product_id = mn.product_id 
group by 
  s.customer_id;

/*
In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
not just sushi - how many points do customer A and B have at the end of January?
*/
with cte as (
  select 
    s.customer_id, 
    mn.price, 
    s.order_date, 
    m.join_date, 
    mn.product_name, 
    date_add(m.join_date, interval 6 day) as first_week 
  from 
    sales s 
    join menu mn on s.product_id = mn.product_id 
    join members m on m.customer_id = s.customer_id 
  where 
    extract(
      month 
      from 
        s.order_date
    ) = 1
) 
select 
  customer_id, 
  sum(
    case when order_date between join_date 
    and first_week then price * 10 * 2 when (
      order_date not between join_date 
      and first_week
    ) 
    and product_name = 'sushi' then price * 10 * 2 else price * 10 end
  ) as points 
from 
  cte 
group by 
  customer_id 
order by 
  customer_id;

# Create a SQL Views named order_member_status for the Bonus Question 01
SELECT 
  s.customer_id, 
  s.order_date, 
  mn.product_name, 
  mn.price, 
  CASE WHEN m.join_date <= s.order_date THEN 'Y' ELSE 'N' END AS Members 
FROM 
  sales s 
  LEFT JOIN members m ON s.customer_id = m.customer_id 
  JOIN menu mn ON mn.product_id = s.product_id;

# Now call from created Views for the Bonus Question 02
select 
  *, 
  (
    case when Members = 'N' then null else dense_rank() over(
      partition by customer_id, 
      Members 
      order by 
        order_date
    ) end
  ) as rankings 
from 
  order_member_status;






























