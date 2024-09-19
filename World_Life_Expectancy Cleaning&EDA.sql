# World Life Expectancy Project (Data Cleaning)

SELECT * 
FROM world_life_expectancy.world_life_expectancy
;

## REMOVING DUPLICATES ##

#We should have a one entry for each year so lets see if there are duplicates
SELECT
	COUNTRY,
    YEAR,
    CONCAT(COUNTRY,YEAR)
FROM
	world_life_expectancy;
    
    
#Lets use Count to see if there are duplicates for our concat    
SELECT
	COUNTRY,
    YEAR,
    CONCAT(COUNTRY,YEAR),
    COUNT(CONCAT(COUNTRY,YEAR))
FROM
	world_life_expectancy
GROUP BY
	COUNTRY,
    YEAR,
    CONCAT(COUNTRY,YEAR);
    
    
    
#Lets Filter for the duplicates
SELECT
	COUNTRY,
    YEAR,
    CONCAT(COUNTRY,YEAR),
    COUNT(CONCAT(COUNTRY,YEAR))
FROM
	world_life_expectancy
GROUP BY
	COUNTRY,
    YEAR,
    CONCAT(COUNTRY,YEAR)
HAVING
	COUNT(CONCAT(COUNTRY,YEAR)) > 1;
    


#Lets now assign a row number to the Concat and partition by it
SELECT 
	Row_ID,
    CONCAT(COUNTRY,YEAR),
    ROW_NUMBER() OVER(PARTITION BY CONCAT(COUNTRY,YEAR) ORDER BY CONCAT(COUNTRY,YEAR)) AS row_num
FROM world_life_expectancy.world_life_expectancy
;

#Now we will filter on the row number assigned
SELECT *
FROM
	(SELECT 
	Row_ID,
    CONCAT(COUNTRY,YEAR),
    ROW_NUMBER() OVER(PARTITION BY CONCAT(COUNTRY,YEAR) ORDER BY CONCAT(COUNTRY,YEAR)) AS row_num
	FROM world_life_expectancy.world_life_expectancy) AS row_table
WHERE
	Row_num > 1;
    
#Deleting the duplicate rows
DELETE FROM world_life_expectancy
WHERE row_id IN (
	SELECT row_id
	FROM
		(SELECT 
		Row_ID,
		CONCAT(COUNTRY,YEAR),
		ROW_NUMBER() OVER(PARTITION BY CONCAT(COUNTRY,YEAR) ORDER BY CONCAT(COUNTRY,YEAR)) AS row_num
		FROM world_life_expectancy.world_life_expectancy) AS row_table
	WHERE
		Row_num > 1
        );




## ADDRESSING GAPS IN DATA##

#Looking at all the rows that have a status that is blank
SELECT * 
FROM world_life_expectancy
WHERE
	status = '';

#Looking at what types of status' there are    
SELECT 
	DISTINCT(status) 
FROM world_life_expectancy
WHERE
	status <> '';
    
#Looking at all the Developing countries    
SELECT 
DISTINCT(country)
FROM world_life_expectancy
WHERE
	status = 'Developing';

#Updating blank status' where countries are Developing
UPDATE world_life_expectancy
SET status = 'Developing'
WHERE country IN (
	SELECT DISTINCT(country)
	FROM world_life_expectancy
	WHERE status = 'Developing'
    );

#Above update was not successful I will have to try another way

#We will be joining the table to itself to update the status' to developing   
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.country = t2.country
SET t1.status = 'Developing'
WHERE t1.status = ''
AND t2.status <> ''
AND t2.status = 'Developing';


#Checking to see if all status have been updated
SELECT * 
FROM world_life_expectancy
WHERE
	status = '';
    
#Only 1 status is needs updating but I want to see what the status US is 
SELECT * 
FROM world_life_expectancy
WHERE
	country = 'United States of America';
    

#Updating the status for developed countries that are blank
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.country = t2.country
SET t1.status = 'Developed'
WHERE t1.status = ''
AND t2.status <> ''
AND t2.status = 'Developed';

#Checking to see if there is any Nulls for status
SELECT * 
FROM world_life_expectancy
WHERE
	status IS NULL;


SELECT * 
FROM world_life_expectancy;

#Looking at life expectancy data gaps
SELECT * 
FROM world_life_expectancy
WHERE
	`Life expectancy` = '';
   
   
#Getting the columns I want to work with
SELECT Country, Year, `Life expectancy`
FROM world_life_expectancy
WHERE
	`Life expectancy` = '';
    
#Because there are few missing data points and seeing a trend I will sum up the previous year and following year and then take the avg to fill in gap

#First I will need to make a couple self joins to ensure that I make the table I need to get the aggregation for the gaps
SELECT 
	t1.Country, 
    t1.Year, 
	t1.`Life expectancy`,
    t2.Country, 
    t2.Year, 
    t2.`Life expectancy`,
	t3.Country, 
    t3.Year, 
    t3.`Life expectancy`,
    ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
    AND t1.YEAR = t2.YEAR - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
    AND t1.YEAR = t3.YEAR + 1
WHERE
	t1.`Life expectancy` = '';
    
#Now I need to update the table with the avg calculated using another self join
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
    AND t1.YEAR = t2.YEAR - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
    AND t1.YEAR = t3.YEAR + 1
SET t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
WHERE t1.`Life expectancy` = '';


SELECT * 
FROM world_life_expectancy;








### World Life Expectancy Project (Exploratory Data Analysis) ###

#When we are exploring the data we are trying to find trends, patterns, insights into the data.
#I'm noticing there's are some dates, so I can look at some data over time

#We can look at some information at the per country, like GDP, BMI... etc.

#Let's start with some life expectancy then work our way to BMI and then Adult Mortality

SELECT * 
FROM world_life_expectancy;




#Let's take a look at Life Expectancy strides made by each country over the last 15 years
SELECT 
	Country, 
	MIN(`Life expectancy`), 
    MAX(`Life expectancy`),
    ROUND(MAX(`Life expectancy`) - MIN(`Life expectancy`),1) AS Life_Increase_15_Years
FROM world_life_expectancy
GROUP BY country
HAVING 
	MIN(`Life expectancy`) <> 0
	AND MAX(`Life expectancy`) <> 0
ORDER BY Life_Increase_15_Years DESC;





#Lets look at AVG worldly life expectancy per year 
SELECT 
	YEAR, 
	ROUND(AVG(`Life expectancy`),2)
FROM world_life_expectancy
WHERE 
	`Life expectancy` <> 0
	AND `Life expectancy` <> 0
GROUP BY
	YEAR
ORDER BY YEAR;



SELECT * 
FROM world_life_expectancy;

#Lets look at AVG Life Expectancy vs. AVG GDP
SELECT 
	Country,
    ROUND(AVG(`Life expectancy`),1) AS Life_Exp,
    ROUND(AVG(GDP),1) AS GDP
FROM world_life_expectancy
GROUP BY
	Country
HAVING
	Life_Exp > 0
    AND GDP > 0
ORDER BY GDP DESC;


#Lets look at the AVG life expectancy of High GDP countries vs Low GDP Countries
SELECT 
	SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) High_GDP_Count,
    AVG(CASE WHEN GDP >= 1500 THEN `Life expectancy` ELSE NULL END) High_GDP_Life_Exp,
    SUM(CASE WHEN GDP <= 1500 THEN 1 ELSE 0 END) Low_GDP_Count,
    AVG(CASE WHEN GDP <= 1500 THEN `Life expectancy` ELSE NULL END) Low_GDP_Life_Exp
FROM world_life_expectancy;





#Wanted to explore the AVG life expectancy of Developed vs Developing countries
SELECT Status, ROUND(AVG(`Life expectancy`),1)
FROM world_life_expectancy
GROUP BY Status;




#Checking amount of countries in each Developed and Developing country
SELECT 
	Status, 
	COUNT(DISTINCT Country),
    ROUND(AVG(`Life expectancy`),1)
FROM world_life_expectancy
GROUP BY Status;






#Lets compare Life Expectancy to BMI
SELECT 
	Country,
    ROUND(AVG(`Life expectancy`),1) AS Life_Exp,
    ROUND(AVG(BMI),1) AS BMI
FROM world_life_expectancy
GROUP BY Country
HAVING
	Life_Exp > 0
    AND BMI > 0
ORDER BY BMI DESC;







#Looking at Sum of deaths year over year
SELECT
	Country,
    Year,
    `Life expectancy`,
    `Adult Mortality`,
    SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY YEAR) AS Rolling_Total
FROM world_life_expectancy;







#Looking at United States of America deaths
SELECT
	Country,
    Year,
    `Life expectancy`,
    `Adult Mortality`,
    SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY YEAR) AS Rolling_Total
FROM world_life_expectancy
WHERE Country LIKE '%United%'