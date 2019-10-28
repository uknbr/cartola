-- Top 5 player latest round
select P.name, R.player_score
  from round R
 inner join player P on R.player_id = P.id
where R.id = (select max(id) from round)
 order by player_score desc
   limit 5;

-- Player average and value by team   
select P.name as JOGADOR,
 P.position as POSICAO,
 (select round(avg(player_value),2) from round where player_id = P.id) as VALOR,
 (select round(avg(player_score),2) from round where player_id = P.id) as MEDIA
  from team T
 inner join player P on P.id_team = T.id
  where T.name like '%Preta%'
order by 4 desc;

-- Complete status by position
select P.name as JOGADOR,
          T.name as `TIME`,
          P.creation_date as DATA,
	  P.position as POSICAO,
	  (select count(player_id ) from round where player_id = P.id) as JOGOS,
          (select round(avg(player_value),2) from round where player_id = P.id) as VALOR,
	  (select round(avg(player_score),2) from round where player_id = P.id) as MEDIA
  from team T
 inner join player P on P.id_team = T.id
  where P.position like '%TEC%'
order by 7 desc;

-- Matches details
select M.round_id as RODADA,
           (select T.name from team T where T.id = M.team_id_home) as TIME_CASA,
           (select T.name from team T where T.id = M.team_id_away) as TIME_FORA,
           concat(ifnull(M.team_home_goals, '?'), ' x ', ifnull(M.team_away_goals, '?')) as SCORE
  from `match` M
where M.round_id <= (select max(R.id) from round R)
 order by M.round_id asc;
 
-- Rounds
select distinct R.id as RODADA, R.date -1 as DATA from round R;

​​-- Artilheiros
select P.name as JOGADOR, max(S.g) as GOLS
  from stat S
 inner join player P on P.id = S.player_id
 where S.g is not null
 group by P.name
 order by 2 desc
  limit 10;

​​-- TOP5
select P.name as JOGADOR,
          T.name as `TIME`,
	  P.position as POSICAO,
          R.player_value as VALOR,
	  R.player_score as PONTOS,
	  (select concat((select T.name from `team` T where id = M.team_id_home), ' ', ifnull(M.team_home_goals,'?'), ' x ', ifnull(M.team_away_goals,'?'), ' ', (select T.name from `team` T where id = M.team_id_away)) as confronto
         from `match` M
       where M.round_id = 5
          and (M.team_id_home = P.id_team or M.team_id_away = P.id_team)) as JOGO
  from team T
 inner join player P on P.id_team = T.id
 inner join round R on R.player_id = P.id
 where R.id = 5
order by 5 desc
  limit 5;
  
select P.name as JOGADOR,
 P.position as POSICAO,
 T.name as TIME,
 (select count(player_id) from round where player_id = P.id) as JOGOS,
 (select round(avg(player_score),2) from round where player_id = P.id and player_score != 0) as MEDIA
  from team T
 inner join player P on P.id_team = T.id
 where P.position = 'ATA' and (select count(player_id) from round where player_id = P.id) > 4
order by 5 desc
 limit 5;
  
-- ranking
select T.name as `TIME`, sum(R.player_score) as `PONTOS`
  from team T
 inner join player P on P.id_team = T.id
 inner join round R on P.id = R.player_id
 group by T.name
 order by 2 desc;

select T.name as `TIME`, sum(R.player_score) as `PONTOS`
  from team T
 inner join player P on P.id_team = T.id
 inner join round R on P.id = R.player_id
 where R.id = (select max(R.id) from round R)
 group by T.name
 order by 2 desc
  limit 5;

-- Find out which match is missing
select * from round R where R.id = 7 and R.player_id in (select P.id from player P where P.id_team in (select T.id from team T where T.id not in (select M.team_id_away from `match` M where M.round_id = 7 union select M.team_id_home from `match` M where M.round_id = 7)));

select concat('update round set valid = 0 where id = ', R.id, ' and player_id = ', R.player_id, ';') as 'SQL STATEMENT' from round R where R.id = 7 and R.player_id in (select P.id from player P where P.id_team in (select T.id from team T where T.id not in (select M.team_id_away from `match` M where M.round_id = 7 union select M.team_id_home from `match` M where M.round_id = 7)));

-- Set round as invalid
select concat('update round set valid = 0 where id = ', R.id, ' and player_id = ', R.player_id, ';') from round R where R.id = 16 and R.player_id in (select id from player where id_team in (1,5,18,20));


-- database size
--Here’s the SQL script to list out the entire databases size
SELECT table_schema "Data Base Name", SUM( data_length + index_length) / 1024 / 1024 
"Data Base Size in MB" FROM information_schema.TABLES GROUP BY table_schema ;

-- Another SQL script to list out one database size, and each tables size in detail
SELECT TABLE_NAME, table_rows, data_length, index_length, 
round(((data_length + index_length) / 1024 / 1024),2) "Size in MB"
FROM information_schema.TABLES WHERE table_schema = "schema_name";
