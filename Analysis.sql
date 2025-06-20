
USE infra_limited;




-- DATA CLEANING
-- Removing Discrepancies in product prices between sales_data and product_data

SELECT product_data.ProductID,product_data.Price as product_price,Temp.Price as sales_price 
FROM product_data
JOIN
(SELECT ProductID, Price FROM sales_data) as Temp
ON Temp.ProductID = product_data.ProductID
WHERE product_data.Price != Temp.Price;

-- from the upper query we come to know that product_id 51 in sales table have wrong input for price.
-- So I used case Statement there.
UPDATE sales_data s
JOIN product_data p 
ON s.ProductID = p.ProductID
SET s.Price =
	CASE
		WHEN s.Price != p.Price THEN p.Price
        ELSE s.Price
	END;
-- Now Every price discrepancy is gone.

-- Part 2 :- Handling Null Values.
SELECT *
FROM sales_data
WHERE TransactionID IS NULL
OR CustomerID IS NULL
OR ProductID IS NULL
OR QuantityPurchased IS NULL
OR TransactionDate IS NULL 
OR Price IS NULL;

-- Sales_data have no null values. 
-- =================================================================
SELECT *
FROM product_data
WHERE ProductID IS NULL
OR ProductName IS NULL
OR Category IS NULL
OR StockLevel IS NULL
OR Price IS NULL;

-- Hence Product_data have no null values.
-- ===================================================================
SELECT * FROM customer_data
WHERE CustomerID IS NULL
OR Age IS NULL
OR Gender IS NULL
OR Location IS NULL
OR JoinDate IS NULL;

-- Got the null Locations for some users.
ALTER TABLE customer_data
ADD COLUMN cleaned_location VARCHAR(255);

UPDATE customer_data
SET cleaned_location = COALESCE(location, 'Not Mentioned');


-- =======================================
-- EDA (Exploratory Data Anaylysis)
-- 1. Basic Product Performance Overview
-- here by , iam finding total number of Units sold per Product , total revenue per product , and the top performer(with greatest sale).
WITH product_analysis AS 
(SELECT ProductID , SUM(QuantityPurchased) AS total_no_of_units_sold,
SUM(Price * QuantityPurchased) AS total_revenue_per_product
FROM sales_data
GROUP BY ProductID
)SELECT * FROM product_analysis ORDER BY total_revenue_per_product DESC;


-- 2. Customer Purchase Frequency
-- here , Iam finding No of Orders per customer , Total amount spent per customer and Avg order value for each customer , also customer with most no of orders
WITH customer_analysis AS (
SELECT CustomerID , COUNT(TransactionID) AS no_of_orders,
SUM(Price * QuantityPurchased) AS total_spent_by_each_cust
FROM sales_data
GROUP BY CustomerID
)SELECT * , (total_spent_by_each_cust / no_of_orders) AS avg_spent_by_cust
FROM customer_analysis
ORDER BY no_of_orders DESC;


-- 3. Product Category Performance Evaluation.
-- Here i found total revenue by each category and number of product sold for each category.
WITH category_based_data AS (
	SELECT sd.*,pd.Category,pd.StockLevel FROM sales_data AS sd
	JOIN (
		SELECT ProductID , Category , StockLevel FROM product_data
	)AS pd
	ON sd.ProductID = pd.ProductID
) SELECT Category , SUM(price * QuantityPurchased) AS total_revenue_by_each_category,
  SUM(QuantityPurchased) AS no_of_product_sold_per_category
  FROM category_based_data
  GROUP BY Category;
  
-- ===============================================================================================

-- DETAILED ANALYSIS
-- 1. High or Low Sales Products :- Total Quantity Sold per Product , Total revenue generated per product 
-- adding a new column performance (which depend on how much a product get sold).

WITH product_analysis AS 
(SELECT ProductID , SUM(QuantityPurchased) AS total_no_of_units_sold,
SUM(Price * QuantityPurchased) AS total_revenue_per_product
FROM 
(	SELECT sd.* FROM sales_data AS sd
	RIGHT JOIN (
		SELECT ProductID FROM product_data
	)AS pd
	ON sd.ProductID = pd.ProductID
) AS Product_info
GROUP BY ProductID
)SELECT 
  *,
  CASE 
    WHEN total_no_of_units_sold > 90 THEN 'Very High'
    WHEN total_no_of_units_sold > 70 THEN 'High'
    WHEN total_no_of_units_sold > 50 THEN "Average"
    WHEN total_no_of_units_sold = 0 THEN "Should be Discarded"
    ELSE "LOW"
  END AS performance_tag
FROM product_analysis;

-- Now what i did here is I tooked Sales Data and Product Data then combined both data with right join because 
-- i need all product info rather they have been ordered or not,
-- Now I am Summing up the units sold for each product and then giving them a performance tag according to it.
-- Reason behind taking Right join :- if any product in Product table is never ordered then we can discontinue it.

-- ======================================================================================================================

-- Sales Trends & M-o-M (Month-over-Month) Growth
WITH MoM_sales_agg_data as (
SELECT COUNT(*) as DistinctOrdersMoM,
EXTRACT(MONTH FROM TransactionDate) as Months,
SUM(QuantityPurchased) as Total_Quantity_Sold_each_month ,
LAG(Sum(QuantityPurchased)) OVER (ORDER BY EXTRACT(MONTH FROM TransactionDate)) as Previous_month_Sales,
SUM(Price) as Total_revenue_each_month,
LAG(Sum(Price)) OVER (ORDER BY EXTRACT(MONTH FROM TransactionDate)) as Previous_month_revenue
FROM sales_data
GROUP BY Months
)SELECT *,
((total_Quantity_Sold_each_month - Previous_month_sales) / (Previous_month_sales) * 100) as MoM_precent_change_in_sales,
((total_revenue_each_month - Previous_month_revenue)/ (Previous_month_revenue) * 100) as MoM_percent_change_in_revenue
FROM MoM_sales_agg_data;

-- Now here I calculated total revenue for each month , total sales for each month , 
-- then stored_previous month sales and revenue in seperate columns
-- then created two columns percent_change in sales , percent change in revenue. in months to show Growth in both aspects




-- =============================================================================
-- 2. Customer Segmentation
	-- 1. Customer Segmentation (by purchase and spent)

WITH cust_segment_analysis AS (
SELECT CustomerID , SUM(QuantityPurchased) As total_purchase_by_cust,
SUM(Price) As total_spent_by_cust
FROM sales_data
GROUP BY CustomerID
)SELECT * ,
 CASE 
    WHEN total_purchase_by_cust >= 35 THEN 'Volume Buyer'
    WHEN total_purchase_by_cust > 10 THEN 'Average Buyer'
    ELSE "Ocassional Buyer"
END AS purchasing_tag,
CASE 
    WHEN total_spent_by_cust > 800 THEN 'High'
    WHEN total_spent_by_cust > 500 THEN 'Average'
    ELSE "LOW"
END AS spending_tag
FROM cust_segment_analysis;

-- spent :- 800 as high , 500 as mid , below as low
-- Quantity :- 30 as volume buyer and above 10 as good buyers , and occasional ones.

-- ======================================================================================
	-- 2.  Identify Loyal Customers (Using Duration Between Purchases)
    
-- +++++++++++++++++++++++++++++++++++++++++++++++++
-- WITH loyal_cust_table AS(
-- 	WITH curr_data AS (
-- 		SELECT CustomerID,TransactionDate,
-- 		LAG(TransactionDate) OVER(PARTITION BY CustomerID ORDER BY TransactionDate) As LastPurchaseOn
-- 		FROM sales_data
-- 	)SELECT * , DATEDIFF(TransactionDate, LastPurchaseOn) AS DaysBetween FROM curr_data
-- )SELECT CustomerID , AVG(DaysBetween) As Avg_order_gap
-- FROM loyal_cust_table
-- GROUP BY CustomerID

-- This code raised error  , because our date is in string format so it broke whole logic.
-- ++++++++++++++++++++++++++++++++++++++++++++++++++


WITH cust_avg_data AS (
	WITH total_info_table AS(
		WITH curr_data AS (
			SELECT CustomerID,TransactionDate,STR_TO_DATE(TransactionDate,'%d/%m/%y') As Real_date,
			LAG(STR_TO_DATE(TransactionDate,'%d/%m/%y')) OVER(PARTITION BY CustomerID ORDER BY STR_TO_DATE(TransactionDate,'%d/%m/%y')) As LastPurchaseOn
			FROM sales_data
		)SELECT * , DATEDIFF(Real_date, LastPurchaseOn) AS DaysBetween FROM curr_data
	)SELECT CustomerID , AVG(DaysBetween) As Avg_order_gap
	FROM total_info_table
	GROUP BY CustomerID
)SELECT CustomerID , Avg_order_gap,
CASE 
	WHEN Avg_order_gap < 28 THEN "Loyal"
    WHEN Avg_order_gap < 150 THEN "Moderate"
    ELSE "InActive"
END AS customer_loyalty
FROM cust_avg_data;    

-- Finally , Average Order gap is less than a month -> Loyal , less than 150days -> Moderate 
-- More than 150 or Null (means ordered once ) -> InActive.
    
-- ==========================================================================================
-- 3. Customer Behaviour Analysis
WITH ranked_categories AS (
	WITH data_with_category_count AS(
		WITH buying_data_with_category AS (
			WITH buying_gap_data AS (
				WITH curr_data AS (
					SELECT CustomerID,ProductID,TransactionDate,STR_TO_DATE(TransactionDate,'%d/%m/%y') As Real_date, 
					LAG(STR_TO_DATE(TransactionDate,'%d/%m/%y')) OVER(PARTITION BY CustomerID ORDER BY STR_TO_DATE(TransactionDate,'%d/%m/%y')) As LastPurchaseOn
					FROM sales_data
				)SELECT * , DATEDIFF(Real_date, LastPurchaseOn) AS DaysBetween FROM curr_data
			)SELECT  bg.CustomerID,bg.ProductID,pd.Category,bg.Real_date,bg.LastPurchaseOn , bg.DaysBetween  
			FROM buying_gap_data As bg
			LEFT JOIN product_data AS pd ON bg.ProductID = pd.ProductID
			-- Here I did Left join because we have the required data we just need to attach a Category column.
		)SELECT 
				CustomerID,
				Category,
				COUNT(*) AS CategoryCount
		FROM buying_data_with_category
		GROUP BY CustomerID,Category
	) SELECT *,
			RANK() OVER (PARTITION BY CustomerID ORDER BY CategoryCount DESC) AS rk
	FROM data_with_category_count
)SELECT CustomerID, Category AS Most_Purchased_Category
FROM ranked_categories
WHERE rk = 1;

-- Here , this query is quite long , so ellaborating steps by steps :
-- 1. curr_date :- i tooked this from previous analysis it already have data of each user's each transaction with product_ID
-- 2. buying_gap_data :- In this level i am adding category column respective to the productID.
-- 3. buying_data_with_category :- from here this data iam arraning the data by grouping all  the similar categories.
-- 4. data_with_category_count :- Creating a new column which have rank all the categories by their appearance count.
-- 5. ranked_categories :- Now from rank categories iam retriving the customerID and the top rank category 
-- Now with this analysis I got to know  that what  each Customer buying most.