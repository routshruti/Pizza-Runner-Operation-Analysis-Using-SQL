# Introduction:

Inspired by the concept of “80s Retro Styling and Pizza Is The Future,” Danny launched Pizza Runner, a modern pizza delivery service blending retro themes with an Uber-style delivery model.

# Problem Statement:

As Pizza Runner expands, operational complexities are increasing. Danny needs a deeper understanding of his data to make informed decisions and streamline his business.

# Goal:

The objective is to clean and analyze Pizza Runner's data to extract key insights to optimize operations, enhance delivery efficiency, and support the growth of the business through data-driven strategies.

# Stakeholder(s):
CEO/Founder

# Solution:

## 1. Data Cleaning, Transforming, and Normalizing for Analysis

Below are the detailed steps taken to ensure the data is clean, consistent, and properly formatted for analysis.

### Table 2: `customer_orders`

#### Step 1: Dealing with “null” and Empty Rows
Replace `'null'` and empty strings with `NULL` to standardize missing data.

```sql
UPDATE customer_orders
SET exclusions = NULL 
WHERE exclusions IN ('null', '');

UPDATE customer_orders
SET extras = NULL 
WHERE extras IN ('null', '');
```

#### Step 2: Normalization
- **Atomic Values**: Ensure that each column contains only atomic values by splitting multi-valued fields into separate rows.
- **Separate Tables**: Create `pizza_exclusions` and `pizza_extras` tables to store individual exclusions and extras.
- **Unique Identifier**: Add a `serial_no` column to maintain the link between normalized data and original records.

```sql
ALTER TABLE customer_orders
ADD COLUMN serial_no SERIAL PRIMARY KEY;

CREATE TABLE pizza_exclusions AS
SELECT serial_no, unnest(string_to_array(exclusions, ',')) AS exclusion
FROM customer_orders;

ALTER TABLE customer_orders
DROP COLUMN exclusions;

CREATE TABLE pizza_extras AS
SELECT serial_no, unnest(string_to_array(extras, ',')) AS extra
FROM customer_orders;

ALTER TABLE customer_orders
DROP COLUMN extras;
```

#### Step 3: Correct Data Types
Ensure the data types are correct for proper analysis.
- Change exclusions and extras columns from **varchar** to **integer**

```sql
ALTER TABLE pizza_exclusions
ALTER COLUMN exclusion TYPE INT USING exclusion::integer;

ALTER TABLE pizza_extras
ALTER COLUMN extra TYPE INT USING extra::integer;
```

### Table 3: `runner_orders`

#### Step 1: Dealing with “null” and Empty Rows
Replace `'null'` and empty strings with `NULL`.

```sql
UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time IN ('null', '');

UPDATE runner_orders
SET distance = NULL
WHERE distance IN ('null', '');

UPDATE runner_orders
SET duration = NULL
WHERE duration IN ('null', '');

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation IN ('null', '');
```

#### Step 2: Dealing with Inconsistencies
Remove unnecessary text from the `distance` and `duration` columns.

```sql
UPDATE runner_orders
SET distance = REPLACE(distance, 'km', '');

UPDATE runner_orders
SET duration = REPLACE(REPLACE(REPLACE(duration, 'mins', ''), 'minutes', ''), 'minute', '');
```

#### Step 3: Correct Data Types
Ensure the data types are correct for proper analysis.
- Change pickup_time from **varchar** to **timestamp**
-	Change distance from **varchar** to **numeric**
-	Change duration from **varchar** to **integer**
  
```sql
ALTER TABLE runner_orders
ALTER COLUMN pickup_time TYPE timestamp USING pickup_time::timestamp without time zone;

ALTER TABLE runner_orders
ALTER COLUMN distance TYPE numeric USING distance::numeric;

ALTER TABLE runner_orders
ALTER COLUMN duration TYPE INT USING duration::integer;
```

### Table 5: `pizza_recipes`

#### Step 1: Data Normalization
Split the `toppings` column into individual rows to remove multi-value rows.

```sql
CREATE TABLE pizza_recipes1 AS
SELECT pizza_id, unnest(string_to_array(toppings, ',')) AS topping
FROM pizza_recipes;

DROP TABLE IF EXISTS pizza_recipes;

ALTER TABLE pizza_recipes1
RENAME TO pizza_recipes;
```

#### Step 2: Correct Data Types
Ensure the `topping` column has the correct data type.
- change topping from **text** to **integer**
  
```sql
ALTER TABLE pizza_recipes
ALTER COLUMN topping TYPE INT USING topping::integer;
```

## 2. Data Analysis
After the data cleaning process, I conducted a detailed analysis, answering over 20 questions that explored various dimensions of the dataset:

- SECTION A: Pizza Metrics
- SECTION B: Runner and Customer Experience
- SECTION C: Ingredient Optimization
- SECTION D: Pricing and Ratings

# Topics Covered:
- DDL and DML Commands
- Sorting and Filtering
- Joining Tables
- Group By
- Aggregate Functions
- Subqueries
- CTE
- Window Functions
- Date-Time Manipulation
- Conversion Functions

# Tools Used:
- PostgreSQL
- pgAdmin
