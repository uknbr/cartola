#!/bin/bash
#===============================================================
# NAME      :  cartola_html.sh
# Programmer:  Pedro Pavan
# Date      :  27-June-2015
# Purpose   :  Generate HTML files
#
# Changes history:
#
#  By     |    Date       |  Changes/New features
# ----------+-------------+-------------------------------------
# Pedro	      06-27-2015    Initial release
# Pedro	      06-28-2015    Home page
# Pedro	      07-09-2015    Standing page
# Pedro	      07-15-2015    Top5 page
# Pedro	      07-20-2015    Deployment package
# Pedro	      07-26-2015    Best page
# Pedro	      07-28-2015    Record page
# Pedro	      08-03-2015    Chart page
# Pedro	      04-13-2016    Current season
#===============================================================

# =======================
#  Variables
# =======================
DB_CONF="../conf/db.conf"
LOG_FILE="../log/html.log"
HTML_SITE_URL="www.MYHOST/cartola"
HTML_DIR="../html_dev"
HTML_WORK="${HTML_DIR}/work"
HTML_PAGE_HOME="${HTML_WORK}/home.html"
HTML_PAGE_STANDING="${HTML_WORK}/standing.html"
HTML_PAGE_TOP5="${HTML_WORK}/top5.html"
HTML_PAGE_BEST="${HTML_WORK}/best.html"
HTML_PAGE_RECORD="${HTML_WORK}/record.html"
HTML_PAGE_CHART="${HTML_WORK}/chart.html"
TMP_FILE="$(mktemp ../tmp/tmp_cartola_html.XXXXXXXXXX)"
TMP_DIR="deploy_tmp"

> ${LOG_FILE}
MYSQL_CONN=""
CURRENT_ROUND=""
CURRENT_SEASON=$(date +'%Y')
#CURRENT_SEASON="2015"

# =======================
#  Border
# =======================
Border() {
	TYPE=$1
	TIME=$(date '+%F %T')
	NEWLINE="?"
	
	echo -e "================================"
	echo -e "  ${TYPE} time - ${TIME}"
	echo -e "================================"
	
	[ "${TYPE}" == "Start" ] && NEWLINE="\n" || NEWLINE=""
	echo -e "${NEWLINE}***************** $(basename $0) [${TIME}] *****************" >> ${LOG_FILE}
}

# =======================
#  Check DB status
# =======================
Check_DB_Conn() {
	echo "show status;" | mysql -N -B ${MYSQL_CONN} 2> /dev/null | grep -w "Uptime" >> ${LOG_FILE} 2>&1
	
	if [ $? -eq 0 ]; then
		Message -info "Connection working [$(hostname) <---> MYHOST]"
		CURRENT_ROUND=$(Get_Latest_Round)
	else
		Message -fail "Fail to connect to MYHOST"
		Exit_Script 2
	fi
}

# =======================
#  Get Latest Round
# =======================
Get_Latest_Round() {
	RESULT=$(echo "call sp_get_round_latest();" | mysql -N -B ${MYSQL_CONN} 2> /dev/null)
	echo ${RESULT}
}

# =======================
#  Get Minimum Rounds
# =======================
Get_Min_Round() {
	RESULT=$(expr ${CURRENT_ROUND} - 3)
	RESULT=$(expr ${RESULT} \* 75)
	RESULT=$(expr ${RESULT} / 100)
	
	echo ${RESULT}
}

# =======================
#  Set Global Parameters
# =======================
Set_Params() {
	Message -info "Setting Global Parameters"
	
	MYSQL_CONN="$(Get_DB_Param)"
}

# =======================
#  Site Deployment
# =======================
Site_Deployment() {
	Message -info "Deploying site (round ${CURRENT_ROUND})"
	
	# round folder
	cp -rf ${HTML_WORK}/* ${HTML_DIR}/${CURRENT_ROUND}/
	cd ${HTML_DIR}/${CURRENT_ROUND}
	unlink index.html 2> /dev/null
	ln -sf $(basename ${HTML_PAGE_HOME}) index.html
	cd - > /dev/null 2>&1
	cd ${HTML_DIR}/
	unlink site 2> /dev/null
	ln -sf ${CURRENT_ROUND} site
	cd - > /dev/null 2>&1
	
	# package
	cd ${HTML_DIR}/
	mkdir ${TMP_DIR}
	cp -rf ${CURRENT_ROUND}/* ${TMP_DIR}/
	cd ${TMP_DIR}/
	find . -type f -name '*.html' | xargs sed -i "s/href=\"\//href=\"\/cartola\//g"
	rm -f ../deploy/deploy${CURRENT_ROUND}.tar.gz 2> /dev/null
	tar -czvf ../deploy/deploy${CURRENT_ROUND}.tar.gz * > /dev/null 2>&1
	cd ../
	rm -rf ${TMP_DIR}/
	cd - > /dev/null 2>&1
}

# =======================
#  Get DB parameters
# =======================
Get_DB_Param() {
	if [ -f ${DB_CONF} ]; then
		CONN_USER=$(grep MYSQL_USER ${DB_CONF} | cut -d '=' -f 2)
		CONN_HOST=$(grep MYSQL_HOST ${DB_CONF} | cut -d '=' -f 2)
		CONN_PASS=$(grep MYSQL_PASS ${DB_CONF} | cut -d '=' -f 2)
		CONN_PORT=$(grep MYSQL_PORT ${DB_CONF} | cut -d '=' -f 2)
		CONN_INST=$(grep MYSQL_INST ${DB_CONF} | cut -d '=' -f 2)
		echo "--user=${CONN_USER} --host=${CONN_HOST} --password=${CONN_PASS} --port=${CONN_PORT} ${CONN_INST}"
	else 
		Message -fail "File not found (${DB_CONF})"
		Exit_Script 2
	fi
}

# =======================
#  Message
# =======================
Message() {
	MSG_TYPE="$1"
	MSG="$2"
	
	case "${MSG_TYPE}" in
		"-info")	echo "[+] ${MSG}" | tee -a ${LOG_FILE}	;;
		"-fail")	echo "[!] ${MSG}" | tee -a ${LOG_FILE}	;;
		"-more")	echo "[*] ${MSG}" | tee -a ${LOG_FILE}	;;
		      *)	echo "[-] ${MSG}" | tee -a ${LOG_FILE}	;;
	esac
}

# =======================
#  Exit
# =======================
Exit_Script() {
	EXIT_CODE=$1
	
	rm ../tmp/tmp_cartola_html.*
	Border "Finish"
	exit ${EXIT_CODE}
}

# =======================
#  HTML head
# =======================
HTML_Head() {
	FILE=$1
	
	echo -e "
<!DOCTYPE html>
<html lang=\"pt-BR\">
<head>
    <meta charset=\"utf-8\">
    <title>Brasileirão Cartola</title>

    <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">

    <meta name=\"author\" content=\"Pedro Pavan\" >
    <link rel=\"shortcut icon\" href=\"img/ball.png\">

    <link rel=\"stylesheet\" href=\"cartola.css\">
</head> " >> ${FILE}
}

# =======================
#  HTML body (menu)
# =======================
HTML_Menu() {
	FILE=$1

	echo -e "
<body>

<div id=\"top\" class=\"bar bar-compact\">
    <table>
        <tr>
            <td id=\"site-logo\">
                <a href=\"/\"><img src=\"img/cartola.png\"></a>
            </td>
            <td>
                <div id=\"site-name\">
                    <a href=\"/\">BRASILEIRÃO CARTOLA $(date '+%Y')</a>
                </div>
                <div id=\"site-menu\">
                    <a href=\"/index.html\">início</a>
                    <a href=\"/standing.html\">tabela</a>
                    <a href=\"/top5.html\">top5</a>
                    <a href=\"/best.html\">destaque</a>
                    <a href=\"/record.html\">recordes</a>
				    <a href=\"/chart.html\">gráficos</a>
                    <a href=\"/about.html\">sobre</a>
                </div>
            </td>
        </tr>
    </table>
</div>

<div id=\"main\" class=\"bar\">" >> ${FILE}
}

# =======================
#  HTML end
# =======================
HTML_End() {
	FILE=$1
	
	echo -e "
</div>

</body>
</html>" >> ${FILE}
}

# =======================
#  HTML body (menu)
# =======================
HTML_Share() {
	FILE=$1

	echo -e "
	<p>Curtiu? Compartilhe com seus amigos cartoleiros!</p>
	
	<br>
	<center>
		<a href=\"https://www.facebook.com/sharer/sharer.php?u=${HTML_SITE_URL}\"><img src=\"img/facebook.png\" alt=\"Facebook\" style=\"width:42px;height:42px;border:0;\"></a>
		<a href=\"https://twitter.com/home?status=${HTML_SITE_URL}\"><img src=\"img/twitter.png\" alt=\"Twitter\" style=\"width:42px;height:42px;border:0;\"></a>
		<a href=\"https://plus.google.com/share?url=${HTML_SITE_URL}\"><img src=\"img/google+.png\" alt=\"Goodle Plus\" style=\"width:42px;height:42px;border:0;\"></a>
	</center>" >> ${FILE}
}

# =======================
#  Build home page
# =======================
Build_Home() {
	Message -info "Building page ($(basename ${HTML_PAGE_HOME}))"
	> ${HTML_PAGE_HOME}
	
	HTML_Head ${HTML_PAGE_HOME}
	HTML_Menu ${HTML_PAGE_HOME}
	
	DB_DATA_NOW=$(echo "call sp_html_now();" | mysql -N -B ${MYSQL_CONN} 2> /dev/null)
	DB_DATA_ROUND=$(echo "call sp_html_rounds();" | mysql -N -B ${MYSQL_CONN} 2> /dev/null)
	
	echo -e "
    <div id=\"header\">
		  <img style=\"display: inline;\" src=\"img/bench.png\" alt=\"Início\" />
		  <h1 style=\"display: inline;\">Início</h1>
    </div>

    <div id=\"content\">
		<div class=\"alert\">
			${DB_DATA_NOW}
		</div>

		<div class=\"banner\">
			${DB_DATA_ROUND}
		</div>

		<p>Este site foi feito para você cartoleiro que esta afim de ficar por dentro de tudo que acontece no Brasileirão. Acompanhe os destaques da última rodada bem como  as estatísticas dos jogares para auxiliar na escação do seu time.</p>
	</div>" >> ${HTML_PAGE_HOME}
	
	HTML_Share ${HTML_PAGE_HOME}
	HTML_End ${HTML_PAGE_HOME}
}

# =======================
#  Build home page
# =======================
Build_Standing() {
	Message -info "Building page ($(basename ${HTML_PAGE_STANDING}))"
	> ${HTML_PAGE_STANDING}
	
	HTML_Head ${HTML_PAGE_STANDING}
	HTML_Menu ${HTML_PAGE_STANDING}
	
	echo -e "
    <div id=\"header\">
		  <img style=\"display: inline;\" src=\"img/standing.png\" alt=\"Tabela\" />
		  <h1 style=\"display: inline;\">Tabela</h1>
    </div>
    " >> ${HTML_PAGE_STANDING}
		
	echo "call sp_html_standings(${CURRENT_SEASON});" | mysql -N -B ${MYSQL_CONN} 2> /dev/null > ${TMP_FILE}
	
	echo -e "
	<div id=\"content\">
		<p>Já imaginou como seria a classificação do brasileirão baseado na pontuação do cartola? Confira abaixo o resultado (rodada <b>${CURRENT_ROUND}</b>) com a somatória de todos jogares e compare com a classificação original.
			
		<table class=\"flat-table\">
		<tbody>
			<tr><th> </th><th> </th><th>TIME</th><th>PONTOS</th></tr>" >> ${HTML_PAGE_STANDING}
		
	count=0
	while read line
	do
		count=$(expr ${count} + 1)
		
		case $count in
		1|2|3|4)		
			font_color="#000099"
			font_size="3"
		;;
	
		17|18|19|20)	
			font_color="#CC0000"
			font_size="3"
		;;
	
		*)
			font_color="#000000"
			font_size="2"
		;;		
		esac

		#TEAM_ID=$(echo "${line}" | cut -d '"' -f 6 | tr -d '/' | tr -d '.' | tr -d '_' | tr -d '0' | tr '[A-Z]' '[a-z]' | tr -d '[a-z]')
		#TEAM_INFO=$(echo "call sp_html_standings_round(${CURRENT_ROUND}, ${TEAM_ID});" | mysql -N -B ${MYSQL_CONN} 2> /dev/null)
		#echo -e "Rodada#${CURRENT_ROUND}: ${TEAM_ID}" 
		
		echo "${line}" | sed "s/%position_number%/${count}/g" | sed "s/%font_color%/${font_color}/g" | sed "s/%font_size%/${font_size}/g" >> ${HTML_PAGE_STANDING}
	done < ${TMP_FILE}
	
	echo -e "
	</tbody>
	</table>
	<br>
	</div>
	" >> ${HTML_PAGE_STANDING}
		
	HTML_Share ${HTML_PAGE_STANDING}
	HTML_End ${HTML_PAGE_STANDING}
}

# =======================
#  Build Top5 page
# =======================
Build_Top5() {
	Message -info "Building page ($(basename ${HTML_PAGE_TOP5}))"
	> ${HTML_PAGE_TOP5}
	
	HTML_Head ${HTML_PAGE_TOP5}
	HTML_Menu ${HTML_PAGE_TOP5}
	
	MIN_ROUND=$(Get_Min_Round)
	
	echo -e "
    <div id=\"header\">
		  <img style=\"display: inline;\" src=\"img/top.png\" alt=\"TOP#5\" />
		  <h1 style=\"display: inline;\">TOP#5</h1>
    </div>
    " >> ${HTML_PAGE_TOP5}

	echo -e "
	<div id=\"content\">
		<p>Veja os melhores jogadores por posição até o momento baseado nas médias. Em busca da regularidade são listados jogadres com mais de <b>70%</b> de participação, ou seja, que atuaram em pelo menos <b>${MIN_ROUND}</b> jogos.
	" >> ${HTML_PAGE_TOP5}
	
	# GOL - Goleiro
	echo -e "
		<h2>Goleiro</h2>
		<hr>
		<table class=\"flat-table\">
		<tbody>
			<tr><th> </th><th> </th><th>TIME</th><th>JOGADOR</th><th>PARTIDAS</th><th>VALOR</th><th>MÉDIA</th></tr>" >> ${HTML_PAGE_TOP5}
	count=0
	echo "call sp_html_top5_position('GOL', ${MIN_ROUND}, ${CURRENT_SEASON});" | mysql -N -B ${MYSQL_CONN} 2> /dev/null > ${TMP_FILE}
	while read line
	do
		count=$(expr ${count} + 1)
		echo "${line}" | sed "s/%position_number%/${count}/g" >> ${HTML_PAGE_TOP5}
	done < ${TMP_FILE}

	echo -e "
	</tbody>
	</table>" >> ${HTML_PAGE_TOP5}
	
	# LAT - Lateral
	echo -e "
		<h2>Lateral</h2>
		<hr>
		<table class=\"flat-table\">
		<tbody>
			<tr><th> </th><th> </th><th>TIME</th><th>JOGADOR</th><th>PARTIDAS</th><th>VALOR</th><th>MÉDIA</th></tr>" >> ${HTML_PAGE_TOP5}
	count=0
	echo "call sp_html_top5_position('LAT', ${MIN_ROUND});" | mysql -N -B ${MYSQL_CONN} 2> /dev/null > ${TMP_FILE}
	while read line
	do
		count=$(expr ${count} + 1)
		echo "${line}" | sed "s/%position_number%/${count}/g" >> ${HTML_PAGE_TOP5}
	done < ${TMP_FILE}

	echo -e "
	</tbody>
	</table>" >> ${HTML_PAGE_TOP5}
	
	# ZAG - Zagueiro
	echo -e "
		<h2>Zagueiro</h2>
		<hr>
		<table class=\"flat-table\">
		<tbody>
			<tr><th> </th><th> </th><th>TIME</th><th>JOGADOR</th><th>PARTIDAS</th><th>VALOR</th><th>MÉDIA</th></tr>" >> ${HTML_PAGE_TOP5}
	count=0
	echo "call sp_html_top5_position('ZAG', ${MIN_ROUND});" | mysql -N -B ${MYSQL_CONN} 2> /dev/null > ${TMP_FILE}
	while read line
	do
		count=$(expr ${count} + 1)
		echo "${line}" | sed "s/%position_number%/${count}/g" >> ${HTML_PAGE_TOP5}
	done < ${TMP_FILE}

	echo -e "
	</tbody>
	</table>" >> ${HTML_PAGE_TOP5}
	
	# MEI - Meia
	echo -e "
		<h2>Meio de campo</h2>
		<hr>
		<table class=\"flat-table\">
		<tbody>
			<tr><th> </th><th> </th><th>TIME</th><th>JOGADOR</th><th>PARTIDAS</th><th>VALOR</th><th>MÉDIA</th></tr>" >> ${HTML_PAGE_TOP5}
	count=0
	echo "call sp_html_top5_position('MEI', ${MIN_ROUND});" | mysql -N -B ${MYSQL_CONN} 2> /dev/null > ${TMP_FILE}
	while read line
	do
		count=$(expr ${count} + 1)
		echo "${line}" | sed "s/%position_number%/${count}/g" >> ${HTML_PAGE_TOP5}
	done < ${TMP_FILE}

	echo -e "
	</tbody>
	</table>" >> ${HTML_PAGE_TOP5}
	
	# ATA - Atacante
	echo -e "
		<h2>Atacante</h2>
		<hr>
		<table class=\"flat-table\">
		<tbody>
			<tr><th> </th><th> </th><th>TIME</th><th>JOGADOR</th><th>PARTIDAS</th><th>VALOR</th><th>MÉDIA</th></tr>" >> ${HTML_PAGE_TOP5}
	count=0
	echo "call sp_html_top5_position('ATA', ${MIN_ROUND});" | mysql -N -B ${MYSQL_CONN} 2> /dev/null > ${TMP_FILE}
	while read line
	do
		count=$(expr ${count} + 1)
		echo "${line}" | sed "s/%position_number%/${count}/g" >> ${HTML_PAGE_TOP5}
	done < ${TMP_FILE}

	echo -e "
	</tbody>
	</table>" >> ${HTML_PAGE_TOP5}
	
	# TEC - Tecnico
	echo -e "
		<h2>Técnico</h2>
		<hr>
		<table class=\"flat-table\">
		<tbody>
			<tr><th> </th><th> </th><th>TIME</th><th>JOGADOR</th><th>PARTIDAS</th><th>VALOR</th><th>MÉDIA</th></tr>" >> ${HTML_PAGE_TOP5}
	count=0
	echo "call sp_html_top5_position('TEC', ${MIN_ROUND});" | mysql -N -B ${MYSQL_CONN} 2> /dev/null > ${TMP_FILE}
	while read line
	do
		count=$(expr ${count} + 1)
		echo "${line}" | sed "s/%position_number%/${count}/g" >> ${HTML_PAGE_TOP5}
	done < ${TMP_FILE}

	echo -e "
	</tbody>
	</table>" >> ${HTML_PAGE_TOP5}
	
	# End
	echo -e "<br>
	</div>
	" >> ${HTML_PAGE_TOP5}
		
	HTML_Share ${HTML_PAGE_TOP5}
	HTML_End ${HTML_PAGE_TOP5}
}

# =======================
#  Build best page
# =======================
Build_Best() {
	Message -info "Building page ($(basename ${HTML_PAGE_BEST}))"
	> ${HTML_PAGE_BEST}
	
	HTML_Head ${HTML_PAGE_BEST}
	HTML_Menu ${HTML_PAGE_BEST}
	
	echo -e "
    <div id=\"header\">
		  <img style=\"display: inline;\" src=\"img/best.png\" alt=\"Destaques\" />
		  <h1 style=\"display: inline;\">Destaques</h1>
    </div>
    " >> ${HTML_PAGE_BEST}

	echo -e "
	<div id=\"content\">
		<p>Confira os jogadores e times que foram destaques na última rodada <b>(${CURRENT_ROUND})</b>.
	" >> ${HTML_PAGE_BEST}
	
	# Player Good
	echo -e "
		<h2>Jogador - Destaques positivos</h2>
		<hr>
		<table class=\"flat-table\">
		<tbody>
			<tr><th>#</th><th>JOGADOR</th><th>TIME</th><th>POSIÇÂO</th><th>PONTOS</th><th>PARTIDA</th></tr>" >> ${HTML_PAGE_BEST}
	count=0
	echo "call sp_html_player_performance_round_desc(${CURRENT_ROUND});" | mysql -N -B ${MYSQL_CONN} 2> /dev/null > ${TMP_FILE}
	while read line
	do
		count=$(expr ${count} + 1)
		echo "${line}" | sed "s/%position_number%/${count}/g" >> ${HTML_PAGE_BEST}
	done < ${TMP_FILE}

	echo -e "
	</tbody>
	</table>" >> ${HTML_PAGE_BEST}	

	# Player Bad
	echo -e "
		<h2>Jogador - Destaques negativos</h2>
		<hr>
		<table class=\"flat-table\">
		<tbody>
			<tr><th>#</th><th>JOGADOR</th><th>TIME</th><th>POSIÇÂO</th><th>PONTOS</th><th>PARTIDA</th></tr>" >> ${HTML_PAGE_BEST}
	count=0
	echo "call sp_html_player_performance_round_asc(${CURRENT_ROUND});" | mysql -N -B ${MYSQL_CONN} 2> /dev/null > ${TMP_FILE}
	while read line
	do
		count=$(expr ${count} + 1)
		echo "${line}" | sed "s/%position_number%/${count}/g" >> ${HTML_PAGE_BEST}
	done < ${TMP_FILE}

	echo -e "
	</tbody>
	</table>" >> ${HTML_PAGE_BEST}	
	
	# Team Good
	echo -e "
		<h2>Time - Destaques positivos</h2>
		<hr>
		<table class=\"flat-table\">
		<tbody>
			<tr><th> </th><th> </th><th>TIME</th><th>PONTOS</th></tr>" >> ${HTML_PAGE_BEST}
	count=0
	echo "call sp_html_round_standing_desc(${CURRENT_ROUND});" | mysql -N -B ${MYSQL_CONN} 2> /dev/null > ${TMP_FILE}
	while read line
	do
		count=$(expr ${count} + 1)
		echo "${line}" | sed "s/%position_number%/${count}/g" >> ${HTML_PAGE_BEST}
	done < ${TMP_FILE}

	echo -e "
	</tbody>
	</table>" >> ${HTML_PAGE_BEST}		
	
	# Team Bad
	echo -e "
		<h2>Time - Destaques negativos</h2>
		<hr>
		<table class=\"flat-table\">
		<tbody>
			<tr><th> </th><th> </th><th>TIME</th><th>PONTOS</th></tr>" >> ${HTML_PAGE_BEST}
	count=0
	echo "call sp_html_round_standing_asc(${CURRENT_ROUND});" | mysql -N -B ${MYSQL_CONN} 2> /dev/null > ${TMP_FILE}
	while read line
	do
		count=$(expr ${count} + 1)
		echo "${line}" | sed "s/%position_number%/${count}/g" >> ${HTML_PAGE_BEST}
	done < ${TMP_FILE}

	echo -e "
	</tbody>
	</table>" >> ${HTML_PAGE_BEST}		
		
	HTML_Share ${HTML_PAGE_BEST}
	HTML_End ${HTML_PAGE_BEST}
}

# =======================
#  Build best page
# =======================
Build_Record() {
	Message -info "Building page ($(basename ${HTML_PAGE_RECORD}))"
	> ${HTML_PAGE_RECORD}
	
	HTML_Head ${HTML_PAGE_RECORD}
	HTML_Menu ${HTML_PAGE_RECORD}
	
	echo -e "
    <div id=\"header\">
		  <img style=\"display: inline;\" src=\"img/record.png\" alt=\"Recordes\" />
		  <h1 style=\"display: inline;\">Recordes</h1>
    </div>
    " >> ${HTML_PAGE_RECORD}

	echo -e "
	<div id=\"content\">
		<p>Relembre as rodadas em que os jogadores fizeram mais pontos desde o começo do campeonato até o momento (rodada <b>${CURRENT_ROUND}</b>).
	" >> ${HTML_PAGE_RECORD}
	
	# Player Good
	echo -e "
		<h2>Jogador - Recordes positivos</h2>
		<hr>
		<table class=\"flat-table\">
		<tbody>
			<tr><th>#</th><th>JOGADOR</th><th>TIME</th><th>POSIÇÂO</th><th>RODADA</th><th>PONTOS</th><th>PARTIDA</th><th><img src=\"img/details.png\" style=\"width:22px;height:22px;\"</th></tr>" >> ${HTML_PAGE_RECORD}
	count=0
	echo "call sp_html_player_performance_all_desc(${CURRENT_ROUND});" | mysql -N -B ${MYSQL_CONN} 2> /dev/null | head -10 > ${TMP_FILE}
	while read line
	do
		count=$(expr ${count} + 1)
		echo "${line}" | sed "s/%position_number%/${count}/g" >> ${HTML_PAGE_RECORD}
	done < ${TMP_FILE}	
	
	echo -e "
	</tbody>
	</table>" >> ${HTML_PAGE_RECORD}

	# Player Bad
	echo -e "
		<h2>Jogador - Recordes negativos</h2>
		<hr>
		<table class=\"flat-table\">
		<tbody>
			<tr><th>#</th><th>JOGADOR</th><th>TIME</th><th>POSIÇÂO</th><th>RODADA</th><th>PONTOS</th><th>PARTIDA</th><th><img src=\"img/details.png\" style=\"width:22px;height:22px;\"</th></tr>" >> ${HTML_PAGE_RECORD}
	count=0
	echo "call sp_html_player_performance_all_asc(${CURRENT_ROUND});" | mysql -N -B ${MYSQL_CONN} 2> /dev/null | head -10 > ${TMP_FILE}
	while read line
	do
		count=$(expr ${count} + 1)
		echo "${line}" | sed "s/%position_number%/${count}/g" >> ${HTML_PAGE_RECORD}
	done < ${TMP_FILE}	
	
	echo -e "
	</tbody>
	</table>" >> ${HTML_PAGE_RECORD}
	
	HTML_Share ${HTML_PAGE_RECORD}
	HTML_End ${HTML_PAGE_RECORD}
}

# =======================
#  Build chart page
# =======================
Build_Chart() {
	Message -info "Building page ($(basename ${HTML_PAGE_CHART}))"
	> ${HTML_PAGE_CHART}
	
	HTML_Head ${HTML_PAGE_CHART}
	sed -i '$d' ${HTML_PAGE_CHART}
	
	# Goals
	echo -e "
    <script type=\"text/javascript\" src=\"https://www.google.com/jsapi\"></script>
	
    <script type=\"text/javascript\">
		google.load('visualization', '1', {packages: ['corechart', 'bar']});
		google.setOnLoadCallback(drawBarColors);
		
		function drawBarColors() {
		      var data = google.visualization.arrayToDataTable([
        		['Jogador', 'Gols', 'Impedimento'],
	" >> ${HTML_PAGE_CHART}
	echo "call sp_html_goals();" | mysql -N -B ${MYSQL_CONN} 2> ${LOG_FILE} >> ${HTML_PAGE_CHART}
	echo -e "
	   ]);

      	var options = {
          	chartArea: {width: '50%'},
          	colors: ['#000099', '#CC0000'],
          	hAxis: { minValue: 0 }
      	};
      	var chart = new google.visualization.BarChart(document.getElementById('chart_goals'));
      	chart.draw(data, options);
    	}
    </script> 
    
	" >> ${HTML_PAGE_CHART}
		
	# Shots
	echo -e "
    <script type=\"text/javascript\">
		google.load('visualization', '1', {packages: ['corechart', 'bar']});
		google.setOnLoadCallback(drawBarColors);
		
		function drawBarColors() {
		      var data = google.visualization.arrayToDataTable([
        		['Jogador', 'Finalizações defendidas', 'Finalizações para fora', 'Finalizações na trave'],	
	" >> ${HTML_PAGE_CHART}
	echo "call sp_html_shots();" | mysql -N -B ${MYSQL_CONN} 2> ${LOG_FILE} >> ${HTML_PAGE_CHART}
	echo -e "
	   ]);

      	var options = {
          	chartArea: {width: '50%'},
          	colors: ['#000099', '#CC0000', '#009900'],
          	hAxis: { minValue: 0 }
      	};
      	var chart = new google.visualization.BarChart(document.getElementById('chart_shots'));
      	chart.draw(data, options);
    	}
    </script>	
    
	" >> ${HTML_PAGE_CHART}
	
	# Assists
	echo -e "
   <script type=\"text/javascript\">
      google.load(\"visualization\", \"1\", {packages:[\"corechart\"]});
      google.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = google.visualization.arrayToDataTable([
          ['Jogador', 'Assistencia'],
    " >> ${HTML_PAGE_CHART}
    echo "call sp_html_assists();" | mysql -N -B ${MYSQL_CONN} 2> ${LOG_FILE} >> ${HTML_PAGE_CHART}
    echo -e "
        ]);

        var options = { pieHole: 0.3 };
        var chart = new google.visualization.PieChart(document.getElementById('chart_assists'));
        chart.draw(data, options);
      }
    </script>
</head>    
    " >> ${HTML_PAGE_CHART}
    
	HTML_Menu ${HTML_PAGE_CHART}
	
	echo -e "
    <div id=\"header\">
		  <img style=\"display: inline;\" src=\"img/chart.png\" alt=\"Gráficos\" />
		  <h1 style=\"display: inline;\">Gráficos</h1>
    </div>

	<div id=\"content\">
		<p>Veja estatísticas interessantes sobre o cartola.
	

		<h2>Gols/Impedimentos</h2>
		<hr>
		<div id=\"chart_goals\"></div>
		<br>
		
		<h2>Finalizações</h2>
		<hr>
		<div id=\"chart_shots\"></div>
		<br>		
		
		<h2>Assistências</h2>
		<hr>
		<div id=\"chart_assists\"></div>
		<br>		
	" >> ${HTML_PAGE_CHART}
	
	HTML_Share ${HTML_PAGE_CHART}
	HTML_End ${HTML_PAGE_CHART}
}

# =======================
#  Main
# =======================
Border "Start"

Set_Params

Check_DB_Conn

Build_Home

Build_Standing

Build_Top5

Build_Best

Build_Record

Build_Chart

Site_Deployment

Exit_Script 0
