-- Creating backups of the two tables that will be modified.
CREATE TABLE backup_us_household_income_statistics LIKE us_household_income_statistics;
INSERT INTO backup_us_household_income_statistics SELECT * FROM us_household_income_statistics;

CREATE TABLE backup_us_household_income LIKE us_household_income;
INSERT INTO backup_us_household_income SELECT * FROM us_household_income;

-- -----------------------------------------------------
SELECT * FROM us_project.us_household_income;
SELECT * FROM us_project.us_household_income_statistics;
-- -----------------------------------------------------

-- Renaming the 'id' column from the Statistics table.
ALTER TABLE us_project.us_household_income_statistics RENAME COLUMN `ï»¿id` TO `id`;

-- Identifying the duplicates in the Household Income table.
SELECT *
FROM (SELECT row_id, id, ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) AS row_num
		FROM us_household_income) AS duplicates
WHERE row_num > 1;

-- Deleting the duplicate rows.
DELETE FROM us_household_income
WHERE row_id IN (SELECT row_id
				FROM (SELECT row_id, id, ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) AS row_num
						FROM us_household_income) AS duplicates
				WHERE row_num > 1);
                
-- Identifying the duplicates in the Statistics table.
SELECT id, COUNT(id)
FROM us_household_income_statistics
GROUP BY id
HAVING COUNT(id) > 1;
-- No duplicates found.

-- ----------------------------------------------------------
-- Finding spelling and capitalization errors in the `State_Name` column of the Household Income table.
SELECT DISTINCT state_name
FROM us_household_income;
-- Spelling errors were identified.

-- Fixing the spelling error.
UPDATE us_project.us_household_income
SET State_Name = 'Georgia'
WHERE State_Name = 'georia';

-- Fixing the capitalization error.
UPDATE us_project.us_household_income
SET State_Name = 'Alabama'
WHERE State_Name = 'alabama';

-- -------------------------------------------------------
-- Checking if the `State_ab` column is consistent.
SELECT DISTINCT State_ab
FROM us_household_income;

-- ------------------------------------------------------------
-- Checking for and populating blank values in the `Place` column.
SELECT *
FROM us_household_income
WHERE Place = '';

UPDATE us_project.us_household_income
SET Place = 'Autaugaville'
WHERE County = 'Autauga County'
AND City = 'Vinemont';

-- ---------------------------------------------------
-- Identifying and fixing errors in the `Type` column.
SELECT type, COUNT(type)
FROM us_household_income
GROUP BY type;

UPDATE us_project.us_household_income
SET Type = 'Borough'
WHERE Type = 'Boroughs';

-- -----------------------------------------------------
-- Comparing the land and water areas of each state.
-- Top 10 states with the largest land area:
SELECT state_name, SUM(ALand), SUM(AWater)
FROM us_household_income
GROUP BY state_name
ORDER BY SUM(ALand) DESC
LIMIT 10;

-- Top 10 states with the largest water area:
SELECT state_name, SUM(ALand), SUM(AWater)
FROM us_household_income
GROUP BY state_name
ORDER BY SUM(AWater) DESC
LIMIT 10;

-- --------------------------------------------------
-- Joining the two tables together.
-- Identifying missing information from the Household Income table that has no ID matches with the Statistics table.
SELECT *
FROM us_project.us_household_income AS hi
RIGHT JOIN us_project.us_household_income_statistics AS histat
	ON hi.id = histat.id
WHERE hi.id IS NULL;

-- The rows with the NULL values from the query above will not be used.
-- Filtering out the Mean values that equal to 0 for future calculations.
SELECT *
FROM us_project.us_household_income AS hi
INNER JOIN us_project.us_household_income_statistics AS histat
	ON hi.id = histat.id
WHERE Mean != 0;

-- Observing and comparing the average Mean and Median of each state.
SELECT hi.State_Name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income AS hi
INNER JOIN us_project.us_household_income_statistics AS histat
	ON hi.id = histat.id
WHERE Mean != 0
GROUP BY hi.State_Name
ORDER BY hi.State_Name ASC;

-- Finding a correlation between the neighbourhood type and the average Mean and Median household incomes.
SELECT Type, COUNT(Type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income AS hi
INNER JOIN us_project.us_household_income_statistics AS histat
	ON hi.id = histat.id
WHERE Mean != 0
GROUP BY Type
ORDER BY 4 DESC;

-- Comparing the average Mean and Median of household income within each City.
SELECT hi.State_Name, City, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income AS hi
INNER JOIN us_project.us_household_income_statistics AS histat
	ON hi.id = histat.id
GROUP BY hi.State_Name, City
ORDER BY ROUND(AVG(Mean),1) DESC;






















