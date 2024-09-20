# US HOUSEHOLD INCOME DATA CLEANING

#Taking a look at tables to make sure that columns were imported correctly
SELECT * 
FROM us_project.us_household_income;

SELECT * 
FROM us_project.us_house_hold_income_statistics;

ALTER TABLE us_house_hold_income_statistics
RENAME COLUMN `ï»¿id` TO `id`;




#Looking at the count of rows for each table. About 200 rows were not imported out from household income table out of 32k
SELECT COUNT(id)
FROM us_project.us_household_income;

SELECT COUNT(id) 
FROM us_project.us_house_hold_income_statistics;



#Looking for duplicates in household income table
SELECT id, COUNT(id) 
FROM us_project.us_household_income
GROUP BY id
HAVING COUNT(id) > 1;




#Removing Duplicate ID's
SELECT *
FROM (
SELECT 
	row_id,
	id,
    ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) AS row_num
FROM us_project.us_household_income) AS duplicates
WHERE
	row_num > 1;

DELETE FROM us_household_income
WHERE row_id IN (
	SELECT row_id
	FROM
		(SELECT 
			row_id,
			id,
			ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) AS row_num
		FROM us_project.us_household_income) AS duplicates
	WHERE
		Row_num > 1);

#Verifying Deletion        
SELECT id, COUNT(id) 
FROM us_house_hold_income_statistics
GROUP BY id
HAVING COUNT(id) > 1;










#Looking at spelling variability
SELECT DISTINCT State_Name
FROM us_household_income;

UPDATE us_household_income
SET State_Name = 'Georgia'
WHERE State_Name = 'georia';

UPDATE us_household_income
SET State_Name = 'Alabama'
WHERE State_Name = 'alabama';

SELECT DISTINCT(state_ab)
FROM us_household_income;












#Looking for any blanks in the data
SELECT *
FROM us_household_income
WHERE
	Place = ''
ORDER BY 1;


SELECT *
FROM us_household_income
WHERE
	County = 'Autauga County'
ORDER BY 1;


UPDATE us_household_income
SET Place = 'Autaugaville'
WHERE
	County = 'Autauga County'
    AND City = 'Vinemont';




#Looking for Variabilities in Type column    
SELECT 
	Type, 
	COUNT(Type)
FROM us_household_income
GROUP BY 
	Type;
    
UPDATE us_household_income
SET Type = 'Borough'
WHERE
	Type = 'Boroughs';



SELECT *
FROM us_household_income;


SELECT 
   ALand,
   AWater
FROM us_household_income
WHERE
	ALand IN (0,'',NULL) OR
    Awater IN (0,'',NULL);
    
    
### EXPLORATORY DATA ANALYSIS ###

#When we are exploring the data we are trying to find trends, patterns, insights into the data.
#I'm noticing there's not date fields, so no time series data. So probably won't be looking for trends over time

#We can look at some information at the state level through, like size of each stat, average city size. etc.
#We can also join to the statistics table and look at mean and median incomes

#Let's start with some simple stuff and work out way to joining the tables

#Lets look at columns we want to work with
SELECT
	State_Name,
    ALand,
    AWater
FROM
	us_household_income;

#Total size of the land from smallest to largest
SELECT 
	State_Name,
    SUM(ALand), 
	SUM(AWater)
FROM us_household_income
GROUP BY State_Name
ORDER BY 2 DESC;

#Just glancing at these results they look pretty accurate. Texas being the largest

#Now let's say we just want to look at the top 10 largest states by water. These will be states that have a lot of lakes or rivers
SELECT 
	State_Name,
    SUM(ALand), 
	SUM(AWater)
FROM us_household_income
GROUP BY State_Name
ORDER BY 3 DESC
LIMIT 10;

#I expected(Michigan, Florida, Minnesota to be in there - also Alaska, but I didn't expect Texas or North Carolina to be in the top 10 - interesting

#Now that's interesting, but this is a primarily an income dataset. Let's join the tables together and look at that

SELECT * 
FROM us_household_income u
INNER JOIN us_house_hold_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0;


#Now let's filter on the columns we want
SELECT u.State_Name, County, Type, `Primary`, Mean, Median 
FROM us_household_income u
INNER JOIN us_house_hold_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0;

#First, let's look at just the state level the average mean and median
#Let's start to look at the top 10 lowest avg household income
SELECT u.State_Name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income u
INNER JOIN us_house_hold_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY
	u.State_Name
ORDER BY 2
LIMIT 10;


#Now let's do highest avg household income
SELECT u.State_Name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income u
INNER JOIN us_house_hold_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY
	u.State_Name
ORDER BY 2 DESC
LIMIT 10;

#Now we are taking a look at the type of area avg household income
SELECT 
	Type, 
	COUNT(Type), 
	ROUND(AVG(Mean),1), 
    ROUND(AVG(Median),1) 
FROM us_household_income u
INNER JOIN us_house_hold_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY
	Type
ORDER BY
	3 DESC;
    
    
#Now we are looking at the Median household income by type of area    
SELECT 
	Type, 
	COUNT(Type), 
    ROUND(AVG(Mean),1), 
    ROUND(AVG(Median),1) 
FROM us_household_income u
INNER JOIN us_house_hold_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY
	Type
ORDER BY
	4 DESC;



#I wanted to see what the state had these Community areas
SELECT *
FROM us_household_income
WHERE Type = 'Community';

#So it looks like PR would have the lowest AVG household income which makes sense

#I really want to stick with type of areas that has more data so I'm filtering out those that have less than 100 inputs
SELECT Type, COUNT(Type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1) 
FROM us_household_income u
JOIN us_house_hold_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY
	Type
HAVING 
	COUNT(Type) > 100
ORDER BY
	4 DESC;


#Let's take a look at the highest mean income by city
SELECT 
	u.State_Name, 
	City, 
    ROUND(AVG(Mean),1)
FROM us_household_income u
JOIN us_house_hold_income_statistics us
	ON u.id = us.id
GROUP BY
	u.State_Name,
    City
ORDER BY
	3 DESC;