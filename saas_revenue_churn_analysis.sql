-- ====
-- EDA
-- ====
SELECT * FROM monthly_revenue;

SELECT monthly_churn_rate_pct,
ROUND((churned_customers/total_active_customers)*100,2) AS monhtly_churn_rate_check
FROM monthly_revenue;
# checking my assumption about calculation of monthly_churn_rate_pct column

SELECT avg_revenue_per_customer,
ROUND(total_mrr/total_active_customers,2) AS avg_revenue_check
FROM monthly_revenue;
# checking my assumption about calculation of avg_revenue_per_customer

SELECT month, total_active_customers AS starting_customers, new_customers, churned_customers,
total_active_customers + new_customers - churned_customers AS expected_next_month_start,
LEAD(total_active_customers, 1) OVER(ORDER BY month) AS reported_next_month
FROM monthly_revenue
ORDER BY month;
# the customer counts do not reconcile

SELECT month, total_active_customers AS starting_customers, new_customers, churned_customers,
total_active_customers + new_customers - churned_customers AS expected_next_month_start,
LEAD(total_active_customers) OVER(ORDER BY month) AS reported_next_month_start,
LEAD(total_active_customers) OVER(ORDER BY month) - (total_active_customers + new_customers - churned_customers) AS unexplained_difference
FROM monthly_revenue
ORDER BY month;
# there are multiple months with customers who are not accounted for; possible reason: customers may have reactived their plan, but are not accounted for separately in this dataset


SELECT * FROM subscriptions;

SELECT COUNT(*) AS number_of_rows,
	COUNT(DISTINCT customer_id) AS number_of_customers
FROM subscriptions;
# each customer appears only once

SELECT churned,
	COUNT(*) AS number_of_customers,
    SUM(churn_date IS NOT NULL) AS with_churn_date
FROM subscriptions
GROUP BY churned;
# both churned = yes and churned = no have churn date

SELECT churn_date
FROM subscriptions
WHERE churned = 'No';

SELECT churn_date
FROM subscriptions
WHERE churned = 'No'
AND churn_date IS NULL;

SELECT churn_date
FROM subscriptions
WHERE churned = 'No'
AND churn_date = "";

SELECT SUM(IF(churned = 'No', 1, 0)) AS number_of_nonchurners
FROM subscriptions;

SELECT COUNT(churn_date) AS number_of_empty_churn_date
FROM subscriptions
WHERE churned = 'No'
AND churn_date = "";
# all churn_date values for nonchurners are filled with ""

SELECT DISTINCT plan
FROM subscriptions;
# 4 plan subscriptions (professional, starter, business, enterprise)

SELECT DISTINCT billing_cycle
FROM subscriptions;
# 2 billing cycles - monthly and annual

SELECT COUNT(DISTINCT industry)
FROM subscriptions;
# 10 industries

SELECT DISTINCT company_size
FROM subscriptions
ORDER BY company_size;

SELECT plan, company_size
FROM subscriptions
GROUP BY plan, company_size
ORDER BY plan;
# plans are not exclusive to particular company-size categories

SELECT DISTINCT region
FROM subscriptions;
# 4 regions

SELECT DISTINCT acquisition_channel
FROM subscriptions;
# 6 channels

SELECT DISTINCT churned
FROM subscriptions;

SELECT DISTINCT churn_reason
FROM subscriptions;
# there are empty values for churn reason

SELECT *
FROM subscriptions
WHERE churn_reason = '';
# churn reason is empty when churned = No

SELECT *
FROM subscriptions
WHERE churn_reason = ''
AND churned = 'Yes';
# there are no exceptions


-- ===============
-- CHURN ANALYSIS
-- ===============
-- WHAT IS THE OVERALL SHARE EVER CHURNED?
SELECT ROUND((churned_customers.num_of_churned / all_customers.num_of_customers)*100,2) AS share_churned
FROM (SELECT COUNT(customer_id) AS num_of_churned FROM subscriptions WHERE churned = 'Yes') AS churned_customers,
	(SELECT COUNT(DISTINCT customer_id) AS num_of_customers FROM subscriptions) AS all_customers;
# 52.17%

-- WHAT IS THE SHARE EVER CHURNED BY PLAN?
SELECT plan,
SUM(IF(churned = 'Yes', 1, 0)) AS number_of_churned
FROM subscriptions
GROUP BY plan
ORDER BY number_of_churned DESC;
# those on starter plan churn the most (153 customers churned)

SELECT plan,
SUM(IF(churned = 'Yes', 1, 0)) AS number_of_churned,
COUNT(customer_id) AS number_of_customers,
ROUND((SUM(IF(churned = 'Yes', 1, 0)))/(COUNT(customer_id))*100,2) AS churned_percentage
FROM subscriptions
GROUP BY plan
ORDER BY 4 DESC, 3 DESC;
# 153 out of 217 (70.51%) customers with starter plan churned

-- WHAT IS THE SHARE EVER CHURNED BY BILLING CYCLE?
SELECT billing_cycle,
SUM(IF(churned = 'Yes', 1, 0)) AS number_of_churned,
COUNT(customer_id) AS number_of_customers,
ROUND((SUM(IF(churned = 'Yes', 1, 0)))/(COUNT(customer_id))*100,2) AS churned_percentage
FROM subscriptions
GROUP BY billing_cycle
ORDER BY 4 DESC, 3 DESC;
# customers who pay monthly churn more than customers who pay annually (60% vs 40%)

-- WHAT IS THE SHARE EVER CHURNED BY ACQUISITION CHANNEL?
SELECT acquisition_channel,
SUM(IF(churned = 'Yes', 1, 0)) AS number_of_churned,
COUNT(customer_id) AS number_of_customers,
ROUND((SUM(IF(churned = 'Yes', 1, 0)))/(COUNT(customer_id))*100,2) AS churned_percentage
FROM subscriptions
GROUP BY acquisition_channel
ORDER BY 4 DESC, 3 DESC;
# customers who discovered CloudTaskPro via referral churned the most (61.29%)

-- WHAT IS THE SHARE EVER CHURNED BY COMPANY SIZE?
SELECT company_size,
SUM(IF(churned = 'Yes', 1, 0)) AS number_of_churned,
COUNT(customer_id) AS number_of_customers,
ROUND((SUM(IF(churned = 'Yes', 1, 0))/COUNT(customer_id))*100,2) AS churned_percentage
FROM subscriptions
GROUP BY company_size
ORDER BY 4 DESC, 3 DESC;
# customers from the largest companies have the highest churn share (63.16%)
# companies of size 11-50 have the most churned customers (93)
# the smallest companies (1-10) have a high percentage across a much larger group

-- WHAT ARE THE TOP 3 REASONS FOR CHURNING?
SELECT churn_reason,
COUNT(churned) AS number_of_churned
FROM subscriptions
WHERE churned = 'Yes'
GROUP BY churn_reason
ORDER BY 2 DESC
LIMIT 3;
# budget cuts, price too high, company closed
# price too high is something CloudTask Pro can control

SELECT plan, billing_cycle, industry, company_size
FROM subscriptions
WHERE churned = 'Yes'
AND churn_reason = 'Price Too High';

-- WHAT IS THE RELATIONSHIP BETWEEN "PRICE TOO HIGH" AND...?
SELECT plan,
COUNT(customer_id) AS number_of_customers
FROM subscriptions
WHERE churned = 'Yes'
AND churn_reason = 'Price Too High'
GROUP BY plan WITH ROLLUP;
# most of the customers who found price to be too high are on starter plan (29/51)

SELECT billing_cycle,
COUNT(customer_id) AS number_of_customers
FROM subscriptions
WHERE churned = 'Yes'
AND churn_reason = 'Price Too High'
GROUP BY billing_cycle WITH ROLLUP;
# most of the customers who found price to be too high are paying monthly (37/51)

SELECT industry,
COUNT(customer_id) AS number_of_customers
FROM subscriptions
WHERE churned = 'Yes'
AND churn_reason = 'Price Too High'
GROUP BY industry WITH ROLLUP;
# largest count of the customers who found price to be too high are from legal industry (10/51)

SELECT company_size,
COUNT(customer_id) AS number_of_customers
FROM subscriptions
WHERE churned = 'Yes'
AND churn_reason = 'Price Too High'
GROUP BY company_size WITH ROLLUP;
# most of the customers who found price to be too high are from small companies (size 1-10 employees) (16/51)

-- ================
-- UNIT ECONOMICS
-- ================
-- WHAT IS THE AVERAGE ESTIMATED LIFETIME REVENUE PER CHURNED CUSTOMER BY PLAN?
# first approach at calculating customer lifetime in months
WITH customer_lifetime AS (
	SELECT plan, signup_date, churn_date,
	TIMESTAMPDIFF(MONTH, signup_date, churn_date) AS customer_lifetime_in_months,
    monthly_revenue
	FROM subscriptions
	WHERE churn_date <> "")
SELECT plan, AVG(customer_lifetime_in_months) AS average_customer_lifespan
FROM customer_lifetime
GROUP BY plan;
-- problem: returns whole completed months, discarding the remaining days

# second approach at calculating customer lifetime in months
# average calendar-month length = 30.44 days
WITH customer_lifetime AS (
	SELECT plan, signup_date, churn_date,
	DATEDIFF(churn_date, signup_date) AS customer_lifetime_in_days,
    monthly_revenue
	FROM subscriptions
	WHERE churn_date <> "")
SELECT plan,
ROUND(AVG(monthly_revenue*customer_lifetime_in_days)/30.44,2) AS estimated_revenue_CLV_per_plan
FROM customer_lifetime
GROUP BY plan
ORDER BY 2 DESC;
-- average (monthly revenue * customer lifespan) = estimated revenue CLV per plan for customers who churned

-- WHAT IS THE AVERAGE OBSERVED-TO-DATE REVENUE BY PLAN?
-- checking the last date on which we have data
SELECT signup_date
FROM subscriptions
ORDER BY 1 DESC;
-- assumed observarion end date = 2025-12-31

WITH customer_lifetime AS (
	SELECT plan, signup_date, churn_date,
	IF(churn_date <> "", DATEDIFF(churn_date, signup_date), DATEDIFF('2025-12-31', signup_date)) AS customer_lifetime_in_days,
    churned, monthly_revenue
	FROM subscriptions)
SELECT plan,
ROUND(AVG((monthly_revenue*customer_lifetime_in_days)/30.44),2) AS estimated_revenue_per_customer
FROM customer_lifetime
GROUP BY plan
ORDER BY 2 DESC;
-- active customers observed tenure was calculated from signup to the assumed cutoff date, so their estimated revenue covers only their time as customer so far, not their eventual lifetime value (it is a proxy)
-- enterprise plan has the highest average estimated observed-to-date revenue per customer

-- WHAT IS THE AVERAGE ESTIMATED OBSERVED-TO-DATE REVENUE PER CUSTOMER BY PLAN AND CHURN STATUS?
WITH customer_lifetime AS (
	SELECT plan, signup_date, churn_date,
	IF(churn_date <> "", DATEDIFF(churn_date, signup_date), DATEDIFF('2025-12-31', signup_date)) AS customer_lifetime_in_days,
    churned, monthly_revenue, customer_id
	FROM subscriptions)
SELECT churned, plan,
ROUND(AVG((monthly_revenue*customer_lifetime_in_days)/30.44),2) AS estimated_revenue_per_plan,
COUNT(customer_id) AS number_of_customers
FROM customer_lifetime
GROUP BY churned, plan
ORDER BY 3 DESC;
-- customers who didn't churn (active customers) and are on enterprise plan have the highest average estimated observed-to-date revenue per customer
-- interestingly, customers who churned and were on start plan were in the largest group by customer count, but had the lowest average estimated revenue per customer

-- ===================
-- AT-RISK INDICATORS
-- ===================
-- WHAT IS THE RELATIONSHIP BETWEEN FEATURE USAGE, NPS AND CHURN?
-- comparing active and churned customers' average
SELECT churned,
COUNT(*) AS number_of_customers,
ROUND(AVG(feature_usage_pct), 2) AS avg_feature_usage_pct,
ROUND(AVG(nps_score), 2) AS avg_nps_response
FROM subscriptions
GROUP BY churned;
-- both feature usage and NPS reponses differ between active and churned customers (customers who churned have lower average feature usage and lower average nps reponse)

-- FLAGGING AT-RISK CUSTOMERS BY FEATURE USAGE PCT
-- assumption: at-risk customers are customers who have feature_usage_pct below x%
-- creating buckets for feature_usage_pct
WITH buckets_for_feature_usage AS (
SELECT *,
CASE 
	WHEN feature_usage_pct = 100 THEN 90
    ELSE FLOOR(feature_usage_pct/10) * 10
    END AS bucket_start
FROM subscriptions),
subscriptions_with_buckets AS (
SELECT *,
CASE
	WHEN bucket_start = 90 THEN '90-100'
    ELSE CONCAT(bucket_start, '-<', bucket_start + 10)
    END AS feature_usage_bucket
FROM buckets_for_feature_usage)
SELECT *
FROM subscriptions_with_buckets;

WITH buckets_for_feature_usage AS (
SELECT *,
CASE 
	WHEN feature_usage_pct = 100 THEN 90
    ELSE FLOOR(feature_usage_pct/10) * 10
    END AS bucket_start
FROM subscriptions),
subscriptions_with_buckets AS (
SELECT *,
CASE
	WHEN bucket_start = 90 THEN '90-100'
    ELSE CONCAT(bucket_start, '-<', bucket_start + 10)
    END AS feature_usage_bucket
FROM buckets_for_feature_usage)
SELECT feature_usage_bucket,
SUM(IF(churned = "Yes", 1, 0)) AS number_of_churned,
SUM(IF(churned = "No", 1, 0)) AS number_of_active
FROM subscriptions_with_buckets
GROUP BY feature_usage_bucket
ORDER BY 1;
-- no churn was observed among customers in higher usage buckets (above 60%)
-- only 5 customers who have feature usage 50%-59% have churned
-- all other customers who have churned have feature usage between 10 and 49%
-- assumption: active customers who have feature usage below 50% are most at-risk of churning

-- NUMBER OF CUSTOMERS AT-RISK BY FEATURE USAGE PCT
WITH buckets_for_feature_usage AS (
SELECT *,
CASE 
	WHEN feature_usage_pct = 100 THEN 90
    ELSE FLOOR(feature_usage_pct/10) * 10
    END AS bucket_start
FROM subscriptions),
subscriptions_with_buckets AS (
SELECT *,
CASE
	WHEN bucket_start = 90 THEN '90-100'
    ELSE CONCAT(bucket_start, '-<', bucket_start + 10)
    END AS feature_usage_bucket
FROM buckets_for_feature_usage)
SELECT feature_usage_bucket,
COUNT(customer_id) AS number_of_customers_at_risk_per_bucket
FROM subscriptions_with_buckets
WHERE feature_usage_bucket IN ("10-<20", "20-<30", "30-<40", "40-<50")
AND churned = "No"
GROUP BY feature_usage_bucket WITH ROLLUP
ORDER BY 1;
-- there are 132 customers at risk if a defined trashold for at-risk customer is that a customer has feature usage below 50%

-- NPS VS CHURN
WITH nps_groups AS(
SELECT churned,
CASE
	WHEN nps_score BETWEEN 0 AND 6 THEN 'Detractor'
    WHEN nps_score BETWEEN 7 AND 8 THEN 'Passive'
    WHEN nps_score BETWEEN 9 AND 10 THEN 'Promoter'
END AS nps_group
FROM subscriptions)
SELECT churned,  nps_group, COUNT(*) AS number_of_customers
FROM nps_groups
GROUP BY churned, nps_group;
-- only customers who have nps score between 0 and 6 have churned

-- FEATURE USAGE AND NPS VS CHURN
-- if customers have similar usage, does NPS distinguish customers who churned?
WITH customer_segments AS (
SELECT *,
CASE
	WHEN feature_usage_pct BETWEEN 0 AND 49 THEN 'Below 50%'
    ELSE "50% or above"
    END AS usage_group,
CASE
	WHEN nps_score BETWEEN 0 AND 6 THEN 'Detractor'
    WHEN nps_score BETWEEN 7 AND 8 THEN 'Passive'
    WHEN nps_score BETWEEN 9 AND 10 THEN 'Promoter'
END AS nps_group
 FROM subscriptions)
SELECT usage_group, nps_group,
SUM(IF(churned = "Yes", 1, 0)) AS number_of_churned,
SUM(IF(churned = "No", 1, 0)) AS number_of_active
FROM customer_segments
GROUP BY usage_group, nps_group WITH ROLLUP
ORDER BY 1;
-- all churned customers are detractors and most of them have below 50% feature usage
-- if customers use features 50% or above, customers with nps score between 0 and 6 have churned

-- CUSTOMERS AT-RISK BY FEATURE USAGE PCT AND NPS SCORE (FOR EXPORT)
-- assumption: at-risk customers are customers who have feature_usage_pct below 50% AND are detractors (nps_score between 0 and 6)
SELECT customer_id, plan, billing_cycle, industry, company_size, monthly_revenue, feature_usage_pct, nps_score
FROM subscriptions
WHERE churned = 'No'
AND feature_usage_pct < 50
AND nps_score BETWEEN 0 AND 6
ORDER BY monthly_revenue;