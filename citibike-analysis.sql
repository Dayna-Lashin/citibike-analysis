-- Looking for nulls --
SELECT *
FROM citibike_2019
WHERE start_time IS NULL
	OR stop_time IS NULL
	OR start_station_id IS NULL
	OR end_station_id IS NULL
	OR user_type IS NULL;

SELECT *
FROM citibike_stations
WHERE id IS NULL
	OR name IS NULL
	OR docks IS NULL;

--No rows returns for either table which indicates no null values found


-- Looking for duplicates --
SELECT id,
	COUNT(id)
FROM citibike_stations
GROUP BY id
HAVING COUNT(id)>1;

SELECT bike_id,
	start_time,
	COUNT(*)
FROM citibike_2019
GROUP BY bike_id, start_time
HAVING COUNT(*) > 1

--No rows returned which indicates no duplicates


-- counting rows --
SELECT COUNT(*)
FROM citibike_2019;
--404,947

SELECT COUNT(*)
FROM citibike_stations;
--936


-- 2019 riders by user_type --
SELECT user_type,
	COUNT(*) as num_riders
	FROM citibike_2019
GROUP BY 1;
--customer = 43026
--subscriber = 361921


---- Docks and Stations ----
SELECT MAX(docks) AS max_docks,
	MIN(docks) AS min_docks,
	ROUND(AVG(docks), 0) as avg_num_docks
FROM citibike_stations;
--79 max docs per any station
--0 min docs per any station
--31 avg docks per station

--which station(s) have 0 docks?
SELECT id,
	name,
	docks
FROM citibike_stations
WHERE docks = 0;
-- Mercer St & Spring St, id = 303

--redo docks calculation without outlier station
SELECT MAX(docks) AS max_docks,
	MIN(docks) AS min_docks,
	ROUND(AVG(docks), 0) as avg_num_docks
FROM citibike_stations
WHERE docks > 0;
--79 max docs per any station
--0 min docs per any station
--31 avg docks per station

--How many stations per each range of docks
SELECT COUNT(id) as num_stations,
CASE
	WHEN docks BETWEEN 1 AND 20 THEN '1-20'
	WHEN docks BETWEEN 21 AND 40 THEN '21-40'
	WHEN docks BETWEEN 41 AND 60 THEN '41-60'
	ELSE '61-80'
END AS num_docks
FROM citibike_stations
WHERE docks > 0
GROUP BY 2
ORDER BY 2 ASC;

--How many stations have less than avg num of docks?
SELECT COUNT(*) as num_stations_with_below_avg_num_docks
FROM citibike_stations
WHERE docks <
(SELECT ROUND(AVG(docks),0)
FROM citibike_stations)
--552


---- riders & stations ----

--riders by month
SELECT TO_CHAR(start_time::date, 'Month') AS month,
	COUNT(*) as total_riders
FROM citibike_2019
GROUP BY 1
ORDER BY 2 DESC;
--Sept had the most riders

--user_type breakdown of Sept
SELECT user_type,
	COUNT(user_type) AS num_users
FROM citibike_2019
WHERE DATE_PART('month', start_time) = 09
GROUP BY 1;
--customer = 7388
--subscriber = 41856

--start_station breakdown of Sept
--Check if there are any start_stations without station info
SELECT start_station_id
FROM citibike_2019
EXCEPT
SELECT id
FROM citibike_stations;
-- start_station_id = 3183
-- start_station_id = 3426

--how many trips were taken and when?
SELECT start_station_id,
	DATE_PART('Month', start_time) AS ride_month,
	COUNT(*) as num_rides
FROM citibike_2019
WHERE start_station_id = 3183 OR
start_station_id = 3426
GROUP BY 1, 2
ORDER BY 2 ASC;
--Jan through Aug
--I'm looking at September so these stations don't factor into my analysis right now
--My guess for why they're not in stations table is that they were removed part way through the year and no longer exist

--matching station names with ids to see station info for Sept
SELECT stations.id AS station_id,
	stations.name AS station_name,
	stations.docks,
	COUNT(*) AS num_riders
FROM citibike_stations stations
LEFT JOIN citibike_2019 riders
ON stations.id = riders.start_station_id
WHERE DATE_PART('Month', start_time)= 9
GROUP BY 1,2,3
ORDER BY 4 DESC;


--riders by day in Sept
SELECT TO_CHAR(start_time::date, 'Dy, Mon DD') AS day,
	COUNT(*) as total_riders
FROM citibike_2019
WHERE DATE_PART('Month', start_time) = 9
GROUP BY 1
ORDER BY 2 DESC;
--fri, Sept 27 had the most riders that month

--rider breakdown by user_type for 9/27
SELECT user_type,
	COUNT(user_type) AS num_users
FROM citibike_2019
WHERE start_time::date = '2019-09-27'
GROUP BY 1;
--Customer = 196
--Subscriber = 1729

--stations used on Fri, 9/27
SELECT stations.id AS station_id,
	stations.name AS station_name,
	stations.docks,
	COUNT(*) AS num_riders
FROM citibike_stations stations
LEFT JOIN citibike_2019 riders
ON stations.id = riders.start_station_id
WHERE start_time::date = '2019-09-27'
GROUP BY 1,2,3
ORDER BY 4 DESC;


--riders by hour on Fri, 9/27
SELECT TO_CHAR(start_time,'HH am') AS hour,
	COUNT(*) as total_riders
FROM citibike_2019
WHERE start_time::date = '2019-09-27'
GROUP BY 1
ORDER BY 2 DESC;
--8am hour had the most rides

--rider breakdown by user_type for 9/27 8am hour
SELECT user_type,
	COUNT(user_type) AS num_users
FROM citibike_2019
WHERE start_time::date = '2019-09-27'
	AND DATE_PART('hour', start_time) = 08
GROUP BY 1;
--Customer = 17
--Subscriber = 213

--stations used on Fri, 9/27 8am hour
SELECT stations.id AS station_id,
	stations.name AS station_name,
	stations.docks,
	COUNT(*) AS num_riders
FROM citibike_stations stations
LEFT JOIN citibike_2019 riders
ON stations.id = riders.start_station_id
WHERE start_time::date = '2019-09-27'
	AND DATE_PART('hour', start_time) = 08
GROUP BY 1,2,3
ORDER BY 4 DESC;


-- Pulling top 10 stations of Sept with dock labels for recommendation

SELECT stations.id AS station_id,
	stations.name AS station_name,
	stations.docks,
	COUNT(*) AS num_riders,
CASE
	WHEN docks < (SELECT ROUND(AVG(docks),0) FROM citibike_stations) THEN 'Below Average'
	WHEN docks = (SELECT ROUND(AVG(docks),0) FROM citibike_stations) THEN 'Average'
	ELSE 'Above Average'
END AS num_docks_label
FROM citibike_stations stations
LEFT JOIN citibike_2019 riders
ON stations.id = riders.start_station_id
WHERE DATE_PART('Month', start_time)= 9
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 10;
