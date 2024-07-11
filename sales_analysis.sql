select *from customers;
select *from products;
select *from pincode;
select *from delivery_person;
select *from orders;

-- 1. How many customers do not have DOB information available?

SELECT COUNT(*) AS customers_without_dob
FROM Customers
WHERE dob IS NULL;

-- 2.How many customers are there in each pincode and gender combination?

SELECT primary_pincode, gender, COUNT(*) AS customer_count
FROM Customers
GROUP BY primary_pincode, gender;

--3.Print product name and mrp for products which have more than 50000 MRP?

SELECT product_name, mrp
FROM Products
WHERE mrp > 50000;

--4.How many delivery personnel are there in each pincode?

SELECT pincode, COUNT(*) AS delivery_person_count
FROM Delivery_Person
GROUP BY pincode;

--5.For each Pin code, print the count of orders, sum of total amount paid, average amount paid, maximum amount paid, minimum amount paid for the transactions which were paid by 'cash'. Take only 'buy' order types

SELECT delivery_pincode,
       COUNT(*) AS order_count,
       SUM(total_amount_paid) AS total_amount_paid,
       AVG(total_amount_paid) AS avg_amount_paid,
       MAX(total_amount_paid) AS max_amount_paid,
       MIN(total_amount_paid) AS min_amount_paid
FROM Orders
WHERE payment_type = 'cash' AND order_type = 'buy'
GROUP BY delivery_pincode;

--6.For each delivery_person_id, print the count of orders and total amount paid for product_id = 12350 or 12348 and total units > 8. Sort the output by total amount paid in descending order. Take only 'buy' order types

SELECT delivery_person_id,
       COUNT(*) AS order_count,
       SUM(total_amount_paid) AS total_amount_paid
FROM Orders
WHERE product_id IN (12350, 12348) AND tot_units > 8 AND order_type = 'buy'
GROUP BY delivery_person_id
ORDER BY total_amount_paid DESC;

--7.Print the Full names (first name plus last name) for customers that have email on "gmail.com"?

SELECT CONCAT(first_name, last_name, '@gmail.com') AS full_name
FROM Customers;

--8.Which pincode has average amount paid more than 150,000? Take only 'buy' order types 

SELECT delivery_pincode
FROM Orders
WHERE order_type = 'buy'
GROUP BY delivery_pincode
HAVING AVG(total_amount_paid) > 150000;

--9.Create following columns from order_dim data ---order_date--Order day--Order month--Order year

ALTER TABLE orders
ADD COLUMN IF NOT EXISTS order_day INT,
ADD COLUMN IF NOT EXISTS order_month INT,
ADD COLUMN IF NOT EXISTS order_year INT;

-- Update only if the columns are added successfully
UPDATE orders
SET 
    order_day = EXTRACT(DAY FROM order_date),
    order_month = EXTRACT(MONTH FROM order_date),
    order_year = EXTRACT(YEAR FROM order_date);


--10.How many total orders were there in each month and how many of them were returned? Add a column for return rate too.
--return rate = (100.0 * total return orders) / total buy orders
--Hint: You will need to combine SUM() with CASE WHEN

SELECT order_month,
       COUNT(*) AS total_orders,
       SUM(CASE WHEN order_type = 'return' THEN 1 ELSE 0 END) AS total_return_orders,
       (100.0 * SUM(CASE WHEN order_type = 'return' THEN 1 ELSE 0 END)) / COUNT(*) AS return_rate
FROM Orders
GROUP BY order_month;

--11.How many units have been sold by each brand? Also get total returned units for each brand.

SELECT p.brand,
       SUM(o.tot_units) AS total_units_sold,
       SUM(CASE WHEN o.order_type = 'return' THEN o.tot_units ELSE 0 END) AS total_returned_units
FROM Orders o
INNER JOIN Products p ON o.product_id = p.product_id
GROUP BY p.brand;

--12.How many distinct customers and delivery boys are there in each state?

SELECT p.state,
       COUNT(DISTINCT c.cust_id) AS distinct_customers,
       COUNT(DISTINCT d.delivery_person_id) AS distinct_delivery_boys
FROM Pincode p
LEFT JOIN Customers c ON p.pincode = c.primary_pincode
LEFT JOIN Delivery_Person d ON p.pincode = d.pincode
GROUP BY p.state;

--13.For every customer, print how many total units were ordered, how many units were ordered from their primary_pincode and how many were ordered not from the primary_pincode. Also, calculate the percentage of total units which were ordered from the primary_pincode (remember to multiply the numerator by 100.0). Sort by the percentage column in descending order.

SELECT o.cust_id,
       SUM(o.tot_units) AS total_units_ordered,
       SUM(CASE WHEN o.delivery_pincode = c.primary_pincode THEN o.tot_units ELSE 0 END) AS units_from_primary_pincode,
       SUM(CASE WHEN o.delivery_pincode != c.primary_pincode THEN o.tot_units ELSE 0 END) AS units_not_from_primary_pincode,
       (100.0 * SUM(CASE WHEN o.delivery_pincode = c.primary_pincode THEN o.tot_units ELSE 0 END)) / SUM(o.tot_units) AS percentage_primary_pincode
FROM Orders o
JOIN Customers c ON o.cust_id = c.cust_id
GROUP BY o.cust_id
ORDER BY percentage_primary_pincode DESC;

--14.For each product name, print the sum of the number of units, total amount paid, total displayed selling price, the total MRP of these units, and finally, the net discount from selling price (i.e., 100.0 - 100.0 * total amount paid / total displayed selling price) & the net discount from MRP (i.e., 100.0 - 100.0 * total amount paid / total MRP).

SELECT p.product_name,
       SUM(o.tot_units) AS total_units_ordered,
       SUM(o.total_amount_paid) AS total_amount_paid,
       SUM(o.displayed_selling_price_per_unit * o.tot_units) AS total_displayed_selling_price,
       SUM(p.mrp * o.tot_units) AS total_mrp,
       (100.0 - 100.0 * SUM(o.total_amount_paid) / SUM(o.displayed_selling_price_per_unit * o.tot_units)) AS net_discount_from_selling_price,
       (100.0 - 100.0 * SUM(o.total_amount_paid) / SUM(p.mrp * o.tot_units)) AS net_discount_from_mrp
FROM Orders o
INNER JOIN Products p ON o.product_id = p.product_id
GROUP BY p.product_name;

--15. For every order_id (exclude returns), get the product name and calculate the discount percentage from the selling price. Sort by the highest discount and print only those rows where the discount percentage was above 10.10%.

SELECT o.order_id,
       p.product_name,
       ((100.0 * (p.mrp - o.total_amount_paid)) / p.mrp) AS discount_percentage
FROM Orders o
INNER JOIN Products p ON o.product_id = p.product_id
WHERE o.order_type != 'return'
GROUP BY o.order_id, p.product_name, p.mrp, o.total_amount_paid
HAVING ((100.0 * (p.mrp - o.total_amount_paid)) / p.mrp) > 10.10
ORDER BY discount_percentage DESC;

--16.Using the per unit procurement cost in product_dim, find which product category has made the most profit in both absolute amount and percentage.
--Absolute Profit = Total Amount Sold - Total Procurement Cost
--Percentage Profit = (100.0 * Total Amount Sold / Total Procurement Cost) - 100.0

SELECT p.category,
       SUM(o.total_amount_paid - (o.tot_units * p.procurement_cost_per_unit)) AS absolute_profit,
       (100.0 * SUM(o.total_amount_paid) / SUM(o.tot_units * p.procurement_cost_per_unit)) - 100.0 AS percentage_profit
FROM Orders o
INNER JOIN Products p ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY absolute_profit DESC;

--17.For every delivery person (use their name), print the total number of order IDs (exclude returns) by month in separate columns. i.e., there should be one row for each delivery_person_id and 12 columns for every month in the year.

SELECT d.name AS delivery_person_name,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 1 THEN 1 ELSE 0 END) AS Jan,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 2 THEN 1 ELSE 0 END) AS Feb,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 3 THEN 1 ELSE 0 END) AS Mar,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 4 THEN 1 ELSE 0 END) AS Apr,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 5 THEN 1 ELSE 0 END) AS May,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 6 THEN 1 ELSE 0 END) AS Jun,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 7 THEN 1 ELSE 0 END) AS Jul,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 8 THEN 1 ELSE 0 END) AS Aug,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 9 THEN 1 ELSE 0 END) AS Sep,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 10 THEN 1 ELSE 0 END) AS Oct,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 11 THEN 1 ELSE 0 END) AS Nov,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 12 THEN 1 ELSE 0 END) AS Dec
FROM Orders o
INNER JOIN Delivery_Person d ON o.delivery_person_id = d.delivery_person_id
WHERE o.order_type != 'return'
GROUP BY d.name;

--18.For each gender - male and female - find the absolute and percentage profit (like in Q15) by product name.

SELECT c.gender,
       p.product_name,
       SUM(o.total_amount_paid - (o.tot_units * p.procurement_cost_per_unit)) AS absolute_profit,
       (100.0 * SUM(o.total_amount_paid) / SUM(o.tot_units * p.procurement_cost_per_unit)) - 100.0 AS percentage_profit
FROM Orders o
INNER JOIN Products p ON o.product_id = p.product_id
INNER JOIN Customers c ON o.cust_id = c.cust_id
GROUP BY c.gender, p.product_name;

--19.Generally, the more numbers of units you buy, the more discount seller will give you. For 'Dell AX420', is there a relationship between the number of units ordered and average discount from selling price? Take only 'buy' order types.

SELECT tot_units,
       AVG(displayed_selling_price_per_unit - total_amount_paid) AS avg_discount
FROM Orders
WHERE product_id IN (SELECT product_id FROM Products WHERE product_name = 'Dell AX420') AND order_type = 'buy'
GROUP BY tot_units;









