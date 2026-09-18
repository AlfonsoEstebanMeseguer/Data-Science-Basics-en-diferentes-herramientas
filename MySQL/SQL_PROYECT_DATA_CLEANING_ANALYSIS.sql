-- DATA CLEANING
SELECT * FROM layoffs;
-- Copying data base to work with it
CREATE TABLE layoffs_staging LIKE layoffs;
SELECT * FROM layoffs_staging; -- Column Check
INSERT layoffs_staging SELECT * FROM layoffs; 
-- 1. Remove Duplicates
/**
Basically, what I do is, as in this case, not all tables come defined with a primary key/identifier.
Therefore, I assign ROW_NUMBER (which adds an incremental value for each row (1, 2, 3...)) to the combined partition of all (IMPORTANT) 
fields (PARTITION BY), and focus on these values ​​with OVER (the cell where ROW_NUMBER is applied).
The result is that with PARTITION BY, each set is placed into a group/bag, and for each bag there is a ROW_NUMBER counter.

Therefore, the logic of this BLOCK is to subsequently find if there are bags with > 1 elements (which will be repeated).
*/
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, percentage_laid_off,`date`)  AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, percentage_laid_off,`date`, stage, country,
funds_raised_millions)  AS row_num
FROM layoffs_staging
)
DELETE FROM duplicate_cte
WHERE row_num > 1;

/*
Second problem: with the WITH structure, what I do is create a temporary table (for the query), and then I try to delete it, but of course, 
that can't be done because the table doesn't physically exist. So we create another table and paste the data from the previous query into it, 
and then we delete all the rows where the "row_num" column has a value greater than 1.
*/

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
  `row_num` INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, percentage_laid_off,`date`, stage, country,
funds_raised_millions)  AS row_num -- Same name column
FROM layoffs_staging;

DELETE FROM layoffs_staging2 WHERE row_num > 1;
SELECT * FROM layoffs_staging2; -- Check no duplicates, I will remove the column "row_num" afterwards in .4

-- 2. Standarize the Data
SELECT DISTINCT industry FROM layoffs_staging2 ORDER BY 1; -- Same companies with diferent names.
UPDATE layoffs_staging2 SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';
SELECT DISTINCT country FROM layoffs_staging2 ORDER BY 1; -- Unite States & Unite States.
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) -- Check of de result
FROM layoffs_staging2 ORDER BY 1;
UPDATE layoffs_staging2 SET country = TRIM(TRAILING '.' FROM country) WHERE
country LIKE 'United States%';
SELECT DISTINCT country FROM layoffs_staging2 ORDER BY 1; -- Check final of countries

SELECT `date`, str_to_date(`date`,'%m/%d/%Y') -- Incorrect Format for dates (check)
FROM layoffs_staging2;
UPDATE layoffs_staging2 SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
ALTER TABLE layoffs_staging2 MODIFY COLUMN `date` DATE;

-- 3. Null Values or blank values
SELECT * FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off is NULl; -- CHECK NULLS 1
SELECT industry FROM layoffs_staging2 WHERE industry is NULL OR industry = ''; -- CHECK 2: BLANKS and NULLS
SELECT *  FROM layoffs_staging2 WHERE company = 'Airbnb'; -- 1 row with valid industry, second one with null value

SELECT * FROM layoffs_staging t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL; 

UPDATE layoffs_staging2 SET industry = NULL WHERE industry = ''; 

/*
With the block above, I find the intersection, or set, of ALL entities with the same 
company, but where one has a value in the industry and the other does not.

BUT BEWARE, THIS MAY CAUSE AN ERROR: Because handling BLANKS and NULL values ​​simultaneously can be problematic, 
the first thing I need to do is convert the BLANKS values ​​to NULL and then update.
*/

UPDATE layoffs_staging2 t1 
JOIN layoffs_staging2 t2 
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry =  '')
AND t2.industry IS NOT NULL;

-- 4. Remove Any Columns
ALTER TABLE layoffs_staging2 DROP COLUMN row_num; 
-- Table we created at the beginning to eliminate duplicates

-- 5. Exploratory Data Analysis (EDA)
/*
Let's look at some interesting data from the database, which could be considered relevant when looking for patterns or important information. 
First of all, let's look at the highest number of layoffs and percentages. We want to work with these columns because the data isn't entirely 
representative; there isn't a column that indicates the total number of employees a company has had to know if the total number of layoffs has 
been high. 1,000 layoffs at Google are not the same as 1,000 layoffs at Zillow.
*/
SELECT MAX(total_laid_off), MAX(percentage_laid_off) FROM layoffs_staging2;
/*
This query shows that a maximum of 12,000 layoffs were carried out, and the highest layoff rate was 100% of the company, meaning that the company 
disappeared. Let's see which companies these were, ordered by the number of layoffs.

The second query is the same but ordered by the amount of revenue the company had that year; this data is interesting.
*/
SELECT * FROM layoffs_staging2 WHERE percentage_laid_off = 1 ORDER BY total_laid_off DESC;
SELECT * FROM layoffs_staging2 WHERE percentage_laid_off = 1 ORDER BY funds_raised_millions DESC;
/*
Another interesting question would be to see which companies have the highest layoff rate,
(ORDER BY TWO for SUM(total_laid_off). The result we logically find is that we see
that the companies that lay off the most are the largest (Amazon, Microsoft, etc.), since in turn
they are the ones with the most employees.
*/
SELECT company, SUM(total_laid_off) FROM layoffs_staging2 GROUP BY company ORDER BY 2 DESC;
/* 
Another interesting query is the start date REGISTERED in this database of the most recent and the oldest company.
*/
SELECT MIN(`date`), MAX(`date`) FROM layoffs_staging2;
/* 
Based on the companies and the layoffs, we could check which sector has the highest rate of layoffs.
We can see that the consumer sector leads the list, which makes sense since most contracts
are short-term.
*/
SELECT industry, SUM(total_laid_off) FROM layoffs_staging2 GROUP BY industry ORDER BY 2 DESC;
/* 
Again, now with the country, the leader is the United States by a wide margin, which, again, makes 
sense since it is not only the largest country but also the most populated.
*/
SELECT country, SUM(total_laid_off) FROM layoffs_staging2 GROUP BY country ORDER BY 2 DESC;
/* 
Let's also look at the year with the most layoffs. The result is 2023. This data could make sense considering that:
in November 2022, the Chatgpt-3 boom brought about a change in the digital sector; by 2023, Chatgpt was very well-known and constantly growing;
perhaps digital companies laid off many programmers.
*/
SELECT YEAR(`date`), SUM(total_laid_off) FROM layoffs_staging2 GROUP BY YEAR(`date`) ORDER BY 1 DESC;
/* 
We previously looked at the number of layoffs, but that metric doesn't really make much sense in terms of productivity.
10,000 layoffs isn't a representative number for a global company. But which company laid off the most employees, considering its total number of employees? 
There are quite a few.
*/
SELECT company, AVG(percentage_laid_off) FROM layoffs_staging2 GROUP BY company ORDER BY 2 DESC;
/* 
Another interesting question would be to find out in which year-month combination the highest number of layoffs occurred. 
`SUBSTRING(`date`,1,7)` is the position of the month and year digits in the standard date format.

It can be seen that the highest number of layoffs per month occurred in the months following March 2023, which was when the COVID pandemic began.
*/
WITH Rolling_Total AS 
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2 
WHERE SUBSTRING(`date`,1,7) IS NOT NULL GROUP BY `MONTH` ORDER BY 1 ASC 
)
SELECT `MONTH`, total_off, SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total FROM Rolling_total;
/*
Based on the previous survey, let's examine which company laid off the most employees in a specific year.
META, AMAZON, and MICROSOFT, in 2022-2023, reinforce the theory of a surge in layoffs due to the integration of AI in the sector.
*/
SELECT company, YEAR(`date`), SUM(total_laid_off) FROM layoffs_staging2 GROUP BY company, YEAR(`date`) ORDER BY 3 DESC;
/*
Finally, to conclude this basic EDA analysis, let's look at the 5 companies that laid off the most people in each individual year. 
The first CTE(WITH) Company_Year is the previous query. The second CTE(WITH) is the ranking (from 1st to 2nd, etc.) across the years. 
Using partition by creates a partition for each year to rank companies by year, not by year. Finally, we have the top 5 years in the 
Company_Year_Rank ranking, which were:

Uber in 2020, with a total of 7,525 layoffs: pandemic -> people don't need vehicles
and Booking with 4,375 in the same year for the same reason.

DENSE_RANK creates a ranking; if two years have the same number of layoffs, they both rank the same. 
*/
WITH Company_Year (company,years,total_laid_off) AS 
(
SELECT company, YEAR(`date`), SUM(total_laid_off) FROM layoffs_staging2 GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS (
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking  
FROM Company_Year WHERE years IS NOT NULL ORDER BY Ranking)
SELECT * FROM Company_Year_Rank WHERE Ranking <= 5;

