/* Group Customers into thee segments based on their spedning behavious:
 -- VIP : Customers with at least 12 Months of history and spending more then $5000.
 -- Regular : Cutomers with at leasr 12 months of history but soending $5,000 or less...
 -- New : Customers with a lifespan less than 12 months.
AND find the total number of cutsomers by each group */


WITH customer_spedning AS
(
SELECT 
c.customer_key,
SUM(f.sales_amount) AS total_spend,
MIN(order_date) as First_Order,
MAX(order_date) as Last_order,
DATEDIFF (month, MIN(order_date), MAX(order_date)) AS Lifespan
FROM gold.fact_sales f
left join gold.dim_customers c
on f.customer_key = c.customer_key
Group BY c.customer_key
)

select 
customer_Segment,
COUNT(customer_key) AS total_customers
from(
	select 
	customer_key,
	CASE WHEN Lifespan >=  12 AND total_spend > 5000 THEN 'VIP'
	 WHEN Lifespan >=  12 AND total_spend <= 5000 THEN 'Regular'
	 ELSE 'New'
	 END customer_segment
	 from customer_spedning) t
Group By customer_segment
Order By total_customers DESC