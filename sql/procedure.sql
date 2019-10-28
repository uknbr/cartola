SHOW PROCEDURE STATUS;
SHOW FUNCTION STATUS;

------------------------------------------------------------------------
-- sp_get_round_latest
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_get_round_latest //
CREATE PROCEDURE sp_get_round_latest()
	select max(R.id) as LATEST_ROUND from round R
//

call sp_get_round_latest;

------------------------------------------------------------------------
-- sp_html_rounds
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_html_rounds //
CREATE PROCEDURE sp_html_rounds()
select concat('Dados disponíveis: Rodada ',min(R.id),' até Rodada ',max(R.id)) AS sp_html_rounds from round R
//

call sp_html_rounds();

------------------------------------------------------------------------
-- sp_html_now
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_html_now //
CREATE PROCEDURE sp_html_now()
select concat('Atualizado em: ',DATE_FORMAT(now(), '%d/%m/%Y %H:%i:%s')) AS sp_html_now
//

call sp_html_now();

------------------------------------------------------------------------
-- sp_report_top5_position
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_report_top5_position //
CREATE PROCEDURE sp_report_top5_position(IN p_position CHAR(3), IN r_count INT)
	select distinct 
			T.name as TIME,
			P.name as JOGADOR,
			(select count(Ro.player_id) from round Ro where Ro.player_id = R.player_id) as JOGOS,      
			(select Rn.player_value from round Rn where Rn.player_id = R.player_id and Rn.id = (select max(Rn.id) from round Rn where Rn.player_id = R.player_id)) as VALOR,
			(select round(avg(Ro.player_score),2) from round Ro where Ro.player_id = R.player_id and Ro.valid = 1) as MEDIA
	from round R
	inner join player P on P.id = R.player_id
	inner join team T on T.id = P.id_team
	where (select count(Ro.player_id) from round Ro where Ro.player_id = R.player_id) >= r_count
				and P.position = p_position
	order by 5 desc
	limit 5;
//

call sp_report_top5_position('ZAG', 5);

------------------------------------------------------------------------
-- sp_html_top5_position
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_html_top5_position //
CREATE PROCEDURE sp_html_top5_position(IN p_position CHAR(3), IN r_count INT)
	select distinct 
           concat('<tr><td><b><font size="2" color="#000000">%position_number%</font></b></td><td><img src="img/team/team_XX00', T.id,'.png" style="width:32px;height:32px;"></td><td>', T.name,'</td><td>', P.name, '</td><td>', (select count(Ro.player_id) from round Ro where Ro.player_id = R.player_id), '</td><td><font size="3" color="#CC0000">C$ ', (select Rn.player_value from round Rn where Rn.player_id = R.player_id and Rn.id = (select max(Rn.id) from round Rn where Rn.player_id = R.player_id)), '</font></td><td><font size="3" color="#000099">', (select round(avg(Ro.player_score),2) from round Ro where Ro.player_id = R.player_id and Ro.valid = 1), '</font></td></tr>') as result
	from round R
	inner join player P on P.id = R.player_id
	inner join team T on T.id = P.id_team
	where (select count(Ro.player_id) from round Ro where Ro.player_id = R.player_id) >= r_count
		  and P.position = p_position
	order by (select round(avg(Ro.player_score),2) from round Ro where Ro.player_id = R.player_id and Ro.valid = 1) desc
	limit 5;
//

call sp_html_top5_position('ZAG', 5);

------------------------------------------------------------------------
-- sp_report_player_performance_round_desc
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_report_player_performance_round_desc //
CREATE PROCEDURE sp_report_player_performance_round_desc(IN round_number INT(2))
	select P.name as JOGADOR,
			  T.name as `TIME`,
			  P.position as POSICAO,
		      round(R.player_score,2) as PONTOS,
	          (select concat((select T.name from `team` T where id = M.team_id_home), ' ', ifnull(M.team_home_goals,'?'), ' x ', ifnull(M.team_away_goals,'?'), ' ', (select T.name from `team` T where id = M.team_id_away)) as confronto
                 from `match` M
                where M.round_id = R.id
                   and (M.team_id_home = P.id_team or M.team_id_away = P.id_team)) as JOGO
	from team T
	inner join player P on P.id_team = T.id
	inner join round R on R.player_id = P.id
	where R.id = round_number
	order by 4 desc
	limit 5;
//

------------------------------------------------------------------------
-- sp_html_player_performance_round_desc
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_html_player_performance_round_desc //
CREATE PROCEDURE sp_html_player_performance_round_desc(IN round_number INT(2))
	select concat('<tr><td><b><font size="2" color="#000000">%position_number%</font></b></td><td>', P.name, '</td><td>', T.name, '</td><td>', P.position, '</td><td><font size="3" color="#000099">', round(R.player_score,2), '</font></td><td><img src="img/team/team_XX00', (select concat(M.team_id_home, '.png" style="width:32px;height:32px;"> ', ifnull(M.team_home_goals,'?'), ' x ', ifnull(M.team_away_goals,'?'), ' <img src="img/team/team_XX00', M.team_id_away, '.png" style="width:32px;height:32px;">') from `match` M where M.round_id = R.id and (M.team_id_home = P.id_team or M.team_id_away = P.id_team)), '</td></tr>') as result
	  from team T
	 inner join player P on P.id_team = T.id
	 inner join round R on R.player_id = P.id
	 where R.id = round_number
	 order by round(R.player_score,2) desc
	 limit 5;
//

------------------------------------------------------------------------
-- sp_report_player_performance_round_asc
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_report_player_performance_round_asc //
CREATE PROCEDURE sp_report_player_performance_round_asc(IN round_number INT(2))
	select P.name as JOGADOR,
			  T.name as `TIME`,
			  P.position as POSICAO,
		      round(R.player_score,2) as PONTOS,
	          (select concat((select T.name from `team` T where id = M.team_id_home), ' ', ifnull(M.team_home_goals,'?'), ' x ', ifnull(M.team_away_goals,'?'), ' ', (select T.name from `team` T where id = M.team_id_away)) as confronto
                 from `match` M
                where M.round_id = R.id
                   and (M.team_id_home = P.id_team or M.team_id_away = P.id_team)) as JOGO
	from team T
	inner join player P on P.id_team = T.id
	inner join round R on R.player_id = P.id
	where R.id = round_number
	order by 4 asc
	limit 5;
//

------------------------------------------------------------------------
-- sp_html_player_performance_round_asc
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_html_player_performance_round_asc //
CREATE PROCEDURE sp_html_player_performance_round_asc(IN round_number INT(2))
	select concat('<tr><td><b><font size="2" color="#000000">%position_number%</font></b></td><td>', P.name, '</td><td>', T.name, '</td><td>', P.position, '</td><td><font size="3" color="#CC0000">', round(R.player_score,2), '</font></td><td><img src="img/team/team_XX00', (select concat(M.team_id_home, '.png" style="width:32px;height:32px;"> ', ifnull(M.team_home_goals,'?'), ' x ', ifnull(M.team_away_goals,'?'), ' <img src="img/team/team_XX00', M.team_id_away, '.png" style="width:32px;height:32px;">') from `match` M where M.round_id = R.id and (M.team_id_home = P.id_team or M.team_id_away = P.id_team)), '</td></tr>') as result
	  from team T
	 inner join player P on P.id_team = T.id
	 inner join round R on R.player_id = P.id
	 where R.id = round_number
	 order by round(R.player_score,2) asc
	 limit 5;
//

------------------------------------------------------------------------
-- sp_report_player_performance_all_desc
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_report_player_performance_all_desc //
CREATE PROCEDURE sp_report_player_performance_all_desc(IN round_end INT(2))
	select P.name as JOGADOR,
			  T.name as `TIME`,
			  P.position as POSICAO,
			  R.id as RODADA,
		      round(R.player_score,2) as PONTOS,
	          (select concat((select T.name from `team` T where id = M.team_id_home), ' ', ifnull(M.team_home_goals,'?'), ' x ', ifnull(M.team_away_goals,'?'), ' ', (select T.name from `team` T where id = M.team_id_away), ' - ', date_format(M.date_time, '%d/%m/%Y às %H:%i')) as confronto
                 from `match` M
                where M.round_id = R.id
                   and (M.team_id_home = P.id_team or M.team_id_away = P.id_team)) as JOGO
	from team T
	inner join player P on P.id_team = T.id
	inner join round R on R.player_id = P.id
	where R.id >= 1 and R.id <= round_end
	order by 5 desc
	limit 10;
//

call sp_report_player_performance_all_desc(38);

------------------------------------------------------------------------
-- sp_html_player_performance_all_desc
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_html_player_performance_all_desc //
CREATE PROCEDURE sp_html_player_performance_all_desc(IN round_end INT(2))
	select concat('<tr><td><b><font size="2" color="#000000">%position_number%</font></b></td><td>', P.name, '</td><td>', T.name, '</td><td>', P.position, '</td><td>', R.id, '</td><td>', round(R.player_score,2), '</td><td>', (select concat('<img src="img/team/team_XX00', M.team_id_home, '.png" style="width:32px;height:32px;"> ', ifnull(M.team_home_goals,'?'), ' x ', ifnull(M.team_away_goals,'?'), ' <img src="img/team/team_XX00', M.team_id_away, '.png" style="width:32px;height:32px;"> - ', date_format(M.date_time, '%d/%m/%Y às %H:%i')) from `match` M where M.round_id = R.id and (M.team_id_home = P.id_team or M.team_id_away = P.id_team)), '</td></tr>') as sp_report_player_performance_all_desc
	from team T
	inner join player P on P.id_team = T.id
	inner join round R on R.player_id = P.id
	where R.id >= 1 and R.id <= round_end
	order by round(R.player_score,2) desc
	limit 10;
//

call sp_html_player_performance_all_desc(38);

------------------------------------------------------------------------
-- sp_report_player_performance_all_asc
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_report_player_performance_all_asc //
CREATE PROCEDURE sp_report_player_performance_all_asc(IN round_end INT(2))
	select P.name as JOGADOR,
			  T.name as `TIME`,
			  P.position as POSICAO,
			  R.id as RODADA,
		      round(R.player_score,2) as PONTOS,
	          (select concat((select T.name from `team` T where id = M.team_id_home), ' ', ifnull(M.team_home_goals,'?'), ' x ', ifnull(M.team_away_goals,'?'), ' ', (select T.name from `team` T where id = M.team_id_away), ' - ', date_format(M.date_time, '%d/%m/%Y às %H:%i')) as confronto
                 from `match` M
                where M.round_id = R.id
                   and (M.team_id_home = P.id_team or M.team_id_away = P.id_team)) as JOGO
	from team T
	inner join player P on P.id_team = T.id
	inner join round R on R.player_id = P.id
	where R.id >= 1 and R.id <= round_end
	order by 5 asc
	limit 10;
//

------------------------------------------------------------------------
-- sp_html_player_performance_all_asc
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_html_player_performance_all_asc //
CREATE PROCEDURE sp_html_player_performance_all_asc(IN round_end INT(2))
	select concat('<tr><td><b><font size="2" color="#000000">%position_number%</font></b></td><td>', P.name, '</td><td>', T.name, '</td><td>', P.position, '</td><td>', R.id, '</td><td>', round(R.player_score,2), '</td><td>', (select concat('<img src="img/team/team_XX00', M.team_id_home, '.png" style="width:32px;height:32px;"> ', ifnull(M.team_home_goals,'?'), ' x ', ifnull(M.team_away_goals,'?'), ' <img src="img/team/team_XX00', M.team_id_away, '.png" style="width:32px;height:32px;"> - ', date_format(M.date_time, '%d/%m/%Y às %H:%i')) from `match` M where M.round_id = R.id and (M.team_id_home = P.id_team or M.team_id_away = P.id_team)), '</td></tr>') as sp_report_player_performance_all_desc
	from team T
	inner join player P on P.id_team = T.id
	inner join round R on R.player_id = P.id
	where R.id >= 1 and R.id <= round_end
	order by round(R.player_score,2) asc
	limit 10;
//

call sp_html_player_performance_all_asc(38);

------------------------------------------------------------------------
-- sp_report_round_standing_desc
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_report_round_standing_desc //
CREATE PROCEDURE sp_report_round_standing_desc(IN round_number INT(2))
select T.name as `TIME`, round(sum(R.player_score),2) as `PONTOS`
  from team T
 inner join player P on P.id_team = T.id
 inner join round R on P.id = R.player_id
 where R.id = round_number
 group by T.name
 order by 2 desc
  limit 5;
//

------------------------------------------------------------------------
-- sp_html_round_standing_desc
------------------------------------------------------------------------
DELIMITER //

DROP PROCEDURE IF EXISTS sp_html_round_standing_desc //
CREATE PROCEDURE sp_html_round_standing_desc(IN round_number INT(2))
select concat('<tr><td><b><font size="2" color="#000000">%position_number%</font></b></td><td><img src="img/team/team_XX00',T.id,'.png" style="width:32px;height:32px;"></td><td>',T.name,'</td><td><font size="3" color="#000099">',round(sum(R.player_score),2),'</font></td></tr>') AS sp_html_round_all_standing 
 from team T 
  join player P on P.id_team = T.id 
  join round R on P.id = R.player_id 
where R.id = round_number
  group by T.name 
  order by sum(R.player_score) desc
  limit 5
//

------------------------------------------------------------------------
-- sp_report_round_standing_asc
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_report_round_standing_asc //
CREATE PROCEDURE sp_report_round_standing_asc(IN round_number INT(2))
select T.name as `TIME`, round(sum(R.player_score),2) as `PONTOS`
  from team T
 inner join player P on P.id_team = T.id
 inner join round R on P.id = R.player_id
 where R.id = round_number
 group by T.name
 order by 2 asc
  limit 5;
//

------------------------------------------------------------------------
-- sp_html_round_standing_asc
------------------------------------------------------------------------
DELIMITER //

DROP PROCEDURE IF EXISTS sp_html_round_standing_asc //
CREATE PROCEDURE sp_html_round_standing_asc(IN round_number INT(2))
select concat('<tr><td><b><font size="2" color="#000000">%position_number%</font></b></td><td><img src="img/team/team_XX00',T.id,'.png" style="width:32px;height:32px;"></td><td>',T.name,'</td><td><font size="3" color="#CC0000">',round(sum(R.player_score),2),'</font></td></tr>') AS sp_html_round_all_standing 
 from team T 
  join player P on P.id_team = T.id 
  join round R on P.id = R.player_id 
where R.id = round_number
  group by T.name 
  order by sum(R.player_score) asc
  limit 5
//

------------------------------------------------------------------------
-- sp_report_round_all_standing
------------------------------------------------------------------------
DELIMITER //
  
DROP PROCEDURE IF EXISTS sp_report_round_all_standing //
CREATE PROCEDURE sp_report_round_all_standing()
select T.name as `TIME`, round(sum(R.player_score),2) as `PONTOS`
  from team T
 inner join player P on P.id_team = T.id
 inner join round R on P.id = R.player_id
 group by T.name
 order by 2 desc;
//

------------------------------------------------------------------------
-- sp_html_round_all_standing
------------------------------------------------------------------------
DELIMITER //

DROP PROCEDURE IF EXISTS sp_html_round_all_standing //
CREATE PROCEDURE sp_html_round_all_standing()
select concat('<tr><td><b><font size="%font_size%" color="%font_color%">%position_number%</font></b></td><td><img src="img/team/team_XX00',T.id,'.png" style="width:32px;height:32px;"></td><td>',T.name,'</td><td>',round(sum(R.player_score),2),'</td></tr>') AS sp_html_round_all_standing 
 from team T 
  join player P on P.id_team = T.id 
  join round R on P.id = R.player_id 
 group by T.name 
 order by sum(R.player_score) desc;
//

------------------------------------------------------------------------
-- sp_html_standings
------------------------------------------------------------------------
DELIMITER //

DROP PROCEDURE IF EXISTS sp_html_standings //
CREATE PROCEDURE sp_html_standings()
select concat('<tr><td><b><font size="%font_size%" color="%font_color%">%position_number%</font></b></td><td><img src="img/team/team_XX00',`T`.`id`,'.png" style="width:32px;height:32px;"></td><td>',`T`.`name`,'</td><td><font size="3" color="#000000">',round(sum(`R`.`player_score`),2),'</font></td></tr>') AS sp_html_standings
  from team T 
  join player P on P.id_team = T.id
  join round R on P.id = R.player_id
 group by T.name order by sum(R.player_score) desc
//

call sp_html_standings();

------------------------------------------------------------------------
-- sp_html_standings_round
------------------------------------------------------------------------
DELIMITER //

DROP PROCEDURE IF EXISTS sp_html_standings_round //
CREATE PROCEDURE sp_html_standings_round(IN round_number INT(2), IN team_number INT(2))
select concat('Ultima Rodada: ', round(sum(`R`.`player_score`),2)) as sp_html_standings_round
  from team T 
  join player P on P.id_team = T.id
  join round R on P.id = R.player_id
 where T.id = team_number and R.id = round_number
 group by T.name
order by sum(R.player_score) desc;
//

call sp_html_standings_round(19, 19);

------------------------------------------------------------------------
-- sp_html_shots
------------------------------------------------------------------------
DELIMITER //

DROP PROCEDURE IF EXISTS sp_html_shots //
CREATE PROCEDURE sp_html_shots()
select concat('[''', P.name, ' (', P.position, ')'', ', max(S.fd), ',', max(S.ff), ',', max(S.ft), '],') as `sp_html_shots`
  from stat S
 inner join player P on P.id = S.player_id
 group by P.name
 order by max(S.fd) desc
  limit 5;
//

call sp_html_shots();

------------------------------------------------------------------------
-- sp_html_goals
------------------------------------------------------------------------
DELIMITER //

DROP PROCEDURE IF EXISTS sp_html_goals //
CREATE PROCEDURE sp_html_goals()
select concat('[''', P.name, ' (', P.position, ')'', ', max(S.g), ',', max(S.i), '],') as `sp_html_goals`
  from stat S
 inner join player P on P.id = S.player_id
 group by P.name
 order by max(S.g) desc
  limit 5;
//

call sp_html_goals();

------------------------------------------------------------------------
-- sp_html_assists
------------------------------------------------------------------------
DELIMITER //

DROP PROCEDURE IF EXISTS sp_html_assists //
CREATE PROCEDURE sp_html_assists()
select concat('[''', P.name, ' (', P.position, ')'', ', max(S.a), '],') as `sp_html_assists`
  from stat S
 inner join player P on P.id = S.player_id
 group by P.name
 order by max(S.a) desc
  limit 5;  
//

call sp_html_assists();



  
