USE ECHARGER_DB;
USE ECHARGER_DB.ECHARGERS_SCHEMA;

-- LEVEL 1

-- Question 1: Number of users with sessions

-- Opcion 1
SELECT COUNT(DISTINCT s.USER_ID) AS users_with_sessions
FROM sessions s;

-- Opcion 2
-- SELECT COUNT(DISTINCT u.ID) AS users_with_sessions
-- FROM users u
-- JOIN sessions s ON u.ID = s.USER_ID;

-- Question 2: Number of chargers used by user with id 1

SELECT COUNT(DISTINCT s.CHARGER_ID) AS n_chargers_id1
FROM sessions s
WHERE s.USER_ID = 1;



-- LEVEL 2

-- Question 3: Number of sessions per charger type (AC/DC):

SELECT c.TYPE, COUNT(DISTINCT s.ID) AS n_sessions
FROM sessions s
JOIN chargers c ON s.CHARGER_ID = c.ID
GROUP BY c.TYPE;


-- Question 4: Chargers being used by more than one user

SELECT s.CHARGER_ID, COUNT(DISTINCT s.USER_ID) AS n_users
FROM sessions s
GROUP BY s.CHARGER_ID
HAVING COUNT(DISTINCT s.USER_ID) > 1
ORDER BY s.CHARGER_ID;

-- Question 5: Average session time per charger

SELECT s.CHARGER_ID, 
    AVG(DATEDIFF(HOUR, s.START_TIME, s.END_TIME)) AS avg_hours,
    AVG(DATEDIFF(MINUTE, s.START_TIME, s.END_TIME)) AS avg_mins,
    AVG(DATEDIFF(SECOND, s.START_TIME, s.END_TIME)) AS avg_secs
FROM sessions s
GROUP BY s.CHARGER_ID
ORDER BY s.CHARGER_ID;



-- LEVEL 3

-- Question 6: Full username of users that have used more than one charger in one day (NOTE: for date only consider start_time)

SELECT DISTINCT CONCAT(u.FIRST_NAME, ' ', u.LAST_NAME) AS username
FROM sessions s
JOIN users u ON s.USER_ID = u.ID
GROUP BY u.ID, username, DATE(s.START_TIME)
HAVING COUNT(DISTINCT s.CHARGER_ID) > 1
ORDER BY username;


-- Question 7: Top 3 chargers with longer sessions

SELECT s.CHARGER_ID, MAX(DATEDIFF(HOUR, s.START_TIME, s.END_TIME)) AS total_hours
FROM sessions s
GROUP BY s.CHARGER_ID
ORDER BY total_hours DESC
LIMIT 3;

-- Question 8: Average number of users per charger (per charger in general, not per charger_id specifically)

SELECT AVG(user_cnt) AS avg_per_charger
FROM (
    SELECT s.CHARGER_ID, COUNT(DISTINCT s.USER_ID) AS user_cnt
    FROM sessions s
    GROUP BY s.CHARGER_ID
) AS user_counts_per_charger;

-- Question 9: Top 3 users with more chargers being used

SELECT CONCAT(u.FIRST_NAME, ' ', u.LAST_NAME) AS username,
    COUNT(DISTINCT s.CHARGER_ID) AS CHARGER_COUNT
FROM users u
JOIN sessions s ON u.ID = s.USER_ID
GROUP BY u.ID, username
ORDER BY CHARGER_COUNT DESC
LIMIT 3;

-- LEVEL 4

-- Question 10: Number of users that have used only AC chargers, DC chargers or both

SELECT 
    COUNT(DISTINCT CASE WHEN user_type = 'only_AC' THEN USER_ID END) AS only_AC_count,
    COUNT(DISTINCT CASE WHEN user_type = 'only_DC' THEN USER_ID END) AS only_DC_count,
    COUNT(DISTINCT CASE WHEN user_type = 'both_AC/DC' THEN USER_ID END) AS both_ACDC_count
FROM (
    SELECT 
        s.USER_ID,
        CONCAT(u.FIRST_NAME, ' ', u.LAST_NAME) AS username,
        CASE 
            WHEN COUNT(DISTINCT c.TYPE) = 1 AND MAX(c.TYPE) = 'AC' THEN 'only_AC'
            WHEN COUNT(DISTINCT c.TYPE) = 1 AND MAX(c.TYPE) = 'DC' THEN 'only_DC'
            WHEN COUNT(DISTINCT c.TYPE) = 2 THEN 'both_AC/DC'
        END AS user_type
    FROM sessions s
    JOIN chargers c ON s.CHARGER_ID = c.id
    JOIN users u ON s.USER_ID = u.ID
    GROUP BY username, s.USER_ID
    ORDER BY s.USER_ID
) AS username_charger_counts;

-- Question 11: Monthly average number of users per charger

SELECT 
    charger_id,
    month_id,
    AVG(user_count) AS average_users_per_month
FROM (
    SELECT 
        c.id AS charger_id,
        EXTRACT(MONTH FROM s.start_time) AS month_id,
        COUNT(DISTINCT s.user_id) AS user_count
    FROM sessions s
    JOIN chargers c ON s.charger_id = c.id
    GROUP BY c.id, month_id
) AS monthly_counts
GROUP BY charger_id, month_id
ORDER BY charger_id, month_id;
    
-- Question 12: Top 3 users per charger (for each charger, number of sessions)

SELECT CHARGER_ID, USER_ID as top3_userid, n_sessions
FROM (
    SELECT 
        s.CHARGER_ID,
        s.USER_ID,
        COUNT(*) AS n_sessions,
        ROW_NUMBER() OVER (PARTITION BY s.CHARGER_ID ORDER BY COUNT(*) DESC) AS ranking
    FROM sessions s
    GROUP BY s.CHARGER_ID, s.USER_ID
) AS ranking_users
WHERE ranking <= 3
ORDER BY CHARGER_ID, ranking;

-- LEVEL 5

-- Question 13: Top 3 users with longest sessions per month (consider the month of start_time)

SELECT 
    EXTRACT(MONTH FROM s.START_TIME) AS MONTH_ID,
    USER_ID,
    MAX(DATEDIFF(HOUR, START_TIME, END_TIME)) AS total_hours
FROM sessions s
GROUP BY MONTH_ID, USER_ID
ORDER BY MONTH_ID, total_hours DESC
LIMIT 3;
    
-- Question 14. Average time between sessions for each charger for each month (consider the month of start_time)

WITH SessionIntervals AS (
    SELECT 
        CHARGER_ID,
        EXTRACT(MONTH FROM s.START_TIME) AS MONTH_ID,
        START_TIME,
        LEAD(START_TIME) OVER (PARTITION BY CHARGER_ID ORDER BY START_TIME) AS next_start_time
    FROM sessions s
)
SELECT 
    CHARGER_ID,
    MONTH_ID,
    AVG(DATEDIFF(HOUR, START_TIME, next_start_time)) AS avg_hour_interval
FROM SessionIntervals
WHERE next_start_time IS NOT NULL
GROUP BY CHARGER_ID, MONTH_ID
ORDER BY CHARGER_ID, MONTH_ID;
