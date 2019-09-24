DROP TABLE sales_raw;
-- Creates an external table over the csv file
CREATE EXTERNAL TABLE sales_raw(
  QUANT INT,
  REGION STRING,
  STORE STRING,
  SALEDATE STRING,
  DEP STRING,
  ITEM STRING,
  UNITSOLD INT,
  UNITPRICE INT,
  REVENUE INT)
--Format and location of the file
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION 'abfs://files@<ADLS GEN2 STORAGE NAME>.dfs.core.windows.net/transformed';

--Drop table sales if exists
DROP TABLE sales;
--Create sales table and populate with data\
--pulled in from csv file (via external table defined previously)
CREATE TABLE sales AS
SELECT QUANT AS quant,
	REGION AS region,
	STORE as store,
	CAST(SALEDATE as DATE) as saledate, 
	DEP as dep,
	ITEM as item,
	UNITSOLD as unitsold,
	UNITPRICE as unitprice,
	REVENUE as revenue
FROM sales_raw;
