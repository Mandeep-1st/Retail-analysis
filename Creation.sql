-- CREATE DATABASE Infra_Limited;
USE Infra_Limited;


-- Creating Customer table
CREATE TABLE customer_data(
	`CustomerID` DECIMAL(38, 0) NOT NULL, 
	`Age` DECIMAL(38, 0) NOT NULL, 
	`Gender` VARCHAR(6) NOT NULL, 
	`Location` VARCHAR(5), 
	`JoinDate` VARCHAR(10) NOT NULL
);

-- Inserting values to the Customer Table
LOAD DATA INFILE 'C:/MySQL/InfraLed Limited Data analysis/customer_profiles_lyst1749925722389.csv'
INTO TABLE customer_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@CustomerID , @Age , @Gender , @Location , @JoinDate)
SET
  CustomerID = NULLIF(@CustomerID, ''),
  Age = NULLIF(@Age, ''),
  Gender = NULLIF(@Gender, ''),
  Location = NULLIF(@Location, ''),
  JoinDate = NULLIF(@JoinDate, '');

-- checking the data
SELECT * FROM customer_data;

-- ===================================================================
-- Creating Product Table 
CREATE TABLE product_data(
	`ProductID` DECIMAL(38, 0) NOT NULL, 
	`ProductName` VARCHAR(11) NOT NULL, 
	`Category` VARCHAR(15) NOT NULL, 
	`StockLevel` DECIMAL(38, 0) NOT NULL, 
	`Price` DECIMAL(38, 2) NOT NULL
);

-- Inserting Values
LOAD DATA INFILE 'C:/MySQL/InfraLed Limited Data analysis/product_inventory_lyst1749925727340.csv'
INTO TABLE product_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@ProductID , @ProductName, @Category, @StockLevel, @Price)
SET
  ProductID = NULLIF(@ProductID, ''),
  ProductName = NULLIF(@ProductName, ''),
  Category = NULLIF(@Category, ''),
  StockLevel = NULLIF(@StockLevel, ''),
  Price = NULLIF(@Price, '');


-- checking data
SELECT * FROM product_data;

-- ===================================================================
-- Creating Sales Table
CREATE TABLE Sales_data (
	`TransactionID` DECIMAL(38, 0) NOT NULL, 
	`CustomerID` DECIMAL(38, 0) NOT NULL, 
	`ProductID` DECIMAL(38, 0) NOT NULL, 
	`QuantityPurchased` DECIMAL(38, 0) NOT NULL, 
	`TransactionDate` VARCHAR(8) NOT NULL, 
	`Price` DECIMAL(38, 2) NOT NULL
);


-- Inserting Values
LOAD DATA INFILE 'C:/MySQL/InfraLed Limited Data analysis/sales_transaction_lyst1749925731351.csv'
INTO TABLE Sales_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@TransactionID,@CustomerID , @ProductID , @QuantityPurchased , @TransactionDate , @Price)
SET
	TransactionID = NULLIF(@TransactionID,''),
  CustomerID = NULLIF(@CustomerID, ''),
  ProductID = NULLIF(@ProductID, ''),
  QuantityPurchased = NULLIF(@QuantityPurchased, ''),
  TransactionDate = NULLIF(@TransactionDate, ''),
  Price = NULLIF(@Price, '');


-- checking data
SELECT * FROM sales_data;


