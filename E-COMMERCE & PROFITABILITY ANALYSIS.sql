--- PROJECT 1 : E-commerce Sales & Profitability Analysis
--- BARUWA AZEEZ PORTFOLIO PROJECT.

 
--- CREATING A SCHEMA FOR THE RAW DATA 
 CREATE SCHEMA RAW_DATA;

---CREATING THE RAW TABLE

  CREATE TABLE raw_data.online_retail(
  InvoiceNo  VARCHAR(20),
  StockCode VARCHAR(20),
  Description TEXT,
  Quantity INTEGER,
  InvoiceDate TIMESTAMP,
  UnitPrice NUMERIC (10,2),
  CustomerID VARCHAR (20),
  Country VARCHAR(100)
  );


---DATA PROFILING

--- 1) CONFIRMING THE IMPORTATION BY THE TOTAL ROW NUMBER
  SELECT count(*) as TOTAL_ROW
  FROM raw_data.online_retail;
---ANSWER: NUMBER OF ROWS = 541,909

---2) CONFIRMING THE COLUMNS
   SELECT * FROM raw_data.online_retail
   LIMIT 10;
 ---ANSWER: total_rows, invoiceno, stockcode, description, quantity,
 ---invoicedate, unitprice, customerid, country

---3) CHECKING MISSING VALUES
    SELECT COUNT(*) AS total_rows,
	COUNT (invoiceno) AS invoice_no_present,
	COUNT (stockcode) AS stock_code_present,
	COUNT (description) AS description_present,
	COUNT (quantity) AS quantity_present,
	COUNT (invoicedate) AS invoice_date_present,
	COUNT (unitprice) AS unit_price_present,
	COUNT (customerid) AS customer_id_present,
	COUNT (country) AS country_present
  FROM raw_data.online_retail;
--ANSWER:
---TOTAL NUMBER OF ROWS IS 541,909
---SO,  1454 records have missing Description
 --135,080 records have missing Customerid

---4) HOW MANY RECORDS HAVE NEGATIVE QUANTITIES
      SELECT count(*) as TOTAL_ROW
      FROM raw_data.online_retail
      WHERE quantity < 0;
---ANSWER: 10,624

---5) CHECKING UNITPRICE WHERE PRICE IS ZERO OR NEGATIVE
       SELECT count(*) as TOTAL_ROW
      FROM raw_data.online_retail
      WHERE unitprice <= 0;
---ANSWER: 2,521

---6) INSPECT THE ZERO/NEGATIVE-PRICE RECORDS    
	SELECT * 
      FROM raw_data.online_retail
      WHERE unitprice <= 0
	  LIMIT 20;

---7) FIND THE DISTINCT INVOICENO VALUE FOR RECORDS WHERE UNITPRICE <=0
        SELECT DISTINCT invoiceno
      FROM raw_data.online_retail
      WHERE unitprice <= 0;

---8) INVESTIGATING THE NEGATIVE QUANTITIES
    SELECT invoiceno,quantity,unitprice,description
	  FROM raw_data.online_retail
	  WHERE quantity < 0
--- ANSWER: IT IS DISCOVERED THAT THE INVOICENO STARTS WITH 'C'
---WHICH INDICATE CANCELLATION
--- C536379, C536383, C536391


---9 CONFIRMING HOW MANY CANCELLATION WE HAVE
     SELECT COUNT(invoiceno)
	  FROM raw_data.online_retail
	  WHERE invoiceno LIKE 'C%';
---ANSWER: 9,288 RECORDS HAVE INVOICE NUMBER BEGINING
---WITH 'C' I.E 9,288 CANCELLATION INVOICE
--- 541,909 TOTAL RECORDS, 10,624 RECORDS
---WITH NEGATIVE QUANTITY, 2,521 RECORDS WITH UNITPRICE <=0
--- NOTICE THAT 10,624 NEGATIVE-QUANTITY RECORDS != 9,288 CANCELLATION RECORDS.
---THAT MEANS NOT EVERY NEGATIVE QUANTITY NECESSARILY 
---HAS AN INVOICE BEGINNING WITH 'C'. WE SHOULD NOT SIMPLY SAY
---"NEGATIVE QUANTITY = CANCELLATION".

---10) FIND THE DIFFERENCE
---(IDENTIFYING NEGATIVE-QUANTITY RECORDS WHOSE INVOICE DOESN'T START WITH 'C')
     SELECT COUNT(*)
	 FROM  raw_data.online_retail
	 WHERE quantity < 0
	 AND invoiceno NOT LIKE 'C%';
---ANSWER 1,336

---11) HOW MANY NEGATIVE-QUANTITY RECORDS ARE ASSOCIATED WITH C INVOICES
---VERSUS NON-C INVOICES

SELECT 
   CASE 
      WHEN invoiceno LIKE 'C%' THEN 'CANCELLATION'
	  ELSE 'NOT CANCELLATION'
	END AS TRANSACTION,
	COUNT(*) AS record_count
FROM raw_data.online_retail
WHERE quantity < 0
GROUP BY
      CASE
	   WHEN invoiceno LIKE 'C%' THEN 'CANCELLATION'
	   ELSE 'NOT CANCELLATION'
END;
---ANSWER CANCELLATION 9,288
--- NOT CANCELLATION 1,336

---12) INVESTIGATING WHETHER THE RAW DATASET CONTAINS DUPLICATE ROWS
    SELECT invoiceno,
	stockcode, quantity, 
	invoicedate, unitprice, COUNT(*) AS DUPLICATE_COUNT
	FROM raw_data.online_retail
	GROUP BY invoiceno,
	stockcode, quantity, 
	invoicedate, unitprice
	HAVING COUNT (*) > 1
	ORDER BY  DUPLICATE_COUNT DESC;

----COUNTING THE DUPLICATE GROUPS
   SELECT COUNT(*) AS DUPLICATE_GROUPS
   FROM (SELECT invoiceno,
	stockcode, quantity, 
	invoicedate, unitprice
	FROM raw_data.online_retail
	GROUP BY invoiceno,
	stockcode, quantity, 
	invoicedate, unitprice
	HAVING COUNT (*) > 1
	) AS DUPLICATE;
---ANSWER 4,881 REPEATED TRANSACTIONS GROUPS
    
--- INSPECTING THE DUPLICATE WITH '555524' AS EXAMPLE
   SELECT *
   FROM raw_data.online_retail
   WHERE invoiceno = '555524'
   ORDER BY stockcode;


---FINDING EXACT DUPLICATE ROWS
  SELECT invoiceno,
	stockcode, description, customerid, country, quantity, 
	invoicedate, unitprice, COUNT(*) AS DUPLICATE_COUNT
	FROM raw_data.online_retail
	GROUP BY invoiceno,
	stockcode, description, customerid, country, quantity, 
	invoicedate, unitprice
	HAVING COUNT (*) > 1
	ORDER BY  DUPLICATE_COUNT DESC;

---COUNTING THE EXACT DUPLICATE GROUPS
   SELECT COUNT (*) AS EXACT_DUPLICATE_GROUPS
   FROM (SELECT invoiceno,
	stockcode, description, customerid, country, quantity, 
	invoicedate, unitprice
	FROM raw_data.online_retail
	GROUP BY invoiceno,
	stockcode, description, customerid, country, quantity, 
	invoicedate, unitprice
	HAVING COUNT (*) > 1)
	AS DUPLICATE;
---ANSWER 4,879

---HOW MANY DUPLICATE ROWS ARE INVOLVED
   SELECT SUM(duplicate_count -1) AS duplicate_raw_to_remove
   from(select invoiceno,
	stockcode, description, customerid, country, quantity, 
	invoicedate, unitprice,
	COUNT (*) AS duplicate_count
	FROM raw_data.online_retail
	GROUP BY invoiceno,
	stockcode, description, customerid, country, quantity, 
	invoicedate, unitprice
	HAVING COUNT (*) > 1) AS duplicate;
---5,268

---CHECKING DATE RANGE
  SELECT 
       MIN(invoicedate) AS earliest_date,
	   MAX(invoicedate) AS latest_date
	   FROM raw_data.online_retail;
---EARLIEST DATE 2010-12-01 08:26:00
---LATEST DATE 2011-12-09  12:50:00

---CREATING CLEANING SCHEMA
    CREATE SCHEMA IF NOT EXISTS clean_data;


---CREATING THE CLEANED TABLE
    CREATE TABLE clean_data.online_retail AS SELECT
	        TRIM(invoiceno) AS invoice_no, TRIM(stockcode) AS stock_code,
			NULLIF(TRIM(description),'') AS description, quantity AS quantity,
			invoicedate AS invoice_date, unitprice AS unit_price,
			NULLIF(TRIM(customerid),'') AS customer_id, TRIM(country) AS country
			FROM raw_data.online_retail;

---COMPARING BOTH THE BELOW QUARIES
     SELECT (SELECT COUNT(*) FROM clean_data.online_retail) AS raw_total_rows;

	 select count(*) from raw_data.online_retail;
---BOTH ARE 541,909

---CHECKING MISSING VALUES
    SELECT
	COUNT (*) AS total_rows,

	COUNT (*) FILTER (
    WHERE description IS NULL)
	AS missing_desciption,

	COUNT (*) FILTER(
    WHERE customer_id IS NULL)
	AS missing_customer_id,

	COUNT (*) FILTER(
    WHERE invoice_no IS NULL)
	AS missing_invoice_no,

	COUNT (*) FILTER(
    WHERE stock_code IS NULL)
	AS missing_stock_code,

	COUNT (*) FILTER(
    WHERE country IS NULL)
	AS missing_country

	FROM clean_data.online_retail;
---ANSWER: TOTAL ROW 541,909
---        MISSING DESCRIPTION 1454
---        MISSING CUSTOMER_ID 135080
---        OTHERS ARE ZERO

----CHECKING TEXT AND UNNECESSARY SPACES
    SELECT
	    COUNT(*) FILTER(
        WHERE description IS NOT NULL
		   AND TRIM(description) = ''
		   )AS blank_descriptions,

		    COUNT(*) FILTER(
        WHERE country IS NOT NULL
		   AND TRIM(country) = ''
		  )AS blank_countries,

		    COUNT(*) FILTER(
        WHERE customer_id IS NOT NULL
		   AND TRIM(customer_id) = ''
		   )AS blank_customer_ids

		   FROM clean_data.online_retail;
--- ALL ZERO


---INSPECTING THE MOST REPEATED RECORDS
    SELECT invoice_no, stock_code, description,
	 quantity, invoice_date, unit_price,customer_id,
	 country, COUNT (*) AS OCCURRENCES
	 FROM clean_data.online_retail
	 GROUP BY invoice_no, stock_code, description,
	 quantity, invoice_date, unit_price,customer_id,
	 country
	 HAVING COUNT (*)>1
	  ORDER BY OCCURRENCES DESC
	  LIMIT 10;
---THE MOST REPEATED IS 555524 OCCURRED 20 TIMES
   
--- CALCULATING POTENTIAL DUPLICATE ROWS
    SELECT SUM (occurrences-1) AS potential_duplicate_rows
	FROM (SELECT COUNT(*) AS OCCURRENCES 
	FROM clean_data.online_retail
	GROUP BY invoice_no, stock_code,description,quantity,invoice_date,unit_price,customer_id,country
	HAVING COUNT (*)>1) AS duplicate_groups;
---ANSWER   5268	
	

--- INVESTIGATING ZERO AND NEGATIVE PRICES
     SELECT CASE WHEN unit_price =0 THEN 'ZERO price'
	 WHEN unit_price < 0 THEN 'Negative price'
	 ELSE 'positive price' END AS price_category,
	 COUNT(*)AS total_records FROM clean_data.online_retail
	 GROUP BY 1 order by total_records DESC;

---INVESTIGATING THE TWO NEGATIVE-PRICE RECORDS
    SELECT * FROM clean_data.online_retail
	WHERE unit_price < 0;


--- INSPECTING ZERO-PRICE TRANSACTION
   SELECT 
      invoice_no,
	  stock_code,
	  description, quantity,unit_price,
	  customer_id, country
	FROM clean_data.online_retail
	WHERE unit_price = 0
	LIMIT 20;

---
  SELECT 
       COUNT (*) AS total_zero_price,
	   COUNT (description) AS with_description,
	   COUNT (customer_id) AS with_customer_id,
	   COUNT (DISTINCT stock_code) AS different_stock_codes,
	   COUNT (DISTINCT invoice_no) AS different_invoice
	  FROM  clean_data.online_retail
	  WHERE unit_price = 0;

---
  SELECT 
      invoice_no,
	  stock_code,
	  description, quantity,
	  customer_id, country
	FROM clean_data.online_retail
	WHERE unit_price = 0
	order by quantity desc
	LIMIT 30;


---- 
  SELECT 
    CASE 
	   WHEN quantity >0 THEN 'positive quantity'
	   WHEN quantity <0 THEN 'negative quantity'
	   WHEN quantity =0 THEN 'zero quantity'
	   END AS quantity_type,
	   COUNT (*) AS total_records
	 FROM clean_data.online_retail
	 WHERE unit_price = 0
	 GROUP BY 1
	 ORDER BY total_records DESC;

--- COMPARING ZERO-PRICE RECORDS WITH CANCELLATION
   SELECT 
      CASE 
	     WHEN invoice_no LIKE 'C%' THEN 'CANCELLATION'
		 ELSE 'NOT CANCELLATION'
		 END AS TRANSACTION_TYPE,
	COUNT (*) AS total_records
	FROM clean_data.online_retail
	WHERE unit_price = 0
	group by 1
	order by total_records desc;

	
---OVERALL BUSINESS PERFOMANCE
   SELECT SUM(quantity * unit_price) AS total_revenue,
   COUNT(DISTINCT invoice_no) AS total_orders,
   SUM(quantity) AS total_quantity_sold,
   COUNT(DISTINCT customer_id) AS total_customers
   FROM clean_data.online_retail
   WHERE unit_price > 0
   and quantity > 0;

---MONTHLY REVENUE
   SELECT 
       DATE_TRUNC('month',invoice_date) AS MONTH,
	   SUM (quantity*unit_price) AS monthly_revenue,
	   COUNT(DISTINCT invoice_no) AS total_orders
	   FROM clean_data.online_retail
	   WHERE unit_price >0
	   AND quantity > 0
	   GROUP BY DATE_TRUNC('month', invoice_date)
	   ORDER BY month;

---- IDENTIFYING BEST AND WORST MONTHS
   SELECT
    DATE_TRUNC('month',invoice_date) AS MONTH,
	   SUM (quantity*unit_price) AS monthly_revenue,
	   COUNT(DISTINCT invoice_no) AS total_orders
	   FROM clean_data.online_retail
	   WHERE unit_price >0
	   AND quantity > 0
	   GROUP BY DATE_TRUNC('month', invoice_date)
	   ORDER BY monthly_revenue DESC;

---TOP 10 PRODUCTS BY REVENUE
    SELECT
	   stock_code, description,
	   SUM(quantity * unit_price) AS TOTAL_REVENUE,
	   SUM(quantity) AS Total_quantity_sold
	   FROM clean_data.online_retail
	   WHERE unit_price >0
	   AND quantity > 0
	   AND description IS NOT NULL
	   GROUP BY stock_code, description
	   ORDER BY total_revenue desc
	   limit 10;

---
   SELECT 
        stock_code, description,
		SUM(quantity*unit_price) AS total_revenue
		FROM clean_data.online_retail
		WHERE unit_price > 0
		AND quantity > 0
		AND description IS NOT NULL
		GROUP BY stock_code, description
		ORDER BY total_revenue DESC
		LIMIT 20;

---TOP 10 PRODUCT BY REVENUE
    SELECT 
        stock_code, description,
		SUM(quantity*unit_price) AS total_revenue
		FROM clean_data.online_retail
		WHERE unit_price > 0
		AND quantity > 0
		AND description IS NOT NULL
		AND stock_code NOT IN ('DOT', 'POST', 'M')
		GROUP BY stock_code, description
		ORDER BY total_revenue DESC
		LIMIT 10;

--- TOP 10 COUNTRIES BY REVENUE
    SELECT 
	    country, SUM(quantity*unit_price) AS total_revenue,
		COUNT (DISTINCT invoice_no) AS total_orders
		FROM clean_data.online_retail
		WHERE unit_price > 0
		  AND quantity > 0
		 GROUP BY country
		 ORDER BY total_revenue DESC
		 LIMIT 10;

----AVERAGE ORDER VALUE
    SELECT 
	   SUM(quantity * unit_price)/ COUNT (DISTINCT invoice_no) AS average_order_value
	   FROM clean_data.online_retail
	   WHERE unit_price > 0
		  AND quantity > 0;

		