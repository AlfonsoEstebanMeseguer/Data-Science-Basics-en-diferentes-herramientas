Before we begin, it's important to note that this project is a simple simulation. Cleaning a larger and/or more complex database would obviously require more advanced techniques and customized tools. However, in this project, I aim to give SQL a real-world application and enrich raw data. In this regard, the EDA analysis focuses on extracting relevant information through various queries, ranging from simple to intermediate operations. We don't generate graphs or statistics (such as quantiles), and since our goal isn't to solve a specific problem but rather to enrich data, we can't target the EDA in that direction.
# Data Source
This dataset is a compilation from **Layoffs.fyi**, a real-time tracker that has become the industry standard for monitoring tech layoffs. The information is primarily drawn from:

1. **Public Reports**: Press releases from the companies themselves.

2. **Business News**: Bloomberg, TechCrunch, Wall Street Journal.

3. **Government Records**: WARN Act notifications (in the US) that require companies to report mass layoffs.

**386,379 documented layoffs** were recorded during this period.

The file contains raw data; much of it needs to be standardized, and some data, such as NULL values, requires processing. Many companies announced layoffs without specifying the exact number, leaving some fields blank or with a null value.
# Data Cleaning
The first task is to transfer all the data to a new data table; we don't want to work with the raw data in case we modify or corrupt it. Also, it's always a good practice to have a backup.
```sql
SELECT * FROM layoffs;
-- Copying data base to work with it
CREATE TABLE layoffs_staging LIKE layoffs;

-- LIKE here creates a table with the SAME columns as the original table, but without data.

SELECT * FROM layoffs_staging; -- Column Check
INSERT layoffs_staging SELECT * FROM layoffs; -- ALL INSERTS
```
## Removing duplicates
To find if this table contains duplicate values, I will group the data by the set of the most representative columns (`OVER(PARTITION BY...`) and have a counter `ROW_NUMBER()` iterate over each set. If it finds two rows with the same set, the counter will increment to two. After this operation, if a query finds a counter `>1`, that information would be duplicated.
```sql
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, percentage_laid_off,`date`)  AS row_num
FROM layoffs_staging;
```
As you can see, there are indeed columns with a value greater than 1. We cannot use `DELETE` directly on this query because the `row_num` column is created during this operation. Let's try using `WITH`.
```sql
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, percentage_laid_off,`date`, stage, country,
funds_raised_millions)  AS row_num
FROM layoffs_staging
)
DELETE FROM duplicate_cte
WHERE row_num > 1;
```
This block generates an error due to the nature of the WITH operator, as it creates a CTE/temporary table, not a physical table. The best way to address this is to create another physical table with this additional column, so that insert and delete operations can be performed later.
```sql
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
```
## Standarized data
This database has some "flaws" that, when working with the data by iterating in the code editor, may result in missing data, misidentified data, or other types of errors. In this section, I will address these common errors.

==Important==: It's worth noting that this data table is large. Attempting standardization without prior knowledge may not resolve all the issues. In this case, I am aware of some of the flaws that we will discuss later, but there is no way to identify ALL the flaws in a large table.
```sql
SELECT DISTINCT industry FROM layoffs_staging2 ORDER BY 1;
```
This query shows that there are two names with the same meaning but different spellings: **Crypto**, **Crypto Currency**, and **CryptoCurrency**. Since they actually refer to the same sector, we will unify them:
```sql
UPDATE layoffs_staging2 SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';
```
Let's look at more errors; If we perform the following query:
```sql
SELECT DISTINCT country FROM layoffs_staging2 ORDER BY 1;
```
We see that the same case is repeated for "**United States**" and "**United States.**". We unify values ​​again:
```sql
UPDATE layoffs_staging2 SET country = TRIM(TRAILING '.' FROM country) WHERE
country LIKE 'Unite States%';
```
`TRIM` removes unwanted characters. If it's empty, it removes extra spaces, but if we specify something like characters, it removes them. `TRAILING` is an advanced function; it basically tells `TRIM` to look at the end of the string found with `LIKE`.

Finally, during some previous queries, we might have noticed that the table refers to dates; however, its format is incorrect. It's not using the standard `date` format. Let's format it:
```sql
UPDATE layoffs_staging2 SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
ALTER TABLE layoffs_staging2 MODIFY COLUMN `date` DATE;
```
# Removing NULL values
The first thing we're going to do is check for any null values. To do this, we'll check some of the fields. We'll look at those related to layoffs, since, as mentioned earlier in this report, some companies didn't report data related to layoffs.
```sql
SELECT * FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off is NULl; -- CHECK NULLS 1
SELECT industry FROM layoffs_staging2 WHERE industry is NULL OR industry = ''; 
-- CHECK 2: BLANKS and NULLS
```
I accidentally noticed a case with the company **AirBnB**. It turns out that the **Industry** field appeared with the value **Travel** in some rows, but in others it appeared with the value NULL or BLANKET. This error is solvable because, logically, we know that Airbnb always belongs to that industry; this data wouldn't affect the rest of the data table. Since there are many companies registered in this table, we'll fix it by offering a general solution:
```sql
SELECT * FROM layoffs_staging 2 t1
JOIN layoffs_staging2 t2 
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry =  '')
AND t2.industry IS NOT NULL -- Check

/*
The block above finds the intersection, or set, of ALL entities with the same company, but where one has a value in the industry and the other does not.

THIS MIGHT CAUSE AN ERROR: Because processing BLANKS and NULL values ​​simultaneously can be problematic. Therefore, the first thing we need to do is convert the BLANKS values ​​to NULL and then update, as this is good practice.
*/
UPDATE layoffs_staging2 SET industry = NULL WHERE industry = ''; 

UPDATE layoffs_staging2 t1 
JOIN layoffs_staging2 t2 
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry =  '')
AND t2.industry IS NOT NULL
```
It might be best not to delete the remaining null values ​​because if one row has data but the next row has a **NULL** value, we could be deleting the entire column (which contains information even if it's only from a few rows). It's also not advisable to replace the NULL value with 0 or other values, as this could affect other queries (averages, counts, etc.).
# Remove redundant columns
Finally, we remove the column we created to eliminate duplicates since we are no longer interested in it.
```sql
ALTER TABLE layoffs_staging2 DROP COLUMN row_num; -- Table we created at the beginning to eliminate duplicates
```
# Exploratory Data Analysis
Let's look at some interesting data from the database, which could be considered relevant when looking for patterns or important information. 

First of all, let's look at the highest number of layoffs and percentages. We want to work with these columns because the data isn't entirely representative; there isn't a column that indicates the total number of employees a company has had to know if the total number of layoffs has been high. 1,000 layoffs at Google are not the same as 1,000 layoffs at Zillow.

```sql
SELECT MAX(total_laid_off), MAX(percentage_laid_off) FROM layoffs_staging2;
```
This query shows that a maximum of 12,000 layoffs were carried out, and the highest layoff rate was 100% of the company, meaning that the company 
disappeared. Let's see which companies these were, ordered by the number of layoffs.

The second query is the same but ordered by the amount of revenue the company had that year; this data is interesting.
```sql
SELECT * FROM layoffs_staging2 WHERE percentage_laid_off = 1 ORDER BY total_laid_off DESC;
SELECT * FROM layoffs_staging2 WHERE percentage_laid_off = 1 ORDER BY funds_raised_millions DESC;
```
Another interesting question would be to see which companies have the highest layoff rate,
(ORDER BY TWO for SUM(total_laid_off). The result we logically find is that we see
that the companies that lay off the most are the largest (Amazon, Microsoft, etc.), since in turn
they are the ones with the most employees.
```sql
SELECT company, SUM(total_laid_off) FROM layoffs_staging2 GROUP BY company ORDER BY 2 DESC;
```
Another interesting query is the start date REGISTERED in this database of the most recent and the oldest company.
```sql
SELECT MIN(`date`), MAX(`date`) FROM layoffs_staging2;
```
Based on the companies and the layoffs, we could check which sector has the highest rate of layoffs. We can see that the consumer sector leads the list, which makes sense since most contracts
are short-term.
```sql
SELECT industry, SUM(total_laid_off) FROM layoffs_staging2 GROUP BY industry ORDER BY 2 DESC;
```
Again, now with the country, the leader is the United States by a wide margin, which, again, makes 
sense since it is not only the largest country but also the most populated.
```sql
SELECT country, SUM(total_laid_off) FROM layoffs_staging2 GROUP BY country ORDER BY 2 DESC;
```
Let's also look at the year with the most layoffs. The result is 2023. This data could make sense considering that:

in November 2022, the Chatgpt-3 boom brought about a change in the digital sector; by 2023, Chatgpt was very well-known and constantly growing;
perhaps digital companies laid off many programmers.
```sql
SELECT YEAR(`date`), SUM(total_laid_off) FROM layoffs_staging2 GROUP BY YEAR(`date`) ORDER BY 1 DESC;
```
We previously looked at the number of layoffs, but that metric doesn't really make much sense in terms of productivity.

10,000 layoffs isn't a representative number for a global company. But which company laid off the most employees, considering its total number of employees? 
There are quite a few.
```sql
SELECT company, AVG(percentage_laid_off) FROM layoffs_staging2 GROUP BY company ORDER BY 2 DESC;
```
Another interesting question would be to find out in which year-month combination the highest number of layoffs occurred. 

`SUBSTRING(`date`,1,7)` is the position of the month and year digits in the standard date format.

It can be seen that the highest number of layoffs per month occurred in the months following March 2023, which was when the COVID pandemic began.
```sql
WITH Rolling_Total AS 
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2 
WHERE SUBSTRING(`date`,1,7) IS NOT NULL GROUP BY `MONTH` ORDER BY 1 ASC 
)
SELECT `MONTH`, total_off, SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total FROM Rolling_total;
```
Based on the previous survey, let's examine which company laid off the most employees in a specific year.

META, AMAZON, and MICROSOFT, in 2022-2023, reinforce the theory of a surge in layoffs due to the integration of AI in the sector.
```sql
SELECT company, YEAR(`date`), SUM(total_laid_off) FROM layoffs_staging2 GROUP BY company, YEAR(`date`) ORDER BY 3 DESC;
```
Finally, to conclude this basic EDA analysis, let's look at the 5 companies that laid off the most people in each individual year. 

The first CTE(WITH) Company_Year is the previous query. The second CTE(WITH) is the ranking (from 1st to 2nd, etc.) across the years. 

Using partition by creates a partition for each year to rank companies by year, not by year. Finally, we have the top 5 years in the 

Company_Year_Rank ranking, which were:

Uber in 2020, with a total of 7,525 layoffs: pandemic -> people don't need vehicles
and Booking with 4,375 in the same year for the same reason.

DENSE_RANK creates a ranking; if two years have the same number of layoffs, they both rank the same. 
```sql
WITH Company_Year (company,years,total_laid_off) AS 
(
SELECT company, YEAR(`date`), SUM(total_laid_off) FROM layoffs_staging2 GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS (
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking  
FROM Company_Year WHERE years IS NOT NULL ORDER BY Ranking)
SELECT * FROM Company_Year_Rank WHERE Ranking <= 5;
```



