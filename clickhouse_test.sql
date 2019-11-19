SELECT avg(c1)
FROM
(
    SELECT Year, Month, count(*) AS c1
    FROM ontime
    GROUP BY Year, Month
);       -- 耗时：0.362s


SELECT DayOfWeek, count(*) AS c
FROM ontime
WHERE Year>=2000 AND Year<=2008
GROUP BY DayOfWeek
ORDER BY c DESC;  -- 耗时：0.083s


SELECT DayOfWeek, count(*) AS c
FROM ontime
WHERE DepDelay>10 AND Year>=2000 AND Year<=2008
GROUP BY DayOfWeek
ORDER BY c DESC;  -- 耗时：0.21s


SELECT Origin, count(*) AS c
FROM ontime
WHERE DepDelay>10 AND Year>=2000 AND Year<=2008
GROUP BY Origin
ORDER BY c DESC
LIMIT 10;   -- 0.279s

SELECT Carrier, count(*)
FROM ontime
WHERE DepDelay>10 AND Year=2007
GROUP BY Carrier
ORDER BY count(*) DESC; --耗时：0.036s


SELECT Carrier, c, c2, c*100/c2 as c3
FROM
(
    SELECT
        Carrier,
        count(*) AS c
    FROM ontime
    WHERE DepDelay>10
        AND Year=2007
    GROUP BY Carrier
)
 JOIN
(
    SELECT
        Carrier,
        count(*) AS c2
    FROM ontime
    WHERE Year=2007
    GROUP BY Carrier
) USING Carrier
ORDER BY c3 DESC;    -- 耗时：0.061s

-- better query of below
SELECT Carrier, avg(DepDelay>10)*100 AS c3
FROM ontime
WHERE Year=2007
GROUP BY Carrier
ORDER BY Carrier; -- 耗时: 0.038s 


SELECT Carrier, c, c2, c*100/c2 as c3
FROM
(
    SELECT
        Carrier,
        count(*) AS c
    FROM ontime
    WHERE DepDelay>10
        AND Year>=2000 AND Year<=2008
    GROUP BY Carrier
)
 JOIN
(
    SELECT
        Carrier,
        count(*) AS c2
    FROM ontime
    WHERE Year>=2000 AND Year<=2008
    GROUP BY Carrier
) USING Carrier
ORDER BY c3 DESC;  --耗时:0.338s

-- better query of below
SELECT Carrier, avg(DepDelay>10)*100 AS c3
FROM ontime
WHERE Year>=2000 AND Year<=2008
GROUP BY Carrier
ORDER BY Carrier;   -- 耗时:0.210s


SELECT Year, c1/c2
FROM
(
    select
        Year,
        count(*)*100 as c1
    from ontime
    WHERE DepDelay>10
    GROUP BY Year
)
JOIN
(
    select
        Year,
        count(*) as c2
    from ontime
    GROUP BY Year
) USING (Year)   --耗时:0.555s
ORDER BY Year;

-- better query of below
SELECT Year, avg(DepDelay>10)
FROM ontime
GROUP BY Year
ORDER BY Year;  -- 耗时:0.347s


SELECT DestCityName, uniqExact(OriginCityName) AS u 
FROM ontime
WHERE Year >= 2000 and Year <= 2010
GROUP BY DestCityName
ORDER BY u DESC LIMIT 10;  -- 耗时:1.193s


SELECT Year, count(*) AS c1
FROM ontime
GROUP BY Year;   --耗时:0.146s


SELECT
   min(Year), max(Year), Carrier, count(*) AS cnt,
   sum(ArrDelayMinutes>30) AS flights_delayed,
   round(sum(ArrDelayMinutes>30)/count(*),2) AS rate
FROM ontime
WHERE
   DayOfWeek NOT IN (6,7) AND OriginState NOT IN ('AK', 'HI', 'PR', 'VI')
   AND DestState NOT IN ('AK', 'HI', 'PR', 'VI')
   AND FlightDate < '2010-01-01'
GROUP by Carrier
HAVING cnt>100000 and max(Year)>1990
ORDER by rate DESC
LIMIT 1000;    --耗时: 1.104s


-- bonus
SELECT avg(cnt)
FROM
(
    SELECT Year,Month,count(*) AS cnt
    FROM ontime
    WHERE DepDel15=1
    GROUP BY Year,Month
);

SELECT avg(c1) FROM
(
    SELECT Year,Month,count(*) AS c1
    FROM ontime
    GROUP BY Year,Month
);

SELECT DestCityName, uniqExact(OriginCityName) AS u
FROM ontime
GROUP BY DestCityName
ORDER BY u DESC
LIMIT 10;

SELECT OriginCityName, DestCityName, count() AS c
FROM ontime
GROUP BY OriginCityName, DestCityName
ORDER BY c DESC
LIMIT 10;

SELECT OriginCityName, count() AS c
FROM ontime
GROUP BY OriginCityName
ORDER BY c DESC
LIMIT 10;
----------------------------------------------------
SELECT \
    OriginCityName, \
    DestCityName, \
    count(*) AS flights, \
    bar(flights, 0, 20000, 40) \
FROM ontime \
WHERE Year = 2015 \
GROUP BY \
    OriginCityName, \
    DestCityName \
ORDER BY flights DESC \    --耗时：0.130s
LIMIT 20;

SELECT \
    OriginCityName, \
    count(*) AS flights \
FROM ontime \
GROUP BY OriginCityName \
ORDER BY flights DESC \
LIMIT 20;         --耗时：0.949s

SELECT \
    OriginCityName, \
    uniq(Dest) As u \
FROM ontime \
GROUP BY OriginCityName \
ORDER BY u DESC \
LIMIT 20;  --耗时:1.518s


SELECT \
    DayOfWeek, \
    count() AS c, \
    avg(DepDelay > 60) AS delays \
FROM ontime \
GROUP BY DayOfWeek \
ORDER BY DayOfWeek ASC;  --耗时:0.436s


SELECT \
    OriginCityName, \
    count() AS c, \
    avg(DepDelay > 60) AS delays \
FROM ontime \
GROUP BY OriginCityName \
HAVING c > 100000 \
ORDER BY delays DESC \
LIMIT 20;   --耗时: 0.377s


SELECT \
    OriginCityName, \
    DestCityName, \
    count(*) AS flights, \
    avg(AirTime) As duration \
FROM ontime \
GROUP BY \
    OriginCityName, \
    DestCityName \
ORDER BY duration DESC \
LIMIT 20;    --耗时: 12.407s 、2.770s


SELECT \
    Carrier, \
    count() AS c, \
    round(quantileTDigest(0.99)(DepDelay), 2) AS q \
FROM ontime \
GROUP BY Carrier \
ORDER BY q DESC;   --耗时: 1.414s


SELECT \
    Carrier, \
    min(Year), \
    max(Year), \
    count() \
FROM ontime \
GROUP BY Carrier \
HAVING max(Year) < 2015 \
ORDER BY count() DESC;  --耗时: 0.390s


SELECT \
    DestCityName, \
    sum(Year = 2014) AS c2014, \
    sum(Year = 2015) AS c2015, \
    c2015 / c2014 AS diff \
FROM ontime \
WHERE Year IN (2014, 2015) \
GROUP BY DestCityName \
HAVING (c2014 > 10000) AND (c2015 > 1000) AND (diff > 1) \
ORDER BY diff DESC;   --耗时: 0.1s


SELECT \
    DestCityName, \
    any(total), \
    avg(abs((monthly * 12) - total) / total) AS avg_month_diff \
FROM \
( \
    SELECT \
        DestCityName, \
        count() AS total \
    FROM ontime \
    GROUP BY DestCityName \
    HAVING total > 100000 \
) ALL INNER JOIN \
( \
    SELECT \
        DestCityName, \
        Month, \
        count() AS monthly \
    FROM ontime \
    GROUP BY \
        DestCityName, \
        Month \
    HAVING monthly > 10000 \
) USING (DestCityName) \
GROUP BY DestCityName \
ORDER BY avg_month_diff DESC \
LIMIT 20;   --耗时: 2.389s
 


