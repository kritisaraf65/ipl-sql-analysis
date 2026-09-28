-- creat Tables
DROP TABLE IF EXISTS MATCHES;
CREATE TABLE MATCHES (
	ID INTEGER PRIMARY KEY,
	SEASON VARCHAR(20),
	CITY VARCHAR(50),
	DATE DATE,
	MATCH_TYPE VARCHAR(30),
	PLAYER_OF_MATCH VARCHAR(100),
	VENUE VARCHAR(150),
	TEAM1 VARCHAR(100),
	TEAM2 VARCHAR(100),
	TOSS_WINNER VARCHAR(100),
	TOSS_DECISION VARCHAR(20),
	WINNER VARCHAR(100),
	RESULT VARCHAR(30),
	RESULT_MARGIN VARCHAR(20),
	TARGET_RUNS INTEGER,
	TARGET_OVERS DECIMAL(4, 1),
	SUPER_OVER VARCHAR(5),
	METHOD VARCHAR(50),
	UMPIRE1 VARCHAR(100),
	UMPIRE2 VARCHAR(100)
);

DROP TABLE  IF EXISTS DELIVERIES;
CREATE TABLE DELIVERIES (
	MATCH_ID INTEGER,
	INNING INTEGER,
	BATTING_TEAM VARCHAR(100),
	BOWLING_TEAM VARCHAR(100),
	OVER INTEGER,
	BALL INTEGER,
	BATTER VARCHAR(100),
	BOWLER VARCHAR(100),
	NON_STRIKER VARCHAR(100),
	BATSMAN_RUNS INTEGER,
	EXTRA_RUNS INTEGER,
	TOTAL_RUNS INTEGER,
	EXTRAS_TYPE VARCHAR(50),
	IS_WICKET INTEGER,
	PLAYER_DISMISSED VARCHAR(50),
	DISMISSAL_KIND VARCHAR(50),
	FIELDER VARCHAR(50)
);

SELECT * FROM MATCHES;
SELECT * FROM DELIVERIES;

--Import Data into MATCHES Table
COPY MATCHES (id, season, city, date, match_type, player_of_match, venue, team1, team2, toss_winner, toss_decision, winner, result, result_margin, target_runs, target_overs, super_over, method, umpire1, umpire2)
FROM 'C:\Users\Public\Documents\matches.csv'
DELIMITER','
CSV HEADER
NULL 'NA';

--Import Data into DELIVERIES Table
COPY DELIVERIES (match_id,inning, batting_team, bowling_team, over, ball, batter, bowler, non_striker, batsman_runs, extra_runs, total_runs, extras_type, is_wicket, player_dismissed, dismissal_kind, fielder)
FROM 'C:\Users\Public\Documents\deliveries.csv'
DELIMITER','
CSV HEADER 
NULL 'NA';

--Data Exploration 

--1. view all match data
SELECT * FROM MATCHES;

--2. view the first 10 matches 
SELECT * FROM MATCHES
LIMIT 10;

--3. count the total number of matches 
SELECT COUNT(*) AS total_matches 
FROM MATCHES;

--4. find all unique seasons 
SELECT DISTINCT season FROM MATCHES
ORDER BY season;

--5.view matches sorted by date 
SELECT * FROM MATCHES
ORDER BY DATE;

--6. view the 10 most recent matches 
SELECT * FROM MATCHES
ORDER BY DATE DESC
LIMIT 10;

--7. view the first 10 delivery records 
SELECT * FROM DELIVERIES
LIMIT 10;

--8. count the total number of deliveries 
SELECT COUNT (*) AS total_deliveries
FROM DELIVERIES;

--9. find the different extras types 
SELECT DISTINCT extras_type
FROM DELIVERIES
WHERE extras_type IS NOT NULL;

--10. find the different dismissal types 
SELECT DISTINCT dismissal_kind
FROM DELIVERIES 
WHERE dismissal_kind IS NOT NULL;


--
=======
--PROJECT ANALYSIS
=======
-- BASIC ANALYSIS 
======
--


--1. find the total number of matches played.
SELECT COUNT (*) AS total_matches 
FROM MATCHES;

--2. find the number of matches played in each season.
SELECT SEASON, COUNT(*) AS total_matches
FROM MATCHES
GROUP BY SEASON
ORDER BY SEASON;

--3. find the number of matches won by each team.
SELECT WINNER, COUNT(*) AS total_wins
FROM MATCHES 
WHERE WINNER IS NOT NULL
GROUP BY WINNER 
ORDER BY total_wins DESC;

--4. find the most frequently used venues.
SELECT VENUE, COUNT (*) AS match_played
FROM MATCHES 
GROUP  BY VENUE 
ORDER BY match_played DESC;

--5. find the number of matches won after choosing a bat first 
SELECT COUNT(*) AS matches_won_batting_first 
FROM MATCHES
WHERE TOSS_DECISION ='bat' AND WINNER = TOSS_WINNER;

--6. find the number of matches won afetr choosing to field first 
SELECT COUNT(*) AS matches_won_fielding_first
FROM MATCHES 
WHERE TOSS_DECISION = 'field' AND WINNER = TOSS_WINNER;

--7. find the top 10 players with the most Player of the Match awards.
SELECT PLAYER_OF_MATCH, COUNT (*) AS awards
FROM MATCHES 
WHERE PLAYER_OF_MATCH IS NOT NULL 
GROUP BY PLAYER_OF_MATCH
ORDER BY awards DESC
LIMIT 10;

--8. find the total number of deliveries bowled. 
SELECT COUNT (*) AS total_deliveries
FROM DELIVERIES;

--9. find the total runs scored by each batting team.
SELECT BATTING_TEAM, SUM(BATSMAN_RUNS) AS total_runs
FROM DELIVERIES 
GROUP BY BATTING_TEAM 
ORDER BY total_runs DESC; 

--10. find the number of wickets taken by each bowling team.
SELECT BOWLING_TEAM, COUNT (*) AS total_wickets
FROM DELIVERIES
WHERE IS_WICKET = 1
GROUP BY BOWLING_TEAM
ORDER BY total_wickets; 

--
=======
-- ADVANCED ANALYSIS 
======
--

--11. Find the top 3 teams with the highest number of wins.
SELECT winner, COUNT(*) AS total_wins
FROM matches
WHERE winner IS NOT NULL
GROUP BY winner
ORDER BY total_wins DESC
LIMIT 3;

-- 12. Find teams that have appeared as both Team 1 and Team 2.
SELECT TEAM1 AS TEAM
FROM MATCHES
UNION
SELECT TEAM2 AS TEAM
FROM MATCHES;

-- 13. Find matches with a target higher than the overall average.
SELECT ID,TEAM1,TEAM2,WINNER,TARGET_RUNS
FROM MATCHES
WHERE TARGET_RUNS > (SELECT AVG(TARGET_RUNS)
    FROM MATCHES
    WHERE TARGET_RUNS IS NOT NULL
);

-- 14. Rank matches by result margin within each season.
SELECT
	SEASON,
	ID,
	TEAM1,
	TEAM2,
	RESULT_MARGIN,
	RANK() OVER (
		PARTITION BY SEASON
		ORDER BY RESULT_MARGIN DESC
	) AS MARGIN_RANK
FROM MATCHES
WHERE RESULT_MARGIN IS NOT NULL;

-- 15. Calculate team wins using a CTE
WITH team_wins AS (
    SELECT WINNER,
           COUNT(*) AS total_wins
    FROM MATCHES
    WHERE WINNER IS NOT NULL
    GROUP BY WINNER
)
SELECT WINNER,
       total_wins
FROM team_wins
ORDER BY total_wins DESC;

-- 16. Find the top 10 batsmen by total runs using a CTE
WITH batsman_runs AS (
    SELECT BATTER,
           SUM(BATSMAN_RUNS) AS total_runs
    FROM DELIVERIES
    GROUP BY BATTER
)
SELECT BATTER,
       total_runs
FROM batsman_runs
ORDER BY total_runs DESC
LIMIT 10;

-- 17. Rank bowlers based on wickets taken
SELECT BOWLER,
       COUNT(*) AS total_wickets,
       RANK() OVER (
           ORDER BY COUNT(*) DESC
       ) AS wicket_rank
FROM DELIVERIES
WHERE IS_WICKET = 1
GROUP BY BOWLER;

-- 18. Calculate each batsman's percentage contribution to total runs
SELECT BATTER,
       SUM(BATSMAN_RUNS) AS total_runs,
       ROUND(100.0 * SUM(BATSMAN_RUNS)
           / SUM(SUM(BATSMAN_RUNS)) OVER (),
           2
       ) AS percentage_of_total
FROM DELIVERIES
GROUP BY BATTER
ORDER BY total_runs DESC;

--19. find the teams that have won at least 5 matches. 
SELECT winner, COUNT(*) AS total_wins
FROM matches
WHERE winner IS NOT NULL
GROUP BY winner
HAVING COUNT(*) >= 5
ORDER BY total_wins DESC;

-- 20. find the matches where the same team won more than 3 times in the dataset.
SELECT winner, COUNT(*) AS total_wins
FROM matches
WHERE winner IS NOT NULL
GROUP BY winner
HAVING COUNT(*) > 3
ORDER BY total_wins DESC;