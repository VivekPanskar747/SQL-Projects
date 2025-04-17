## CB SQL Project 

## Ad-Hoc Request for Atliq Hardware 

-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region. 

select market from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

with cte1  as 
(
select  count(distinct product_code) as unique_products_2020  
from fact_sales_monthly
where fiscal_year = '2020'),
cte2 as 
( 
select  count(distinct product_code) as unique_products_2021 
from fact_sales_monthly
where fiscal_year = '2021')

select unique_products_2020  , unique_products_2021 , 
Round((unique_products_2021 - unique_products_2020) *100/unique_products_2020 ,2) as pct_chg
from cte1
join cte2;

-- 3. Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count

select segment,  count(distinct product_code) as prod_count from dim_product
group by segment
order by prod_count;

-- 4. Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference
with X as 
(
select p.segment , count(distinct p.product_code) as prod_20 
from fact_sales_monthly s
join dim_product p
on p.product_code = s.product_code
where fiscal_year = 2020
group by p.segment) ,
Y as (
select p.segment , count(distinct p.product_code) as prod_21
from fact_sales_monthly s
join dim_product p
on p.product_code = s.product_code
where fiscal_year = 2021
group by p.segment)
select X.segment , Y.prod_21 , X.prod_20 , (prod_21 - prod_20) as diff
from X
join Y
on X.segment = Y.segment
order by diff desc ;

-- 5. Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost 

select * from dim_product; ## product , product_code 

select *, max(manufacturing_cost) from  fact_manufacturing_cost; ## product_code 

select p.product_code , p.product , c.manufacturing_cost
from dim_product p
join fact_manufacturing_cost c 
on p.product_code = c.product_code
where c.manufacturing_cost = 
(
select max(manufacturing_cost) from fact_manufacturing_cost
)
or
c.manufacturing_cost = 
(
select min(manufacturing_cost) from fact_manufacturing_cost
);

-- 6. Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

select c.customer_code , c.customer , c.market ,round(avg(f.pre_invoice_discount_pct),2) as avg_pct
from dim_customer c
join fact_pre_invoice_deductions f
on c.customer_code = f.customer_code
where fiscal_year = 2021 and c.market = "India"
group by customer_code
order by avg_pct desc limit 5;

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount 


select  monthname(s.date) as Month , Year(s.date) as year,
round(sum(g.gross_price * s.sold_quantity) , 2) as gross_sales_amount
from dim_customer c
join fact_sales_monthly s
on s.customer_code = c.customer_code
join fact_gross_price g 
on g.product_code = s.product_code
where customer = "Atliq Exclusive"
group by month(s.date) , year(s.date);

-- 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity

select  round(sum(sold_quantity)/1000000 , 2) as total_sold_quantity , get_fiscal_quarter(date) 
from fact_sales_monthly
where fiscal_year = 2020
group by get_fiscal_quarter(date)
order by total_sold_quantity desc;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage

with cte1 as
(
select c.channel , round(sum(g.gross_price *s.sold_quantity)/1000000 , 2) as gross_sales_mln
from dim_customer c
join fact_sales_monthly s
on c.customer_code = s.customer_code
join fact_gross_price g
on g.product_code = s.product_code
where s.fiscal_year = 2021
group by c.channel)
select *, 
round(gross_sales_mln*100/sum(gross_sales_mln) over () , 2) as channel_pct 
from cte1
order by gross_sales_mln desc;
 
-- 10. Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order

select * from dim_product; ## divsion , product_code , product 
select * from fact_sales_monthly; ## sold_quantity

with Y as 
(
select p.division , s.product_code , p.product ,
sum(s.sold_quantity) as total_quantity ,
RANK () over(partition by p.division order by sum(s.sold_quantity) desc) as rank_order
from fact_sales_monthly s
join dim_product p
on p.product_code = s.product_code
where fiscal_year = 2021
group by p.division , s.product_code , p.product
)
select * from Y
where rank_order  <=3


