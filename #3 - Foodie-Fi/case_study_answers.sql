/* --------------------
   Case Study Questions
   --------------------*/
   

-- A. Customer Journey

-- Based off the 8 sample customers provided in the sample from the subscriptions table, 
-- -- write a brief description about each customer’s onboarding journey. Try to keep it as short as possible 
-- -- - you may also want to run some sort of join to make your explanations a bit easier!

select s.customer_id
	, s.start_date
	, p.plan_name
	, p.price
from foodie_fi.subscriptions as s
	join foodie_fi.plans as p on s.plan_id = p.plan_id
where customer_id <= 8;

  
-- B. Data Analysis Questions

-- 1. How many customers has Foodie-Fi ever had?
-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
-- 6. What is the number and percentage of customer plans after their initial free trial?
-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
-- 8. How many customers have upgraded to an annual plan in 2020?
-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?  


-- 1. How many customers has Foodie-Fi ever had?

select count( distinct customer_id) as customer_count
from foodie_fi.subscriptions;


-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

select date_trunc('month', start_date) as month
	, count(customer_id)
from foodie_fi.subscriptions
where plan_id = 0
group by 1
order by 1;


-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

select p.plan_name
	, count(p.plan_name)
from foodie_fi.subscriptions as s
	join foodie_fi.plans as p on s.plan_id = p.plan_id
where extract(year from s.start_date) > 2020
group by 1;


-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

select count(distinct s.customer_id) as total_cust
	, sum(case when p.plan_name = 'churn' then 1 else 0 end) as count_churned
	, round(100.0 * sum(case when p.plan_name = 'churn' then 1 else 0 end)
		/ count(distinct s.customer_id), 1) as perc_churned
from foodie_fi.subscriptions as s
	join foodie_fi.plans as p on s.plan_id = p.plan_id;


-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

with cte as (
	select s.customer_id
		, plan_id
		, row_number() over (
		partition by s.customer_id
		order by s.plan_id) as rn
	from foodie_fi.subscriptions as s 
	group by 1, 2
	)
select sum(case when plan_id = 4 and rn = 2 then 1 else 0 end) as churned_after_ft 
	, 100* sum(case when plan_id = 4 and rn = 2 then 1 else 0 end)
		/ count(distinct customer_id) as perc_churned_aft
from cte;


-- 6. What is the number and percentage of customer plans after their initial free trial?

with cte as (
	select s.customer_id
		, s.plan_id
		, p.plan_name
		, row_number() over (
		partition by s.customer_id
		order by s.plan_id) as rn
	from foodie_fi.subscriptions as s
		join foodie_fi.plans as p on s.plan_id = p.plan_id
	group by 1, 2, 3
	)
select plan_id
	, plan_name
	, count(plan_id) as customer_count
	, round(100.0 * count(plan_id) 
		/ (select count(distinct customer_id)
			from cte),1) as customer_perc
from cte
where rn = 2 
group by 1, 2; 


-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

with cte as (
	select s.customer_id
		, s.plan_id
		, p.plan_name
		, s.start_date
		, row_number() over (
		partition by s.customer_id
		order by s.start_date desc) as rn
	from foodie_fi.subscriptions as s
		join foodie_fi.plans as p on s.plan_id = p.plan_id
	where start_date <= '2020-12-31' 
	group by 1, 2, 3, 4
	)
select plan_id
	, plan_name
	, count(distinct case when rn = 1 then customer_id end) as customer_count
	, round(100.0 * count(distinct case when rn = 1 then customer_id end)
		/ (select count(distinct customer_id) from cte), 1) as customer_perc
from cte
group by 1, 2
order by 1;


-- 8. How many customers have upgraded to an annual plan in 2020?

select count(s.customer_id) as pro_annual_customers
from foodie_fi.subscriptions as s
	join foodie_fi.plans as p on s.plan_id = p.plan_id
where extract (year from start_date) = 2020	
		and p.plan_name = 'pro annual';

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

with cte_trial as (
	select s.customer_id
		, s.start_date
	from foodie_fi.subscriptions as s
		join foodie_fi.plans as p on s.plan_id = p.plan_id
	where p.plan_name = 'trial'
	)
, cte_annual as (
	select s.customer_id
		, s.start_date
	from foodie_fi.subscriptions as s
		join foodie_fi.plans as p on s.plan_id = p.plan_id
	where p.plan_name = 'pro annual'
	)
select round(avg(a.start_date - t.start_date)) AS avg_days_to_switch
from cte_trial as t
	join cte_annual as a on t.customer_id = a.customer_id;
	
	
-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

with cte_trial as (
	select s.customer_id
		, s.start_date
	from foodie_fi.subscriptions as s
		join foodie_fi.plans as p on s.plan_id = p.plan_id
	where p.plan_name = 'trial'
	)
, cte_annual as (
	select s.customer_id
		, s.start_date
	from foodie_fi.subscriptions as s
		join foodie_fi.plans as p on s.plan_id = p.plan_id
	where p.plan_name = 'pro annual'
	)
, cte_diff as (
	select a.start_date - t.start_date AS days_to_switch
	from cte_trial as t
		join cte_annual as a on t.customer_id = a.customer_id
	)	
select case when days_to_switch <= 30 then '0-30 days'
	when days_to_switch <= 60 then '31-60 days'
	when days_to_switch <= 90 then '61-90 days'
	when days_to_switch <= 120 then '91-120 days'
	when days_to_switch <= 150 then '121-150 days'
	else 'over 150 days'
	end as period
	, count(*) as customer_count
from cte_diff
group by 1;


-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

with pro as (
	select s.customer_id
		, s.start_date 
	from foodie_fi.subscriptions as s
		join foodie_fi.plans as p on s.plan_id = p.plan_id
	where p.plan_name = 'pro monthly'
	)
, basic as (
	select s.customer_id
		, s.start_date
	from foodie_fi.subscriptions as s
		join foodie_fi.plans as p on s.plan_id = p.plan_id
	where p.plan_name = 'basic monthly'
	)
select count(pro.customer_id) as customer_count
	from pro 
		join basic on pro.customer_id = basic.customer_id
where pro.start_date < basic.start_date
	and extract(year from pro.start_date) = 2020; 