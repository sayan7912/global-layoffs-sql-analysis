-- Data Cleaning
select * from layoffs;

-- Remove duplicates
-- Standardize the Data
-- Null values or blank
-- Remove any unneccessary Columns 
-- Note 
-- we can't do it in raw/actual data so we need to make a staging data

CREATE TABLE layoffs_staging
LIKE layoffs;

insert into layoffs_staging
select * from
layoffs;

select * from layoffs_staging;

-- giving row numbers so that we can identify duplicates

SELECT *,
ROW_NUMBER() OVER(
    PARTITION BY company,industry,total_laid_off,percentage_laid_off, industry,`date`
) AS row_num
FROM layoffs_staging;

with remove_dup as (
	select *,
	ROW_NUMBER() OVER(
    PARTITION BY company,
    location,industry,total_laid_off,percentage_laid_off, industry,`date`,funds_raised_millions,stage,country
	) AS row_num
	FROM layoffs_staging
)
select * from remove_dup
where row_num > 1;   

select
* from layoffs_staging
where company = 'Cazoo'; 

-- now we can't directly delete duplicates so to do that we will create another 
-- table called layoffs stage2
drop table layoffs_staging2;

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select *  from layoffs_staging2;

insert into layoffs_staging2
	select *,
	ROW_NUMBER() OVER(
    PARTITION BY company,
    location,industry,total_laid_off,percentage_laid_off, industry,`date`,funds_raised_millions,stage,country
	) AS row_num
	FROM layoffs_staging;
    
    
select *  from layoffs_staging2
where row_num > 1;

set sql_safe_updates = 0;

Delete 
from layoffs_staging2
where row_num > 1;

select *  from layoffs_staging2
where row_num > 1;

-- standardizing data

-- 1 Trimming down company extra spaces 

select company
from layoffs_staging2;

select company,trim(company)
from layoffs_staging2;

update layoffs_staging2
set company = trim(company);

-- 2 formatting industry data

select industry 
from layoffs_staging2
order by 1;

select distinct industry 
from layoffs_staging2
where industry like 'Crypto%';

update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';

select industry
from layoffs_staging2;

-- fixing countries data 
-- we can also use trim(trailing '.' from country) -- advanced 

select distinct country
from layoffs_staging2
order by 1;

select distinct country
from layoffs_staging2
where country like 'United States%';

update layoffs_staging2
set country = 'United States'
where country like 'United States%'; 

select * from layoffs_staging2;

-- updating date column

select date from layoffs_staging2;

select date,
str_to_date(date,'%m/%d/%Y')
from layoffs_staging2;

update layoffs_staging2
set date = str_to_date(date,'%m/%d/%Y');

alter table layoffs_staging2
modify column `date` date;

select * from layoffs_staging2;

-- Getting rid of null values in industry and populating them

select * from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

select * from 
layoffs_staging2
where company = 'Airbnb';

select distinct industry 
from layoffs_staging2;

update layoffs_staging2
set industry = null
where industry = '';

select t1.industry,t2.industry
from layoffs_staging2 as t1
join layoffs_staging2 as t2       -- self join
	on t1.company = t2.company
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;    

update layoffs_staging2 t1
join layoffs_staging2 as t2
	on t1.company = t2.company
set t1.industry = t2.industry    
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;


select * 
from layoffs_staging2;

-- deleting null datas from total_laid_off and percentage_laid_off

select * from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

delete 
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null; 

-- deleting the row_num column 

alter table layoffs_staging2
drop column row_num;

select * from layoffs_staging2;

-- X -- X -- X ---- X ---



