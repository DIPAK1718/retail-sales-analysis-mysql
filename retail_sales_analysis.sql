CREATE DATABASE retail_sales_db;

USE retail_sales_db;
SHOW DATABASES;


-- create table
CREATE TABLE retail_sales (
    transaction_id INT PRIMARY KEY,
    sale_date DATE,
    sale_time TIME,
    customer_id INT,
    gender VARCHAR(15),
    age INT,
    category VARCHAR(15),
    quantity INT,
    price_per_unit DECIMAL(10,2),
    cogs DECIMAL(10,2),
    total_sale DECIMAL(10,2)
);

DESCRIBE retail_sales;

SELECT *
FROM retail_sales
LIMIT 10;

SELECT COUNT(*) AS total_rows
FROM retail_sales;

SELECT DISTINCT category
FROM retail_sales;

-- Q1 - Retrieve all columns for sales made on 2022-11-05. 
SELECT *
FROM retail_sales
WHERE sale_date = '2022-11-05';

-- Q2 Retrieve all transactions where the category is Clothing, quantity sold is more than 4, and the sale happened in November 2022. 
SELECT *
FROM retail_sales
WHERE category = 'Clothing'
  AND quantity > 4
  AND sale_date >= '2022-11-01'
  AND sale_date < '2022-12-01';
  
-- Q3- Calculate the total sales for each category.   
SELECT
    category,
    SUM(total_sale) AS total_sales,
    COUNT(*) AS total_orders
FROM retail_sales
GROUP BY category;

-- Q4- Find the average age of customers who purchased from the Beauty category.
SELECT
    ROUND(AVG(age), 2) AS average_age
FROM retail_sales
WHERE category = 'Beauty';

-- Q5 Find all transactions where total sale is greater than 1000.
SELECT *
FROM retail_sales
WHERE total_sale > 1000;

-- Q6 Find the total number of transactions made by each gender in each category.
SELECT
    category,
    gender,
    COUNT(*) AS total_transactions
FROM retail_sales
GROUP BY category, gender
ORDER BY category, gender;

-- Q7 Calculate the average sale for each month and find the best-selling month in each year.
SELECT
    YEAR(sale_date) AS year,
    MONTH(sale_date) AS month,
    AVG(total_sale) AS average_sale
FROM retail_sales
GROUP BY YEAR(sale_date), MONTH(sale_date);

WITH monthly_sales AS (
    SELECT
        YEAR(sale_date) AS year,
        MONTH(sale_date) AS month,
        AVG(total_sale) AS average_sale
    FROM retail_sales
    GROUP BY YEAR(sale_date), MONTH(sale_date)
),

ranked_months AS (
    SELECT
        year,
        month,
        average_sale,
        RANK() OVER (
            PARTITION BY year
            ORDER BY average_sale DESC
        ) AS sales_rank
    FROM monthly_sales
)

SELECT
    year,
    month,
    average_sale
FROM ranked_months
WHERE sales_rank = 1
ORDER BY year;

-- Q8 Find the top 5 customers based on highest total sales.
SELECT
    customer_id,
    SUM(total_sale) AS total_sales
FROM retail_sales
GROUP BY customer_id
ORDER BY total_sales DESC
LIMIT 5;

-- Q9 Find the number of unique customers who purchased items from each category.
SELECT
    category,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM retail_sales
GROUP BY category;

-- Q10 Create shifts and find the number of orders in each shift.
SELECT
    CASE
        WHEN HOUR(sale_time) < 12 THEN 'Morning'
        WHEN HOUR(sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS total_orders
FROM retail_sales
GROUP BY shift;

-- Q11 Find categories whose total sales are greater than 500,000.
SELECT
    category,
    SUM(total_sale) AS total_sales
FROM retail_sales
GROUP BY category
HAVING SUM(total_sale) > 500000;

-- Q12 Find customers whose total spending is greater than the average customer's total spending. 
SELECT
    customer_id,
    SUM(total_sale) AS total_spent
FROM retail_sales
GROUP BY customer_id
HAVING SUM(total_sale) > (
    SELECT AVG(customer_total)
    FROM (
        SELECT
            customer_id,
            SUM(total_sale) AS customer_total
        FROM retail_sales
        GROUP BY customer_id
    ) AS customer_sales
)
ORDER BY total_spent DESC;
-- Q13 Find the second-highest total_sale. 
SELECT DISTINCT total_sale
FROM retail_sales
ORDER BY total_sale DESC
LIMIT 1 OFFSET 1;

-- Q14 Rank every transaction based on total_sale, highest sale first. 
SELECT
    transaction_id,
    customer_id,
    total_sale,
    RANK() OVER (
        ORDER BY total_sale DESC
    ) AS sales_rank
FROM retail_sales;

-- Q15 Find the top 3 highest-value transactions in each category. 
WITH ranked_sales AS (
    SELECT
        transaction_id,
        category,
        total_sale,
        RANK() OVER (
            PARTITION BY category
            ORDER BY total_sale DESC
        ) AS sales_rank
    FROM retail_sales
)

SELECT
    transaction_id,
    category,
    total_sale,
    sales_rank
FROM ranked_sales
WHERE sales_rank <= 3
ORDER BY category, sales_rank;

-- Q16 Calculate total sales for every month.
SELECT
    YEAR(sale_date) AS year,
    MONTH(sale_date) AS month,
    SUM(total_sale) AS monthly_sales
FROM retail_sales
GROUP BY
    YEAR(sale_date),
    MONTH(sale_date)
ORDER BY year, month;
 
-- Q17 Calculate monthly sales and compare each month with the previous month.
  WITH monthly_sales AS (
    SELECT
        YEAR(sale_date) AS year,
        MONTH(sale_date) AS month,
        SUM(total_sale) AS total_sales
    FROM retail_sales
    GROUP BY YEAR(sale_date), MONTH(sale_date)
)

SELECT
    year,
    month,
    total_sales,
    LAG(total_sales) OVER (
        ORDER BY year, month
    ) AS previous_month_sales
FROM monthly_sales
ORDER BY year, month;

-- Q18 — Calculate Sales Growth % : Growth % = (Current - Previous) / Previous × 100

WITH monthly_sales AS (
    SELECT
        YEAR(sale_date) AS year,
        MONTH(sale_date) AS month,
        SUM(total_sale) AS total_sales
    FROM retail_sales
    GROUP BY YEAR(sale_date), MONTH(sale_date)
),

sales_with_previous AS (
    SELECT
        year,
        month,
        total_sales,
        LAG(total_sales) OVER (
            ORDER BY year, month
        ) AS previous_month_sales
    FROM monthly_sales
)

SELECT
    year,
    month,
    total_sales,
    previous_month_sales,
    ROUND(
        ((total_sales - previous_month_sales)
        / previous_month_sales) * 100,
        2
    ) AS growth_percentage
FROM sales_with_previous;

-- Q19 Classify customers based on their total spending:
WITH customer_sales AS (
    SELECT
        customer_id,
        SUM(total_sale) AS total_spent
    FROM retail_sales
    GROUP BY customer_id
)

SELECT
    customer_id,
    total_spent,
    CASE
        WHEN total_spent >= 3000 THEN 'High Value'
        WHEN total_spent >= 1500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customer_sales;

-- Q20 Find the category having the highest number of transactions.
SELECT
    category,
    COUNT(*) AS total_orders
FROM retail_sales
GROUP BY category
ORDER BY total_orders DESC
LIMIT 1;