-- Exploratory Data Analytics

select * 
from layoffs_staging2;

-- showing how many total layoffs occurred

select sum(total_laid_off) as total_laid_off_count
from layoffs_staging2;   


-- Top 10 companies by total layoffs

select company,
       sum(total_laid_off) as total_laid_off
from layoffs_staging2
group by company
order by total_laid_off desc
limit 10;


-- Total layoffs by industry

select industry,
	   sum(total_laid_off) as total_laid_off_by_industry
from layoffs_staging2
group by industry
order by total_laid_off_by_industry desc
limit 10;   


-- Total layoffs by country

select location,
	   sum(total_laid_off) as total_laid_off_by_country
from layoffs_staging2
group by location
order by total_laid_off_by_country desc
limit 10;      


-- Total layoffs per year

select year(date) as layoff_year,
       sum(total_laid_off) as total_laid_offs
from layoffs_staging2
group by layoff_year
order by total_laid_offs desc
limit 10;     


-- Layoffs by stage

select *
from layoffs_staging2;

select stage,
	   sum(total_laid_off) as total_laid_off_by_stage
from layoffs_staging2
group by stage
order by total_laid_off_by_stage desc
limit 10;  

-- -- Highest total_laid_off in one record

select company,date,sum(total_laid_off) as laid_off_at_once
from layoffs_staging2
group by company,date
order by laid_off_at_once desc
limit 10;

-- Which companies laid off 100% of employees

select company,date,percentage_laid_off,sum(total_laid_off) as full_layoff
from layoffs_staging2
where percentage_laid_off = 1
group by company,date,percentage_laid_off
order by full_layoff desc 
limit 10;

-- Rank industries -- What are the top 10 industries by layoffs

with Cte1 as (
select industry,
	sum(total_laid_off) as total_laid_off_by_industry
    from layoffs_staging2
    group by industry
    )
select *,
	total_laid_off_by_industry,
    dense_rank() over(order by total_laid_off_by_industry desc) as industry_ranking
from Cte1;


-- Monthly trend -- Which month had the highest layoffs

select company,date_format(date, '%Y-%m') as monthly_laid_off,
	sum(total_laid_off) as total_laid_offs
	from layoffs_staging2
group by company,monthly_laid_off
order by total_laid_offs desc
limit 10; 


-- Monthly layoffs trend over time -- using rolling sum

WITH cte2 AS (
    SELECT
        DATE_FORMAT(date, '%Y-%m') AS month,
        SUM(total_laid_off) AS monthly_laid_offs
    FROM layoffs_staging2
    GROUP BY month
)
SELECT
    month,
    monthly_laid_offs,
    SUM(monthly_laid_offs) OVER (ORDER BY month) AS rolling_total
FROM cte2	
ORDER BY month;
   
-- Top 5 companies with most layoffs each year

with company_year as (
	select company,
		year(date) as layoff_year,
        sum(total_laid_off) as total_layoffs
	from layoffs_staging2
    group by company,layoff_year 
),
ranked_companies as (
	select *,
    dense_rank() over(partition by layoff_year order by total_layoffs desc) as ranked_layoffs
    from company_year
)
select * from
ranked_companies
where ranked_layoffs <= 5
order by layoff_year,ranked_layoffs;    
        
-- Which industries grew worse over time  -- IMPORTANT LOGIC -- USING LAG()

with yearly_layoffs as (
	select year(date) as dates,industry,sum(total_laid_off) as totals
    from layoffs_staging2
    group by industry,dates
),
changes_in_layoffs as (
	select dates,totals,industry,
    lag(totals) over (partition by industry order by dates) as prev_year,
    totals - lag(totals) over (partition by industry order by dates) as changes
    from yearly_layoffs
    order by dates,industry
)
select * from 
changes_in_layoffs
where changes > 0
order by changes desc;


 -- Which country experienced the fastest increase in layoffs -- Advanced Logic

select * 
from layoffs_staging2;


with yearly_laid_off as (
	select country,year(date) as dates,sum(total_laid_off) as totals
    from layoffs_staging2
    group by country,dates
),
increased_layoffs as (
	select country,dates,totals,
    lag(totals) over( partition by country order by dates) as prev_year,
    totals - lag(totals) over( partition by country order by dates) as increased_changes
    from yearly_laid_off
)
select * from
increased_layoffs
where increased_changes > 0
order by dates,increased_changes desc;



-- For each year, find the top 3 companies with the highest layoffs and display:
 -- Year
 -- Company
 -- Total layoffs that year
 -- Rank within the year


with yearly_layoffs as (
	select year(date) as dates,company,sum(total_laid_off) as total_layoff_per_year
    from layoffs_staging2
    group by company,dates
),
ranking_years as (
		select dates,company,total_layoff_per_year,
        dense_rank() over(partition by dates order by total_layoff_per_year desc) as ranking
        from yearly_layoffs
)
select * 
from ranking_years
where ranking <= 3
order by total_layoff_per_year;        


-- During which funding stages do layoffs occur most frequently

select * from
layoffs_staging2;


with stages as (
	select stage,count(*) as layoff_events,
    sum(total_laid_off) as total_lay_offs 
    from layoffs_staging2
    group by stage
),
layoffs_during_stages as (
	select stage,layoff_events,total_lay_offs,
    rank() over(order by layoff_events desc) as stage_ranked_by_layoff
    from stages
    order by stage_ranked_by_layoff
    )
select * from
layoffs_during_stages;

-- Which industries had the highest average layoff size 

select *  from
layoffs_staging2;


with industries as (
	select industry,count(*) as record_count,
    avg(cast(total_laid_off as float)) as avg_of_layoffs
    from layoffs_staging2
    group by industry
)
select * from
industries
order by avg_of_layoffs desc;    


-- Which companies appear repeatedly in layoff events 

with industries as (
	select company,count(distinct date) as record_count,
    sum(total_laid_off) as totals
    from layoffs_staging2
    group by company
)
select * from
industries
order by record_count desc; 


-- What were the worst months of the tech downturn 

select * from
layoffs_staging2;


with layoff_months as (
	select year(date) as years,month(date) as months,
    sum(total_laid_off) as layoffss
    from layoffs_staging2
    group by year(date),month(date)
)
select *,
	rank() over(order by layoffss desc) as layoff_order 
from
layoff_months;    


WITH layoff_months AS (
    SELECT 
        DATE_FORMAT(date, '%Y-%m') AS year_months,
        SUM(total_laid_off) AS layoffss
    FROM layoffs_staging2
    GROUP BY DATE_FORMAT(date, '%Y-%m')
)
SELECT *,
       RANK() OVER (ORDER BY layoffss DESC) AS layoff_order
FROM layoff_months
ORDER BY layoff_order;



-- Top company by layoffs in every country

select * from
layoffs_staging2;


with layoff_datas as (
	select country,count(*) as counts_of_country,company,sum(total_laid_off) as layoffss
    from layoffs_staging2
    group by country,company
 ),
top_companies_layoffs as (
	select country,counts_of_country,company,
    layoffss,
    row_number() over (partition by country order by layoffss desc) as highest_layoffs
    from layoff_datas
    )
select *
from top_companies_layoffs
where highest_layoffs = 1;    


WITH layoff_datas AS (
    SELECT 
        country,
        company,
        SUM(total_laid_off) AS layoffss
    FROM layoffs_staging2
    GROUP BY country, company
),
top_companies_layoffs AS (
    SELECT 
        country,
        company,
        layoffss,
        ROW_NUMBER() OVER (
            PARTITION BY country 
            ORDER BY layoffss DESC
        ) AS rn
    FROM layoff_datas
)
SELECT *
FROM top_companies_layoffs
WHERE rn = 1;


-- Which country had the most diversified layoffs across industries

with countries as (
	select country,count(distinct industry) as counts_of_industries,
    sum(total_laid_off) as layoffs
    from layoffs_staging2
    group by country
 ),
 ranking_countries as (
	select country,counts_of_industries,layoffs,
    dense_rank() over(order by counts_of_industries desc) as rankings
	from countries
    )
 select * from
 ranking_countries;


-- Create a leaderboard of companies by cumulative layoffs over time 

WITH cummulative_layoffs AS (
    SELECT 
        company,
        date,
        SUM(total_laid_off) OVER (
            PARTITION BY company 
            ORDER BY date
        ) AS cumulative
    FROM layoffs_staging2
),	
latest AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company 
               ORDER BY date DESC
           ) AS rn
    FROM cummulative_layoffs
)
SELECT 
    company,
    date,
    cumulative
FROM latest
WHERE rn = 1
ORDER BY cumulative DESC;

        
-- X ----- X -- ------- X----





