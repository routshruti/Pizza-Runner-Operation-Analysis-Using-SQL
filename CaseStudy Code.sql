--SECTION A: Pizza Metrics
	
-- Q1. How many pizzas were ordered?
	
SELECT 
	COUNT(pizza_id) AS number_of_pizzas
FROM customer_orders

-- Q2. How many unique customer orders were made?

SELECT 
	COUNT(DISTINCT order_id) AS unique_orders
FROM customer_orders

-- Q3. How many successful orders were delivered by each runner?

SELECT 
	runner_id,
	COUNT(order_id) AS delivered_orders
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id

-- Q4. How many of each type of pizza was delivered?

SELECT
	pizza_id, 
	COUNT(pizza_id) AS quantity_delivered
FROM customer_orders AS co
JOIN runner_orders AS ro
  ON co.order_id = ro.order_id
WHERE cancellation IS NULL
GROUP BY pizza_id

-- Q5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT 
	customer_id,
	SUM(CASE WHEN pizza_name = 'Vegetarian' THEN 1
	         ELSE 0
	    END) AS Vegetarian,
	SUM(CASE WHEN pizza_name = 'Meatlovers' THEN 1
	         ELSE 0
	    END) AS Meatlovers
FROM customer_orders AS co
JOIN pizza_names AS pn
  ON co.pizza_id = pn.pizza_id
GROUP BY customer_id
ORDER BY customer_id
	
-- Q6. What was the maximum number of pizzas delivered in a single order?

SELECT 
	ro.order_id,
	COUNT(ro.order_id) AS max_pizzas
FROM customer_orders AS co
JOIN runner_orders AS ro
  ON co.order_id = ro.order_id
WHERE cancellation IS NULL
GROUP BY ro.order_id
ORDER BY max_pizzas DESC
LIMIT 1

-- Q7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

WITH cte AS
	(SELECT order_id, customer_id, exclusions, extras
     FROM customer_orders AS co
     LEFT JOIN pizza_exclusions AS el
	   ON co.serial_no = el.serial_no
	 LEFT JOIN pizza_extras AS et
	   ON co.serial_no = et.serial_no)
SELECT
	customer_id,
	SUM(CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1
	         ELSE 0
	    END) AS change,
	SUM(CASE WHEN exclusions IS NULL AND extras IS NULL THEN 1
	         ELSE 0
	    END) AS no_change
FROM CTE AS c
JOIN runner_orders AS ro
  ON c.order_id = ro.order_id
WHERE cancellation IS NULL
GROUP BY customer_id
ORDER BY customer_id ASC


-- Q8. How many pizzas were delivered that had both exclusions and extras?

SELECT
	COUNT(DISTINCT pizza_id) AS with_extras_and_exclusions
FROM customer_orders AS co
LEFT JOIN pizza_exclusions AS el
  ON co.serial_no = el.serial_no
LEFT JOIN pizza_extras AS et
  ON co.serial_no = et.serial_no
JOIN runner_orders AS ro
  ON co.order_id = ro.order_id
WHERE cancellation IS NULL
AND exclusions IS NOT NULL 
AND extras IS NOT NULL

-- Q9. What was the total volume of pizzas ordered for each hour of the day?
	
SELECT 
	EXTRACT(HOUR FROM order_time) AS hour, 
	COUNT(order_id) AS orders_per_hour
FROM customer_orders
GROUP BY hour
ORDER BY orders_per_hour DESC

-- Q10 What was the volume of orders for each day of the week?

SELECT to_char(order_time, 'Dy') AS day, COUNT(order_id) AS orders_per_day
FROM customer_orders
GROUP BY day
ORDER BY orders_per_day DESC



-- SECTION B: Runner and Customer Experience

-- Q1. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT
	runner_id,
	round(AVG(EXTRACT(epoch FROM (pickup_time - order_time))/60),0) AS avg_arrival_minutes
FROM runner_orders AS ro
JOIN customer_orders AS co
  ON ro.order_id = co.order_id
GROUP BY runner_id
	
-- Q2. Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH cte AS
	(SELECT
	    ro.order_id,
	    COUNT(pizza_id) AS number_of_pizzas, 
	    EXTRACT(epoch FROM (pickup_time - order_time))/60 AS preparation_time
     FROM runner_orders AS ro
     JOIN customer_orders AS co
       ON ro.order_id = co.order_id
     WHERE cancellation IS NULL
     GROUP BY ro.order_id, pickup_time, order_time)
SELECT
	number_of_pizzas,
	ROUND(AVG(preparation_time),0) AS avg_preparation_minutes
FROM cte
GROUP BY number_of_pizzas

-- Q3. What was the average distance travelled for each customer?

SELECT 
	customer_id, 
	CONCAT(ROUND(AVG(distance),1), ' km') AS avg_distance
FROM customer_orders AS co
JOIN runner_orders AS ro
  ON co.order_id = ro.order_id
GROUP BY customer_id
ORDER BY customer_id
	
-- Q4. What was the difference between the longest and shortest delivery times for all orders?

SELECT 
	MAX(duration) AS longest_delivery_time, 
	MIN(duration) AS shortest_delivery_time,
	MAX(duration) - MIN(duration) AS difference
FROM runner_orders
	
-- Q5. What is the successful delivery percentage for each runner?

SELECT 
	runner_id,
	CONCAT(100* SUM(CASE WHEN cancellation IS NULL THEN 1
                         ELSE 0
                    END)/COUNT(*), '%') AS successful_delivery
FROM runner_orders AS ro
GROUP BY runner_id

	
-- SECTION C: Ingredient Optimisation

-- Q1. What are the standard ingredients for each pizza?

SELECT pn.pizza_id, pizza_name, STRING_AGG(topping_name, ', ') AS toppings
FROM pizza_recipes AS pr
JOIN pizza_toppings AS pt
  ON pr.toppings = pt.topping_id
JOIN pizza_names AS pn
  ON pr.pizza_id = pn.pizza_id
GROUP BY pn.pizza_id, pizza_name
ORDER BY pn.pizza_id

-- Q2. What was the most commonly added extra?

SELECT topping_name AS extra_topping, COUNT(extras) AS count
FROM customer_orders AS co
JOIN pizza_extras AS et
  ON co.serial_no = et.serial_no
JOIN pizza_toppings AS pt
  ON et.extras = pt.topping_id
GROUP BY topping_name
ORDER BY count DESC
LIMIT 1
	
-- Q3. What was the most common exclusion?

SELECT topping_name AS extra_topping, COUNT(exclusions) AS count
FROM customer_orders AS co
JOIN pizza_exclusions AS el
ON co.serial_no = el.serial_no
JOIN pizza_toppings AS pt
ON el.exclusions = pt.topping_id
GROUP BY topping_name
ORDER BY count DESC
LIMIT 1
	
-- Q4. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

SELECT 
	topping_name AS ingredient, 
	COUNT(toppings) AS total_quantity
FROM customer_orders AS co
JOIN runner_orders AS ro
  ON co.order_id = ro.order_id
JOIN pizza_recipes AS pr
  ON co.pizza_id = pr.pizza_id
JOIN pizza_toppings AS pt
  ON pr.toppings = pt.topping_id
WHERE cancellation IS NULL
GROUP BY ingredient
ORDER BY total_quantity DESC


--SECTION D: Pricing and Ratings

-- Q1. If a Meat Lovers pizza costs $12 and a Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

SELECT
    SUM(CASE WHEN pizza_name = 'Meatlovers' THEN 12
	         WHEN pizza_name = 'Vegetarian' THEN 10
	    END) AS revenue
FROM customer_orders AS co
JOIN runner_orders AS ro
  ON co.order_id = ro.order_id
JOIN pizza_names AS pn
  ON co.pizza_id = pn.pizza_id
WHERE cancellation IS NULL

-- Q2. If there was an additional $1 charge for any pizza extras, then how much did Pizza Runner Make?
	
WITH cte AS 
     (SELECT 
          SUM(CASE WHEN pizza_id = 1 THEN 12
	               WHEN pizza_id = 2 THEN 10
	          END) AS revenue
      FROM customer_orders AS co
      JOIN runner_orders AS ro
        ON co.order_id = ro.order_id
      WHERE cancellation IS NULL
      UNION
      SELECT 
          SUM(CASE WHEN extras IS NOT NULL THEN 1
	               ELSE 0
	          END) AS revenue
      FROM customer_orders AS co
      JOIN pizza_extras AS et
        ON co.serial_no = et.serial_no
      JOIN runner_orders AS ro
        ON co.order_id = ro.order_id
      WHERE cancellation IS NULL)
SELECT SUM(revenue) AS total_revenue
FROM cte

-- Q3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a new table and insert your own data for ratings for each successful customer order between 1 to 5.

DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings
(order_id INT,
rating INT);
INSERT INTO runner_ratings
VALUES
(1,4),
(2,3),
(3,4),
(4,3),
(5,3),	
(6,2),
(7,4),
(8,5),
(9,3),
(10,2)

-- Q4. Using your newly generated table, can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id, order_id, runner_id, rating, order_time, pickup_time, Time between order and pickup, Delivery duration, Average speed, Total number of pizzas

CREATE TABLE info AS
SELECT
customer_id, co.order_id, runner_id, rating, order_time, pickup_time, pickup_time-order_time AS runner_arrival_time, duration AS delivery_duration,
round(AVG(distance/duration*60),0) AS average_speed, COUNT(pizza_id) AS total_number_of_pizzas
FROM customer_orders AS co
JOIN runner_orders AS ro
ON co.order_id = ro.order_id
JOIN runner_ratings AS rr
ON co.order_id = rr.order_id
WHERE cancellation IS NULL
GROUP BY 1,2,3,4,5,6,7,8
ORDER BY customer_id
