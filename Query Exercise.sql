/* Sample query exercises */

/* Q1. Find the date and products with that day's quantity sold higher than the average quantity sold by all products in January */
WITH avgSale as (
	SELECT ROUND(AVG(quantity_sold), 2) AS jan_avg_sale
  	FROM sales
 	WHERE EXTRACT(MONTH FROM sale_date) = 1
)
SELECT *
    , (SELECT jan_avg_sale FROM avgSale)
FROM sales
WHERE quantity_sold > (SELECT jan_avg_sale FROM avgSale);

/* Q2. Calculate the total quantity sold for each product, including a cumulative total for each product id */
SELECT 
    product_id
  , sale_date
  , quantity_sold
  , SUM(quantity_sold) OVER (PARTITION BY product_id ORDER BY sale_date) 
	AS cumulative_total
FROM sales;

/* Q3. Find the date where today's quantity sold is higher than yesterday quantity sold for each product */
SELECT 
    s1.product_id
	, s1.sale_date AS yesterday
	, s1.quantity_sold AS yesterday_quantity
    , s2.sale_date AS today
    , s2.quantity_sold AS today_quantity
FROM sales s1
JOIN sales s2 ON s1.product_id = s2.product_id
	AND s1.sale_date = s2.sale_date - INTERVAL '1 day'
	AND s1.quantity_sold < s2.quantity_sold;

/* Q4. Write a query to find the top 3 distinct products with the highest total quantity sold in any consecutive 
three-day period in January. Include the product names and the total quantity sold. */

--List the previous and 2 previous days from today's date, and the total quantity sold
WITH non_consecutive_3days AS ( 
    SELECT
        product_id
        , sale_date
  		, quantity_sold
        , LAG(sale_date, 1) OVER (PARTITION BY product_id ORDER BY sale_date) AS prev_date
        , LAG(sale_date, 2) OVER (PARTITION BY product_id ORDER BY sale_date) AS prev_2_days
        , quantity_sold
            + LAG(quantity_sold, 1) OVER (PARTITION BY product_id ORDER BY sale_date)
            + LAG(quantity_sold, 2) OVER (PARTITION BY product_id ORDER BY sale_date) AS total
    FROM sales
    WHERE EXTRACT(MONTH FROM sale_date) = 1
), 
-- Filter the date as 3 consecutive days
    consecutive_3days AS (
	SELECT 
        product_id
        , sale_date AS last_day_of_3_consecutive_days
        , total 
    FROM non_consecutive_3days
	WHERE prev_date = sale_date - INTERVAL '1 day'
	    AND prev_2_days = sale_date - INTERVAL '2 days'
)                 
-- Find product IDs with the highest total quantity sold
SELECT * 
FROM consecutive_3days
WHERE (product_id, total) IN (
    SELECT product_id, MAX(total) FROM consecutive_3days GROUP BY product_id
    )
ORDER BY total DESC
LIMIT 3;
