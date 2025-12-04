SELECT * FROM world_life_expectancy.world_life_expectancy_project;

-- Finding duplicates in the table.
SELECT country, year, concat(country,year), count(concat(country,year))
FROM world_life_expectancy_project
GROUP BY country, year, concat(country,year)
HAVING count(concat(country,year)) > 1;

-- Finding the Row_ID of the duplicates.
SELECT *
FROM (SELECT row_id, concat(country,year), 
		ROW_NUMBER() OVER(PARTITION BY concat(country,year) ORDER BY row_id) AS row_num
		FROM world_life_expectancy_project) AS row_table
WHERE row_num > 1;

-- Deleting the duplicate rows.
DELETE FROM world_life_expectancy_project
WHERE row_id IN 
	(SELECT row_id
	FROM (SELECT row_id, concat(country,year), 
		ROW_NUMBER() OVER(PARTITION BY concat(country,year) ORDER BY row_id) AS row_num
		FROM world_life_expectancy_project) AS row_table
	WHERE row_num > 1);

-- -----------------------------------------------
-- Populating blank values in the `Status` column.
-- Checking which rows have a blank `Status` column.
SELECT *
FROM world_life_expectancy_project
WHERE status = '';

-- Checking for NULL values.
SELECT *
FROM world_life_expectancy_project
WHERE status IS NULL;

-- Finding all distinct values in the `Status` column.
SELECT DISTINCT(status)
FROM world_life_expectancy_project
WHERE status != '';

-- Showing countries that have the 'Developing' status.
SELECT DISTINCT(country)
FROM world_life_expectancy_project
WHERE status = 'Developing';

-- Using a JOIN to filter the table on itself to populate the 'Developing' countries.
UPDATE world_life_expectancy_project AS t1
JOIN world_life_expectancy_project AS t2
	ON t1.country = t2.country
SET t1.status = 'Developing'
WHERE t1.status = ''
AND t2.status != ''
AND t2.status = 'Developing';

-- Using the same query as above to populate the one remaining 'Developed' country.
UPDATE world_life_expectancy_project AS t1
JOIN world_life_expectancy_project AS t2
	ON t1.country = t2.country
SET t1.status = 'Developed'
WHERE t1.status = ''
AND t2.status != ''
AND t2.status = 'Developed';

-- --------------------------------------------------------
-- Populating blank values in the `Life expectancy` column.
-- Checking which rows have a blank `Life expectancy` column.
SELECT *
FROM world_life_expectancy_project
WHERE `Life expectancy` = '';

-- Populating the blank `Life expectancy` values by observing the pattern of the values per country 
-- and finding the average between the last and next years of the initial blank value.
SELECT country, year, `Life expectancy`
FROM world_life_expectancy_project;

-- Using a JOIN to filter the table on itself to find the blank `Life expectancy` values for each country,
-- and calculating the average value using the years before and after the missing value.
SELECT t1.country, t1.year, t1.`Life expectancy`,
	t2.country, t2.year, t2.`Life expectancy`,
    t3.country, t3.year, t3.`Life expectancy`,
    ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
FROM world_life_expectancy_project AS t1
JOIN world_life_expectancy_project AS t2
	ON t1.country = t2.country
    AND t1.year = t2.year - 1 #The year after the blank value.
JOIN world_life_expectancy_project AS t3
	ON t1.country = t3.country
    AND t1.year = t3.year + 1 #The year before the blank value.
WHERE t1.`Life expectancy` = '';

-- Updating the table to fill in the blank `Life expectancy` values with the calculations from the query above.
UPDATE world_life_expectancy_project AS t1
JOIN world_life_expectancy_project AS t2
	ON t1.country = t2.country
    AND t1.year = t2.year - 1 #The year after the blank value.
JOIN world_life_expectancy_project AS t3
	ON t1.country = t3.country
    AND t1.year = t3.year + 1 #The year before the blank value.
SET t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
WHERE t1.`Life expectancy` = '';

-- ---------------------------------
-- Observing the highest and lowest `Life expectancy` of each country.
SELECT country, MAX(`Life expectancy`), MIN(`Life expectancy`),
	ROUND(MAX(`Life expectancy`) - MIN(`Life expectancy`),1) AS Life_Increase_15_Years
FROM world_life_expectancy_project
GROUP BY country
HAVING MIN(`Life expectancy`) != 0 #Filtering out the 0 values.
AND MAX(`Life expectancy`) != 0
ORDER BY Life_Increase_15_Years DESC;

-- Observing the average life expectancy of each year.
SELECT year, ROUND(AVG(`Life expectancy`),1) AS Avg_Life_Exp
FROM world_life_expectancy_project
WHERE `Life expectancy` != 0 #Filtering out the 0 values.
AND `Life expectancy` != 0
GROUP BY year
ORDER BY year ASC;

-- --------------------------------------------
-- Observing a correlation between the average life expectancy and the average GDP of each country.
SELECT country, ROUND(AVG(`Life expectancy`),1) AS Avg_Life_Exp, ROUND(AVG(GDP),1) AS Avg_GDP
FROM world_life_expectancy_project
GROUP BY country
HAVING Avg_Life_Exp > 0 #Filtering out the 0 values.
AND Avg_GDP > 0
ORDER BY Avg_GDP DESC;
-- For most of the countries, if their average life expectancy is high, then their average GDP is also high.
-- The same conclusion can be said for a countries with a low average life expectancy, their GDP will also be low.

-- Using a CASE statement to categorize the life expectancy and GDP averages.
SELECT 
	SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) AS High_GDP_Count, #Number of rows that have a GDP greater than or equal to 1500.
    ROUND(AVG(CASE WHEN GDP >= 1500 THEN `Life expectancy` ELSE NULL END),1) AS High_GDP_Life_Expectancy, #Average life expectancy of all of the rows with a "high" GDP value.
    SUM(CASE WHEN GDP < 1500 THEN 1 ELSE 0 END) AS Low_GDP_Count, #Number of rows that have a GDP less than 1500.
    ROUND(AVG(CASE WHEN GDP < 1500 THEN `Life expectancy` ELSE NULL END),1) AS Low_GDP_Life_Expectancy #Average life expectancy of all of the rows with a "low" GDP value.
	#1500 is about the halfway point of the GDP values in this table.
FROM world_life_expectancy_project;
-- High GDP countries have a high average life expectancy.
-- Low GDP countries have a Low average life expectancy.

-- ------------------------------------------------------
-- Observing a correlation between the average life expectancy with the 'Developed'/'Developing' statuses.
SELECT status, COUNT(DISTINCT country), ROUND(AVG(`Life expectancy`),1)
FROM world_life_expectancy_project
GROUP BY status;
-- The amount of 'Developed' countries is a lot less than 'Developing' countries.
-- This difference in sample sizes should be taken into account when comparing the average life expectancy of 'Developed'/'Developing' countries.

-- Observing a correlation between the average life expectancy of each country with their BMI.
SELECT country, ROUND(AVG(`Life expectancy`),1) AS Life_Exp, ROUND(AVG(BMI),1) AS BMI
FROM world_life_expectancy_project
GROUP BY country
HAVING Life_Exp > 0
AND BMI > 0
ORDER BY BMI ASC;
-- The countries with the higher BMI seem to be more developed countries with a high life expectancy.
-- The countries with the lower BMI seem to be less developed countries with a low life expectancy. Probably due to lack of food and starvation in that country.

-- Observing a correlation between the adult mortality and life expectancy using a rolling total.
SELECT country, year, `Life expectancy`, `Adult Mortality`,
	SUM(`Adult Mortality`) OVER(PARTITION BY country ORDER BY year) AS Rolling_Total
FROM world_life_expectancy_project;
