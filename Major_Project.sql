                                     /*UEFA Analysis*/
--Creating tables
CREATE TABLE Goals (
    GOAL_ID VARCHAR(256) PRIMARY KEY,
    MATCH_ID VARCHAR(265),
    PID VARCHAR(256),
    DURATION INT,
    ASSIST VARCHAR(256),
    GOAL_DESC VARCHAR(256)
);

CREATE TABLE Matches (
    MATCH_ID VARCHAR(256) PRIMARY KEY,
    SEASON VARCHAR(256),
    DATE DATE,
    HOME_TEAM VARCHAR(256),
    AWAY_TEAM VARCHAR(256),
    STADIUM VARCHAR(256),
    HOME_TEAM_SCORE INT,
    AWAY_TEAM_SCORE INT,
    PENALTY_SHOOT_OUT INT,
    ATTENDANCE INT
);

CREATE TABLE Players (
    PLAYER_ID VARCHAR(256) PRIMARY KEY,
    FIRST_NAME VARCHAR(256),
    LAST_NAME VARCHAR(256),
    NATIONALITY VARCHAR(256),
    DOB DATE,
    TEAM VARCHAR(256),
    JERSEY_NUMBER FLOAT,
    POSITION VARCHAR(256),
    HEIGHT FLOAT,
    WEIGHT FLOAT,
    FOOT CHAR(1)
);

CREATE TABLE Teams (
    TEAM_NAME VARCHAR(256),
    COUNTRY VARCHAR(256),
    HOME_STADIUM VARCHAR(256)
);

CREATE TABLE Stadiums (
    Name VARCHAR(256),
    City VARCHAR(256),
    Country VARCHAR(256),
    Capacity INT
);

--Copying all the data to the created tables using COPY method.

copy Goals from 'C:\Program Files\PostgreSQL\17\data\datasets\goals.csv' csv header;
select * from Goals;

copy Matches from 'C:\Program Files\PostgreSQL\17\data\datasets\Matches.csv' csv header;
select * from Matches;

copy Players from 'C:\Program Files\PostgreSQL\17\data\datasets\Players.csv' csv header;
select * from Players;

copy Teams from 'C:\Program Files\PostgreSQL\17\data\datasets\Teams.csv' csv header;
select * from Teams;

copy Stadiums from 'C:\Program Files\PostgreSQL\17\data\datasets\Stadiums.csv' csv header;
select * from Stadiums;

				--Goal Analysis 

--1.	Which player scored the most goals in a each season?
select player_id,year,name,no_of_goals from(
select g.pid as player_id,m.season as year,concat(p.first_name,' ', p.last_name) as name,
count(g.goal_id) as no_of_goals,
rank()over(partition by m.season order by count(g.goal_id) desc) as rank
from goals g join matches m
on g.match_id=m.match_id join players p on g.pid=p.player_id
group by g.pid,year,name order by no_of_goals desc) as sq where rank=1;

--2.	How many goals did each player score in a given season?
select m.season as seasons,concat(p.first_name,' ',p.last_name) as name,
count(g.goal_id) as no_of_goals
from goals g join matches m on g.match_id=m.match_id join players p on
g.pid=p.player_id group by seasons,name order by seasons,no_of_goals desc;

--3.	What is the total number of goals scored in ‘mt403’ match?
select m.match_id,count(g.goal_id) as total_goals from matches m join
goals g on m.match_id=g.match_id where m.match_id='mt403' group by m.match_id;

--4.	Which player assisted the most goals in a each season?
select year,name,assisted_no_goals from(
select m.season as year,concat(p.first_name,' ', p.last_name) as name,
count(g.assist) as assisted_no_goals,
rank()over(partition by m.season order by count(g.assist) desc) as rank
from goals g join matches m
on g.match_id=m.match_id join players p on g.pid=p.player_id group by year,name
order by year,assisted_no_goals desc) as
sq where rank=1;

--5.	Which players have scored goals in more than 10 matches?
select g.pid, concat(p.first_name,' ',p.last_name), count(distinct g.match_id) no_of_counts 
from goals g join players p on g.pid=p.player_id
group by 1,2 having count(distinct match_id)>10;

--6.	What is the average number of goals scored per match in a given season?
select season, round(avg(no_of_goals),2) as Avg_no_of_goals from(
select m.season as season, m.match_id,count(g.goal_id) as no_of_goals
from goals g right join matches m on g.match_id=m.match_id 
group by season,m.match_id) as sq group by season;

--7.	Which player has the most goals in a single match?
select m.match_id,concat(p.first_name,' ',p.last_name) as name,
count(g.goal_id) as no_of_goals from matches m join goals g
on m.match_id=g.match_id join players p on g.pid=p.player_id 
group by m.match_id,name order by no_of_goals desc;

--8.	Which team scored the most goals in the all seasons?
select team,sum(no_of_goals) as goals from (
select  m.home_team as team, count(g.goal_id) as no_of_goals, m.season as seasons
from matches m join goals g on m.match_id=g.match_id 
group by team,seasons order by no_of_goals desc) as a
group by team order by goals desc limit 1;

--9.	Which stadium hosted the most goals scored in a single season?
select m.stadium,m.season,count(g.goal_id) from matches m left join goals g on 
m.match_id=g.match_id group by m.stadium,m.season order by count(g.goal_id) desc limit 1;


							--Match Analysis 

--10.	What was the highest-scoring match in a particular season?
select season,match_id,(home_team_score+away_team_score) as total_goals from matches 
order by total_goals desc limit 1;

--11.	How many matches ended in a draw in a given season?
select season,count(*) as Total_Draws from matches 
where home_team_score = away_team_score group by season;

--12.	Which team had the highest average score (home and away) in the season 2021-2022?
select team, round(avg(score),2) as avgscore from (
select home_team as team, home_team_score as score from matches where season = '2021-2022' 
union all 
select away_team as team, away_team_score as score from matches 
where season = '2021-2022') as scores group by team order by avgscore desc limit 1;

--13.	How many penalty shootouts occurred in a each season?
select season, count(*) as penalty_shootouts from matches 
group by season order by season,penalty_shootouts desc;

--14.	What is the average attendance for home teams in the 2021-2022 season?
select season,home_team, round(avg(attendance),2) as average_attendance from matches 
where season='2021-2022' group by season,home_team order by average_attendance desc;

--15.	Which stadium hosted the most matches in a each season?
select season, stadium, most_matches from (
select season, stadium, count(match_id) as most_matches,
dense_rank()over(partition by season order by count(match_id) desc) as r
from matches group by season, stadium) as sq where sq.r=1;

--16.	What is the distribution of matches played in different countries in a season?
select season, country, count(*) as matches_played
from matches m join stadiums s on m.stadium = s.name
group by season, country order by season, matches_played desc;

--17.	What was the most common result in matches (home win, away win, draw)?
select 
case 
	when home_team_score > away_team_score then 'Home Win'
	when home_team_score < away_team_score then 'Away Win'
	else 'Draw'
end as match_result,count(*) as result_count
from matches group by match_result order by result_count desc;


					--Player Analysis 
--18.	Which players have the highest total goals scored (including assists)?
select p.first_name, p.last_name, 
       sum(case when g.goal_id is not null then 1 else 0 end) + 
       sum(case when g.assist is not null then 1 else 0 end) as total_goals
from players p left join goals g on p.player_id = g.pid
group by p.first_name, p.last_name order by total_goals desc;

--19.	What is the average height and weight of players per position?
select position, round(avg(height)::numeric, 2) as avg_height, 
round(avg(weight)::numeric, 2) as avg_weight from players 
group by position order by position;

--20.	Which player has the most goals scored with their left foot?
select concat(p.first_name,' ',p.last_name) as name, count(g.goal_id) as left_foot_goals
from players p left join goals g on p.player_id = g.pid
where p.foot = 'L' group by p.player_id,name order by left_foot_goals desc limit 1;

--21.	What is the average age of players per team?
select team, round(avg(extract(year from age(current_date, dob))), 2) as avg_age
from players group by team order by avg_age desc;

--22.	How many players are listed as playing for a each team in a season?
select p.team, count(p.player_id) as player_count, m.season
from players p join matches m on p.team = m.home_team or p.team = m.away_team
group by p.team, m.season order by m.season, player_count desc;

--23.	Which player has played in the most matches in the each season?
select m.season, g.pid, concat(p.first_name, ' ', p.last_name) as player_name, 
count(distinct g.match_id) as matches_played
from goals g join matches m on g.match_id = m.match_id
join players p on g.pid = p.player_id
group by m.season, g.pid, player_name order by m.season, matches_played desc;

--24.	What is the most common position for players across all teams?
select position, count(player_id) as player_count from players
group by position order by player_count desc limit 1;

--25.	Which players have never scored a goal?
select p.player_id, concat(p.first_name, ' ', p.last_name) as player_name
from players p left join goals g on p.player_id = g.pid
where g.goal_id is null order by player_name;


						--Team Analysis 

--26.	Which team has the largest home stadium in terms of capacity?
select t.team_name,t.home_stadium, s.capacity from teams t join stadiums s
on t.home_stadium=s.name order by s.capacity desc limit 1;

--27.	Which teams from a each country participated in the UEFA competition in a season?
select t.country, t.team_name, m.season
from teams t join matches m on t.team_name = m.home_team or t.team_name = m.away_team
group by t.country, t.team_name, m.season order by t.country, t.team_name, m.season;

---28.	Which team scored the most goals across home and away matches in a given season?
select team, season, sum(total_goals) as total_goals
from (
select m.season,m.home_team as team,sum(m.home_team_score) as total_goals
from matches m where m.season = '2021-2022' group by m.season, m.home_team
union all
select m.season,m.away_team as team, sum(m.away_team_score) as total_goals
from matches m where m.season = '2021-2022' group by m.season, m.away_team) as combined
group by season, team order by sum(total_goals) desc limit 1;

--29.	How many teams have home stadiums in a each city or country?
select s.city, s.country, count(distinct t.team_name) as team_count
from teams t join stadiums s on t.home_stadium = s.name
group by s.city, s.country order by team_count desc;

--30.	Which teams had the most home wins in the 2021-2022 season?
select home_team, count(match_id) as home_wins
from matches where season = '2021-2022' and home_team_score > away_team_score
group by home_team order by home_wins desc;

					--Stadium Analysis 

--31.	Which stadium has the highest capacity?
select name as stadium, capacity from stadiums order by capacity desc limit 1;

--32.	How many stadiums are located in a ‘Russia’ country or ‘London’ city?
select count(*) as stadium_counts from stadiums where country = 'Russia' or city = 'London';

--33.	Which stadium hosted the most matches during a season?
select s.name as stadium, count(m.match_id) as match_count
from stadiums s join matches m on s.name = m.stadium
group by s.name order by match_count desc limit 1;

--34.	What is the average stadium capacity for teams participating in a each season?
select m.season, round(avg(s.capacity),2) as avg_capacity
from matches m join teams t on m.home_team = t.team_name
join stadiums s on t.home_stadium = s.name
group by m.season order by m.season, avg_capacity desc;

--35.	How many teams play in stadiums with a capacity of more than 50,000?
select count(distinct t.team_name) as teams_count
from teams t join stadiums s on t.home_stadium = s.name where s.capacity > 50000;

--36.	Which stadium had the highest attendance on average during a season?
select m.season, m.stadium, round(avg(m.attendance),2) as avg_attendance
from matches m group by m.season, m.stadium order by avg_attendance desc limit 1;

--37.	What is the distribution of stadium capacities by country?
select country, round(avg(capacity), 2) as avg_capacity, 
round(min(capacity), 2) as min_capacity, round(max(capacity), 2) as max_capacity
from stadiums group by country order by avg_capacity desc;


					--Cross-Table Analysis 

--38.	Which players scored the most goals in matches held at a specific stadium?
select s.name as stadium, p.first_name || ' ' || p.last_name as player_name, 
count(g.goal_id) as goals_scored from goals g
join matches m on g.match_id = m.match_id
join stadiums s on m.stadium = s.name
join players p on g.pid = p.player_id
group by s.name, p.first_name, p.last_name order by goals_scored desc limit 1;

--39.	Which team won the most home matches in the season 2021-2022 (based on match scores)?
select home_team, count(match_id) as home_wins 
from matches where season = '2021-2022' and home_team_score > away_team_score
group by home_team order by home_wins desc limit 1;

--40.	Which players played for a team that scored the most goals in the 2021-2022 season?
WITH team_goals AS (
select home_team as team, sum(home_team_score) + sum(away_team_score) as total_goals
from matches where season = '2021-2022' group by home_team
union all
select away_team as team, sum(home_team_score) + sum(away_team_score) as total_goals
from matches where season = '2021-2022'group by away_team),
 max_goals_team AS (select team from team_goals where total_goals = (select max(total_goals)
from team_goals)) select p.first_name || ' ' || p.last_name as player_name, p.team
from players p join max_goals_team mgt on p.team = mgt.team;

--41.	How many goals were scored by home teams in matches where the attendance was above 50,000?
select sum(home_team_score) as total_goals from matches where attendance > 50000;

--42.	Which players played in matches where the score difference (home team score - away team score) was the highest?
select p.first_name || ' ' || p.last_name as player_name
from players p join goals g on p.player_id = g.pid
join matches m on g.match_id = m.match_id
where abs(m.home_team_score - m.away_team_score) = (
select max(abs(home_team_score - away_team_score))
from matches) group by p.first_name, p.last_name;

--43.	How many goals did players score in matches that ended in penalty shootouts?
select count(g.goal_id) as total_goals
from goals g
join matches m on g.match_id = m.match_id
where m.penalty_shoot_out > 0;

--44. What is the distribution of home team wins vs away team wins by country for all seasons?
select t.country, 
       sum(case when m.home_team_score > m.away_team_score then 1 else 0 end) as home_team_wins,
       sum(case when m.away_team_score > m.home_team_score then 1 else 0 end) as away_team_wins
from matches m
join teams t on m.home_team = t.team_name or m.away_team = t.team_name
group by t.country;

--45.	Which team scored the most goals in the highest-attended matches?
select m.home_team, sum(case when m.home_team_score > m.away_team_score then m.home_team_score 
else m.away_team_score end) as total_goals
from matches m where m.attendance = (select max(attendance) from matches) 
group by m.home_team order by total_goals desc limit 1;

--46.Which players assisted the most goals in matches where their team lost(you can include 3)?
select p.first_name, p.last_name, count(g.goal_id) as total_assists
from players p join goals g on p.player_id = g.pid join matches m on g.match_id = m.match_id
where ((m.home_team = p.team and m.home_team_score < m.away_team_score) or 
(m.away_team = p.team and m.away_team_score < m.home_team_score))
group by p.first_name, p.last_name order by total_assists desc limit 3;

--47.	What is the total number of goals scored by players who are positioned as defenders?
select sum(goals) as total_goals
from (
    select count(g.goal_id) as goals
    from players p
    join goals g on p.player_id = g.pid
    where p.position = 'Defender'
    group by p.player_id
) as defender_goals;

--48.Which players scored goals in matches that were held in stadiums with a capacity over 60,000?
select distinct p.player_id, concat(p.first_name, ' ', p.last_name) as player_name
from players p
join goals g on p.player_id = g.pid
join matches m on g.match_id = m.match_id
join stadiums s on m.stadium = s.name
where s.capacity > 60000;

--49.	How many goals were scored in matches played in cities with specific stadiums in a season?
select m.season, s.city, count(g.goal_id) as total_goals
from matches m
join goals g on m.match_id = g.match_id
join stadiums s on m.stadium = s.name
group by m.season, s.city;

--50.	Which players scored goals in matches with the highest attendance (over 100,000)?
select p.player_id, concat(p.first_name, ' ', p.last_name) as player_name, 
count(g.goal_id) as total_goals from goals g join players p on g.pid = p.player_id
join matches m on g.match_id = m.match_id where m.attendance > 100000
group by p.player_id, player_name order by total_goals desc;


			--Additional Complex Queries 

--51.	What is the average number of goals scored by each team in the first 30 minutes of a match?
select m.home_team, m.away_team, 
round(avg(case when g.duration <= 30 then 1 else 0 end), 2) as avg_goals_first_30
from goals g join matches m on g.match_id = m.match_id group by m.home_team, m.away_team;

--52.	Which stadium had the highest average score difference between home and away teams?
select m.stadium, 
round(avg(m.home_team_score - m.away_team_score), 2) as avg_score_difference
from matches m group by m.stadium order by avg_score_difference desc limit 1;

--53.	How many players scored in every match they played during a given season?
select p.player_id, concat(p.first_name, ' ', p.last_name) as player_name
from players p
join goals g on p.player_id = g.pid
join matches m on g.match_id = m.match_id
group by p.player_id, p.first_name, p.last_name
having count(distinct g.match_id) = 
    (select count(distinct match_id) 
     from matches 
     where home_team = p.team or away_team = p.team);

--54.	Which teams won the most matches with a goal difference of 3 or more in the 2021-2022 season?
select home_team, count(*) as win_count
from matches
where season = '2021-2022' 
  and (home_team_score - away_team_score) >= 3
group by home_team
order by win_count desc
limit 1;

--55.	Which player from a specific country has the highest goals per match ratio?
select p.first_name, p.last_name, p.nationality, 
       sum(CASE WHEN g.goal_id IS NOT NULL THEN 1 ELSE 0 END)::float / count(distinct m.match_id) as goals_per_match
from players p
join goals g on p.player_id = g.pid
join matches m on g.match_id = m.match_id
where p.nationality = 'Russia'
group by p.first_name, p.last_name, p.nationality
order by goals_per_match desc
limit 1;






















