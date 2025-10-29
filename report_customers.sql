/*
===================================================================================================
Customer Report
===================================================================================================

Purpose:
	- This Report consolidates key customer metrics and behavious

Highlights:
	1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
	3. Aggregates customer-level metrics:
		- total orders
		- total sales
		- total quantity purchased 
		- total products
		- lifespan (in months)
	4. Calculates valuable KPIs:
		- recency (months since last order)
		- average order value
		- average monthly spend
==================================================================================================
*/


CREATE VIEW gold.report_customers AS
WITH base_query AS(
/*------------------------------------------------------------------------------------------------
1) Base Query : Retrives core columns from tables
-------------------------------------------------------------------------------------------------*/
select 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
DATEDIFF(year, c.birthdate, GETDATE()) age
From gold.fact_sales f
Left Join gold.dim_customers c
ON c.customer_key = f.customer_key
Where order_date IS NOT NULL
)

, customer_aggregation AS 
(
/*------------------------------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
-------------------------------------------------------------------------------------------------*/
select 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_Sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_prodcuts,
	MAX(order_date ) AS last_order_date,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
from base_query
GROUP BY
	customer_key,
	customer_number,
	customer_name,
	age
)

select 
customer_key,
customer_number,
customer_name,
age,
CASE WHEN age < 20 THEN 'UNDER 20'
	 WHEN age between 20 and 29 THEN '20-29'
	 WHEN age between 30 and 39 THEN '30-39'
	 WHEN age between 40 and 49 THEN '40-49'
	 ELSE '50 and above'
END AS age_group,
CASE WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
	 WHEN lifespan >= 12 AND total_Sales <= 5000 THEN 'Regular'
	 ELSE 'New'
END customer_segment,
last_order_date,
DATEDIFF(month, last_order_date, GETDATE() ) AS reccency,
total_orders,
total_Sales,
total_quantity,
total_prodcuts,
lifespan,
--	Compute average order values(AVO)
CASE WHEN total_orders = 0 THEN 0
	 ELSE total_Sales / total_orders
END AS avg_order_value,

-- Compute average monthly spend 
CASE WHEN lifespan = 0 THEN total_sales
	 ELSE total_sales/lifespan
END AS avg_monthly_spend 
from customer_aggregation
