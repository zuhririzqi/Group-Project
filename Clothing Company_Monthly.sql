use clothing_company;

CREATE TABLE monthly_sales
	SELECT * FROM product_sales
	WHERE MONTH(start_txn_time) = 2 AND YEAR (start_txn_time)= 2021;

## Sales Analysis
# 1. What was the total quantity sold for all products?
	SELECT sum(qty) as total FROM monthly_sales;

# 2. What is the total generated revenue for all products before discounts?
	SELECT sum(qty*price) as revenue FROM monthly_sales;

# 3. What was the total discount amount for all products?
	SELECT sum((qty*price*discount)/100) as total_discount FROM monthly_sales;
    
## Transaction Analysis
# 1. How many unique transactions were there?
	SELECT count(distinct(txn_id)) as unique_trans FROM monthly_sales;
    
# 2. What is the average unique products purchased in each transaction?
	SELECT round(count(prod_id)/count(distinct(txn_id)),0) as avg_unique FROM monthly_sales;

#3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
WITH revenue as(SELECT txn_id, 
    sum((qty*price)-((qty*price*discount)/100)) AS rev,
    NTILE(100) OVER(ORDER BY sum((qty*price)-((qty*price*discount)/100))) AS percentile 
    FROM monthly_sales
    GROUP BY txn_id
)
SELECT
    max(rev) as Revenue, percentile
FROM
    revenue
WHERE
    percentile IN (25, 50, 75)
GROUP BY
    percentile;

# 4. What is the average discount value per transaction?
WITH avg_disc as(
    SELECT txn_id, 
    sum((qty*price*discount)/100)as disc
    from monthly_sales
    GROUP BY txn_id)
SELECT round(avg(disc),2) as Avg_Disc
FROM avg_disc;
    
# 5. What is the percentage split of all transactions for members vs non-members?
SELECT member as Member, 
round(count(distinct(txn_id))/(SELECT count(distinct(txn_id)) FROM monthly_sales)*100,2) as Percentage
FROM monthly_sales
GROUP BY member;

# 6. What is the average revenue for member transactions and non-member transactions?
SELECT member as Member, 
avg((qty*price)-(qty*price*discount)/100) as average
FROM monthly_sales
GROUP BY member;

## Product Analysis
# 1. What is the percentage split of total revenue by category?
WITH table_join as(SELECT * FROM monthly_sales s
	LEFT JOIN product_details d
    ON s.prod_id = d.product_id)
SELECT
    category_name as Category,
    round(sum((qty*price)-(qty*price*discount)/100)/
    (SELECT sum((qty*price)-(qty*price*discount)/100) from table_join)*100,2) as Percentage
FROM table_join
GROUP BY category_name;

# 2. What is the total transaction “penetration” for each product? 
WITH tab_prod as(SELECT prod_id, count(distinct(txn_id)) as total_prod 
	    FROM monthly_sales s 
	    LEFT JOIN product_details d
	    ON s.prod_id = d.product_id
	    GROUP BY prod_id),
	total_trans as(SELECT count(distinct(txn_id)) as total_trans 
        FROM monthly_sales)
SELECT prod_id, total_prod/total_trans as penetration 
    FROM tab_prod
	CROSS JOIN total_trans;

# 3. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
SELECT ps1.prod_id AS product_1, ps2.prod_id AS product_2, ps3.prod_id AS product_3, COUNT(*) AS trans_count
	FROM monthly_sales ps1
	JOIN monthly_sales ps2 USING (txn_id)
	JOIN monthly_sales ps3 USING (txn_id)
	WHERE ps1.prod_id != ps2.prod_id AND ps2.prod_id != ps3.prod_id AND ps1.prod_id!= ps3.prod_id
	GROUP BY 1,2,3
	ORDER BY trans_count DESC
	LIMIT 1;


# Drop Table to change month and year
DROP TABLE monthly_sales;
