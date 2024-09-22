### CLEANING OF DATA ###

---DUPLICATING DAILYACTIVITY TABLE---
CREATE TABLE `capstone-417722.Bellabeat.copy_dailyActivity` AS
SELECT
  *
FROM
  `capstone-417722.Bellabeat.dailyActivity`;

---CONVERTING ID FROM INT TO STRING AND ADDING DAYS OF WEEK---

CREATE OR REPLACE TABLE `capstone-417722.Bellabeat.copy_dailyActivity` AS
SELECT
  SAFE_CAST(Id AS STRING) AS Id,
  ActivityDate,
  FORMAT_DATE('%A', ActivityDate) AS DayOfWeek,
  TotalSteps,
  TotalDistance,
  TrackerDistance,
  LoggedActivitiesDistance,
  VeryActiveDistance,
  ModeratelyActiveDistance,
  LightActiveDistance,
  SedentaryActiveDistance,
  VeryActiveMinutes,
  FairlyActiveMinutes,
  LightlyActiveMinutes,
  SedentaryMinutes,
  Calories
FROM
  `capstone-417722.Bellabeat.copy_dailyActivity`;

---CHECKING FOR DUPLICATES AND NULLS---


SELECT
  Id,
  ActivityDate,
  COUNT(*) AS num_occurrances
FROM
  `capstone-417722.Bellabeat.copy_dailyActivity`
GROUP BY
  Id,
  ActivityDate
HAVING
  COUNT(*) > 1;

SELECT
  COUNT(*) AS total_rows,
  COUNT(Id) AS non_null_Id,
  COUNT(ActivityDate) AS non_null_ActivityDate,
  COUNT(TotalSteps) AS non_null_TotalSteps,
  COUNT(TotalDistance) AS non_null_TotalDistance,
  COUNT(TrackerDistance) AS non_null_TrackerDistance,
  COUNT(LoggedActivitiesDistance) AS non_null_LoggedActivitiesDistance,
  COUNT(VeryActiveDistance) AS non_null_VeryActiveDistance,
  COUNT(ModeratelyActiveDistance) AS non_null_ModeratelyActiveDistance,
  COUNT(LightActiveDistance) AS non_null_LightActiveDistance,
  COUNT(SedentaryActiveDistance) AS non_null_SedentaryActiveDistance,
  COUNT(VeryActiveMinutes) AS non_null_VeryActiveMinutes,
  COUNT(FairlyActiveMinutes) AS non_null_FairlyActiveMinutes,
  COUNT(LightlyActiveMinutes) AS non_null_LightlyActiveMinutes,
  COUNT(SedentaryMinutes) AS non_null_SedentaryMinutes,
  COUNT(Calories) AS non_null_Calories
FROM
  `capstone-417722.Bellabeat.copy_dailyActivity`;








### EDA OF DAILYACTIVITY TABLE ###

--- LOOKING AT DIFFERANCE BETWEEN TOTALDISTANCE AND TRACKERDISTANCE---
SELECT
  *
FROM
  `capstone-417722.Bellabeat.copy_dailyActivity`
WHERE
  TotalDistance <> TrackerDistance;

SELECT
  Id,
  ActivityDate,
  SUM(TotalDistance-TrackerDistance) AS diffOfDistances
FROM
  `capstone-417722.Bellabeat.copy_dailyActivity`
GROUP BY
  Id,
  ActivityDate
HAVING
  SUM(TotalDistance-TrackerDistance) > 1;




---ROLLING SUM OF STEPS---

SELECT
  Id,
  ActivityDate,
  DayOfWeek,
  TotalSteps,
  SUM(TotalSteps) OVER(PARTITION BY Id ORDER BY Id, ActivityDate) AS SumOfSteps,
  Calories
FROM
  `capstone-417722.Bellabeat.copy_dailyActivity`;



---CALORIES BY DAY---

SELECT
  DayOfWeek,
  AVG(Calories) AS AvgCalBurnByDay
FROM
  `Bellabeat.copy_dailyActivity`
GROUP BY
  DayOfWeek

--- SET ACTIVITY RATING PER ID---

SELECT
  Id,
  AVG(TotalSteps) AS avgTotalSteps,
CASE
  WHEN AVG(TotalSteps) >= 12000 THEN 'HIGHLYACTIVE'
  WHEN AVG(TotalSteps) >= 6000 THEN 'MODERATELYACTIVE'
  WHEN AVG(TotalSteps) < 6000 THEN 'SEDENTARY'
END AS activityRating
FROM
  `capstone-417722.Bellabeat.copy_dailyActivity`
GROUP BY
  Id;

WITH activityRatings AS
(
  SELECT
  Id,
  AVG(TotalSteps) AS avgTotalSteps,
CASE
  WHEN AVG(TotalSteps) >= 12000 THEN 'HIGHLYACTIVE'
  WHEN AVG(TotalSteps) >= 6000 THEN 'MODERATELYACTIVE'
  WHEN AVG(TotalSteps) < 6000 THEN 'SEDENTARY'
END AS activityRating
FROM
  `capstone-417722.Bellabeat.copy_dailyActivity`
GROUP BY
  Id
)
SELECT
  cda.Id,
  cda.ActivityDate,
  cda.TotalSteps,
  SUM(cda.TotalSteps) OVER(PARTITION BY cda.Id ORDER BY cda.Id, cda.ActivityDate) AS SumOfSteps,
  ar.activityRating
FROM
  activityRatings AS ar
JOIN
  `capstone-417722.Bellabeat.copy_dailyActivity` AS cda
ON
  ar.Id = cda.Id;

---CREATE activityRating Table---


CREATE OR REPLACE TABLE `capstone-417722.Bellabeat.activityRating` AS
WITH activityRatings AS
(
  SELECT
  Id,
  AVG(TotalSteps) AS avgTotalSteps,
CASE
  WHEN AVG(TotalSteps) >= 10000 THEN 'HIGHLYACTIVE'
  WHEN AVG(TotalSteps) >= 7000 THEN 'MODERATELYACTIVE'
  WHEN AVG(TotalSteps) < 7000 THEN 'SEDENTARY'
END AS activityRating
FROM
  `capstone-417722.Bellabeat.copy_dailyActivity`
GROUP BY
  Id
)
SELECT
  cda.Id,
  cda.ActivityDate,
  cda.TotalSteps,
  SUM(cda.TotalSteps) OVER(PARTITION BY cda.Id ORDER BY cda.Id, cda.ActivityDate) AS SumOfSteps,
  ar.activityRating
FROM
  activityRatings AS ar
JOIN
  `capstone-417722.Bellabeat.copy_dailyActivity` AS cda
ON
  ar.Id = cda.Id;





---ACTIVITY RATING VS CALORIES---


SELECT
  ar.activityRating,
  AVG(cda.Calories) AS AvgCalBurned
FROM
  `Bellabeat.copy_dailyActivity` AS cda
JOIN
  `Bellabeat.activityRating` AS ar
ON
  cda.Id = ar.Id
GROUP BY
  ar.activityRating;

---ACTIVITY RATING VS CALORIES BY DAY---


SELECT
  ar.activityRating,
  cda.DayOfWeek,
  AVG(cda.Calories) AS AvgCalBurned
FROM
  `Bellabeat.copy_dailyActivity` AS cda
JOIN
  `Bellabeat.activityRating` AS ar
ON
  cda.Id = ar.Id
GROUP BY
  ar.activityRating,
  cda.DayOfWeek;


---COUNT OF ACTIVITY RATINGS---

SELECT
  ID,
  AVG(TotalSteps) AS AvgTotalSteps,
  activityRating
FROM
  `capstone-417722.Bellabeat.activityRating`
GROUP BY
  Id,
  activityRating;

WITH avgStepsVsRating AS
(
  SELECT
  ID,
  AVG(TotalSteps),
  activityRating
FROM
  `capstone-417722.Bellabeat.activityRating`
GROUP BY
  Id,
  activityRating
)
SELECT
  COUNT(CASE WHEN activityRating = 'HIGHLYACTIVE' THEN 1 END) AS countHighlyActive,
  COUNT(CASE WHEN activityRating = 'MODERATELYACTIVE' THEN 1 END) AS countModeratelyActive,
  COUNT(CASE WHEN activityRating = 'SEDENTARY' THEN 1 END) AS countSedentary
FROM
  avgStepsVsRating;

---LOOKING TOTALINTENSITY BY TIME OF DAY---

SELECT
  *
FROM
  `capstone-417722.Bellabeat.hourlyIntensities`;

---FORMAT ACTIVITY HOUR---


SELECT
  Id,
  ActivityDate,
  PARSE_TIME('%H:%M', ActivityHour) AS ActivityHour,
  TotalIntensity,
  AverageIntensity
FROM
  `capstone-417722.Bellabeat.hourlyIntensities`
ORDER BY
  1,2,3;

---CREAT COPY OF HOURLY INTENSITIES TABLE---


CREATE OR REPLACE TABLE `capstone-417722.Bellabeat.copy_hourlyIntensities` AS
SELECT
  CAST(Id AS STRING) AS ID,
  ActivityDate,
  PARSE_TIME('%H:%M', ActivityHour) AS ActivityHour,
  TotalIntensity,
  AverageIntensity
FROM
  `capstone-417722.Bellabeat.hourlyIntensities`
ORDER BY
  1,2,3;

---ACTIVITY BY TIME OF DAY---


SELECT
  Id,
  ActivityDate,
  MAX(TotalIntensity) AS maxIntensityPerDay,
  SUM(TotalIntensity) AS totalIntesityPerDay,
  SUM(CASE WHEN ActivityHour BETWEEN '05:00:00' AND '9:00:00' THEN TotalIntensity ELSE 0 END) AS sumMorningActivity,
  SUM(CASE WHEN ActivityHour BETWEEN '10:00:00' AND '13:00:00' THEN TotalIntensity ELSE 0 END) AS sumMiddayActivity,
  SUM(CASE WHEN ActivityHour BETWEEN '14:00:00' AND '19:00:00' THEN TotalIntensity ELSE 0 END) AS sumEveningActivity,
  SUM(CASE WHEN ActivityHour BETWEEN '20:00:00' AND '23:00:00' OR ActivityHour BETWEEN '00:00:00' AND '04:00:00' THEN TotalIntensity ELSE 0 END) AS sumNightActivity
FROM
  `capstone-417722.Bellabeat.copy_hourlyIntensities`
GROUP BY
  1,2
ORDER BY
  1,2;



---NAME ID BY AVG ACTIVITY IN TIME OF DAY---

WITH intensityInSection AS
(
  SELECT
  Id,
  ActivityDate,
  MAX(TotalIntensity) AS maxIntensityPerDay,
  SUM(TotalIntensity) AS totalIntesityPerDay,
  SUM(CASE WHEN ActivityHour BETWEEN '05:00:00' AND '9:00:00' THEN TotalIntensity ELSE 0 END) AS sumMorningActivity,
  SUM(CASE WHEN ActivityHour BETWEEN '10:00:00' AND '13:00:00' THEN TotalIntensity ELSE 0 END) AS sumMiddayActivity,
  SUM(CASE WHEN ActivityHour BETWEEN '14:00:00' AND '19:00:00' THEN TotalIntensity ELSE 0 END) AS sumEveningActivity,
  SUM(CASE WHEN ActivityHour BETWEEN '20:00:00' AND '23:00:00' OR ActivityHour BETWEEN '00:00:00' AND '04:00:00' THEN TotalIntensity ELSE 0 END) AS sumNightActivity
FROM
  `capstone-417722.Bellabeat.copy_hourlyIntensities`
GROUP BY
  1,2
  ),
avgDailyActivity AS 
(
  SELECT
  ID,
  AVG(sumMorningActivity) AS avgMorningActivity,
  AVG(sumMiddayActivity) AS avgMiddayActivity,
  AVG(sumEveningActivity) AS avgEveningActivity,
  AVG(sumNightActivity) AS avgNightActivity
FROM
  intensityInSection
GROUP BY
  ID
)
SELECT
  id,
  CASE
    WHEN avgDailyActivity.avgMorningActivity >= avgDailyActivity.avgMiddayActivity AND avgDailyActivity.avgMorningActivity >= avgDailyActivity.avgEveningActivity AND 
    avgDailyActivity.avgMorningActivity >= avgDailyActivity.avgNightActivity THEN 'EARLYBIRD'
    WHEN avgDailyActivity.avgMiddayActivity >= avgDailyActivity.avgMorningActivity AND avgDailyActivity.avgMiddayActivity >= avgDailyActivity.avgEveningActivity AND 
    avgDailyActivity.avgMiddayActivity >= avgDailyActivity.avgNightActivity THEN 'LATEBLOOMER'
    WHEN avgDailyActivity.avgEveningActivity >= avgDailyActivity.avgMorningActivity AND avgDailyActivity.avgEveningActivity >= avgDailyActivity.avgMiddayActivity AND 
    avgDailyActivity.avgEveningActivity >= avgDailyActivity.avgNightActivity THEN 'AFTERWORKER'
    WHEN avgDailyActivity.avgNightActivity >= avgDailyActivity.avgMorningActivity AND avgDailyActivity.avgNightActivity >= avgDailyActivity.avgMiddayActivity AND 
    avgDailyActivity.avgNightActivity >= avgDailyActivity.avgEveningActivity THEN 'NIGHTOWL'
  END AS timeOfDayExercise,
  avgDailyActivity.avgMorningActivity,
  avgDailyActivity.avgMiddayActivity,
  avgDailyActivity.avgEveningActivity,
  avgDailyActivity.avgNightActivity,
FROM
  avgDailyActivity;

---CREATE TYPE OF EXCERCISER TABLE---


CREATE OR REPLACE TABLE `capstone-417722.Bellabeat.TypeofExerciser` AS
WITH intensityInSection AS
(
  SELECT
  Id,
  ActivityDate,
  MAX(TotalIntensity) AS maxIntensityPerDay,
  SUM(TotalIntensity) AS totalIntesityPerDay,
  SUM(CASE WHEN ActivityHour BETWEEN '05:00:00' AND '9:00:00' THEN TotalIntensity ELSE 0 END) AS sumMorningActivity,
  SUM(CASE WHEN ActivityHour BETWEEN '10:00:00' AND '13:00:00' THEN TotalIntensity ELSE 0 END) AS sumMiddayActivity,
  SUM(CASE WHEN ActivityHour BETWEEN '14:00:00' AND '19:00:00' THEN TotalIntensity ELSE 0 END) AS sumEveningActivity,
  SUM(CASE WHEN ActivityHour BETWEEN '20:00:00' AND '23:00:00' OR ActivityHour BETWEEN '00:00:00' AND '04:00:00' THEN TotalIntensity ELSE 0 END) AS sumNightActivity
FROM
  `capstone-417722.Bellabeat.copy_hourlyIntensities`
GROUP BY
  1,2
  ),
avgDailyActivity AS 
(
  SELECT
  ID,
  AVG(sumMorningActivity) AS avgMorningActivity,
  AVG(sumMiddayActivity) AS avgMiddayActivity,
  AVG(sumEveningActivity) AS avgEveningActivity,
  AVG(sumNightActivity) AS avgNightActivity
FROM
  intensityInSection
GROUP BY
  ID
)
SELECT
  id,
  CASE
    WHEN avgDailyActivity.avgMorningActivity >= avgDailyActivity.avgMiddayActivity AND avgDailyActivity.avgMorningActivity >= avgDailyActivity.avgEveningActivity AND 
    avgDailyActivity.avgMorningActivity >= avgDailyActivity.avgNightActivity THEN 'EARLYBIRD'
    WHEN avgDailyActivity.avgMiddayActivity >= avgDailyActivity.avgMorningActivity AND avgDailyActivity.avgMiddayActivity >= avgDailyActivity.avgEveningActivity AND 
    avgDailyActivity.avgMiddayActivity >= avgDailyActivity.avgNightActivity THEN 'LATEBLOOMER'
    WHEN avgDailyActivity.avgEveningActivity >= avgDailyActivity.avgMorningActivity AND avgDailyActivity.avgEveningActivity >= avgDailyActivity.avgMiddayActivity AND 
    avgDailyActivity.avgEveningActivity >= avgDailyActivity.avgNightActivity THEN 'AFTERWORKER'
    WHEN avgDailyActivity.avgNightActivity >= avgDailyActivity.avgMorningActivity AND avgDailyActivity.avgNightActivity >= avgDailyActivity.avgMiddayActivity AND 
    avgDailyActivity.avgNightActivity >= avgDailyActivity.avgEveningActivity THEN 'NIGHTOWL'
  END AS timeOfDayExercise,
  avgDailyActivity.avgMorningActivity,
  avgDailyActivity.avgMiddayActivity,
  avgDailyActivity.avgEveningActivity,
  avgDailyActivity.avgNightActivity,
FROM
  avgDailyActivity;




--- ACTIVITY VS SLEEP ---


SELECT
  COUNT(Id),
  COUNT(SAFE_CAST(Id AS STRING))
FROM
  `capstone-417722.Bellabeat.sleepyDay_merged`;

---CREATE COPY OF SLEEPYDAY_MERGED TABLE---

CREATE OR REPLACE TABLE `capstone-417722.Bellabeat.copy_sleepyDay_merged` AS
SELECT
  CAST(Id AS STRING) AS Id,
  SleepDay,
  FORMAT_DATE('%A', SleepDay) AS DayOfWeek,
  TotalSleepRecords,
  TotalMinutesAsleep,
  TotalTimeInBed
FROM
  `capstone-417722.Bellabeat.sleepyDay_merged`;

SELECT
 DISTINCT(sd.Id),
 sd.SleepDay,
 sd.DayOfWeek,
 ar.activityRating,
 sd.TotalTimeInBed,
 sd.TotalMinutesAsleep,
 (sd.TotalTimeInBed-sd.TotalMinutesAsleep) AS TimeToFallAsleep
FROM
  `Bellabeat.copy_sleepyDay_merged` AS sd
JOIN
  `Bellabeat.activityRating` AS ar
ON
  sd.Id = ar.Id
WHERE
  TotalSleepRecords <> 2 OR
  TotalSleepRecords <> 3
GROUP BY
  sd.Id,
  sd.SleepDay,
  sd.DayOfWeek,
  ar.activityRating,
  sd.TotalTimeInBed,
  sd.TotalMinutesAsleep
ORDER BY
  1,2

WITH ActivityVsSleep AS
(
  SELECT
    DISTINCT(sd.Id),
    sd.SleepDay,
    sd.DayOfWeek,
    ar.activityRating,
    sd.TotalTimeInBed,
    sd.TotalMinutesAsleep,
    (sd.TotalTimeInBed-sd.TotalMinutesAsleep) AS TimeToFallAsleep
  FROM
    `Bellabeat.copy_sleepyDay_merged` AS sd
  JOIN
    `Bellabeat.activityRating` AS ar
  ON
    sd.Id = ar.Id
  WHERE
    TotalSleepRecords <> 2 OR
    TotalSleepRecords <> 3
  GROUP BY
    sd.Id,
    sd.SleepDay,
    sd.DayOfWeek,
    ar.activityRating,
    sd.TotalTimeInBed,
    sd.TotalMinutesAsleep
),
SleepActivity AS
(
  SELECT
  id,
  activityRating,
  DayOfWeek,
  AVG(TotalTimeInBed) AS AvgTimeInBed,
  AVG(TotalMinutesAsleep) AS AvgTimeAsleep,
  AVG(ActivityVsSleep.TimeToFallAsleep) AS AvgTimetoFallAsleep
FROM
  ActivityVsSleep
GROUP BY
  id,
  activityRating,
  DayOfWeek
)
SELECT
  sa.id,
  sa.activityRating,
  te.timeOfDayExercise,
  sa.DayOfWeek,
  sa.AvgTimeInBed,
  sa.AvgTimeAsleep,
  sa.AvgTimetoFallAsleep,
  te.avgMorningActivity,
  te.avgMiddayActivity,
  te.avgEveningActivity,
  te.avgNightActivity
FROM
  SleepActivity AS sa
JOIN
  `capstone-417722.Bellabeat.TypeofExerciser` AS te
ON
  sa.id = te.id;

---CREATE TABLE OF EXERSICER VS SLEEP---


CREATE OR REPLACE TABLE `capstone-417722.Bellabeat.ExcersicerVsSleep` AS
WITH ActivityVsSleep AS
(
  SELECT
    DISTINCT(sd.Id),
    sd.SleepDay,
    sd.DayOfWeek,
    ar.activityRating,
    sd.TotalTimeInBed,
    sd.TotalMinutesAsleep,
    (sd.TotalTimeInBed-sd.TotalMinutesAsleep) AS TimeToFallAsleep
  FROM
    `Bellabeat.copy_sleepyDay_merged` AS sd
  JOIN
    `Bellabeat.activityRating` AS ar
  ON
    sd.Id = ar.Id
  WHERE
    TotalSleepRecords <> 2 OR
    TotalSleepRecords <> 3
  GROUP BY
    sd.Id,
    sd.SleepDay,
    sd.DayOfWeek,
    ar.activityRating,
    sd.TotalTimeInBed,
    sd.TotalMinutesAsleep
),
SleepActivity AS
(
  SELECT
  id,
  activityRating,
  DayOfWeek,
  AVG(TotalTimeInBed) AS AvgTimeInBed,
  AVG(TotalMinutesAsleep) AS AvgTimeAsleep,
  AVG(ActivityVsSleep.TimeToFallAsleep) AS AvgTimetoFallAsleep
FROM
  ActivityVsSleep
GROUP BY
  id,
  activityRating,
  DayOfWeek
)
SELECT
  sa.id,
  sa.activityRating,
  te.timeOfDayExercise,
  sa.DayOfWeek,
  sa.AvgTimeInBed,
  sa.AvgTimeAsleep,
  sa.AvgTimetoFallAsleep,
  te.avgMorningActivity,
  te.avgMiddayActivity,
  te.avgEveningActivity,
  te.avgNightActivity
FROM
  SleepActivity AS sa
JOIN
  `capstone-417722.Bellabeat.TypeofExerciser` AS te
ON
  sa.id = te.id

