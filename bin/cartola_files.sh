#!/bin/bash
#===============================================================
# NAME      :  cartola_files.sh
# Programmer:  Pedro Pavan
# Date      :  02-June-2015
# Purpose   :  Parse data from cartolafc
#
# Changes history:
#
#  Date     |    By       |  Changes/New features
# ----------+-------------+-------------------------------------
# Pedro	      06-02-2015    Initial release
# Pedro	      06-05-2015    Parse input files
# Pedro	      06-06-2015    Generate CSV well formatted 
# Pedro	      06-07-2015    Generate SQL file (team)
# Pedro	      06-09-2015    Generate SQL file (player)
# Pedro	      06-12-2015    Create SSH tunnel
# Pedro	      06-13-2015    Generate SQL file (match)
# Pedro	      06-14-2015    Generate SQL file (statistics)
# Pedro	      06-21-2015    Script improvement (bin)
# Pedro	      12-15-2015    Added score information
#===============================================================

# =======================
#  Variables
# =======================
# General files
DB_CONF="../conf/db.conf"
TEMP_FILE="$(mktemp ../tmp/tmp_cartola_files.XXXXXXXXXX)"
TEMP_SCORE="$(mktemp ../tmp/tmp_cartola_score.XXXXXXXXXX)"
FILE_PREFIX="cartola"
ls -1 ../input/${FILE_PREFIX}* | sort -V > ${TEMP_FILE}

# Input files
INPUT_FILES=$(cat ${TEMP_FILE} | tr '\n' ' ')
INPUT_ROUND_NUMBER=$(awk -F '/' '{ print $NF }' ${TEMP_FILE} | head -1 | tr -d '[a-z]' | cut -d '_' -f 1)
INPUT_ROUND_NEXT=$(expr ${INPUT_ROUND_NUMBER} + 1)
INPUT_ROUND_SCORE="../input/score_${INPUT_ROUND_NUMBER}.txt"

# Output files
OUTPUT_FILE_CSV="../output/round${INPUT_ROUND_NUMBER}.csv"
OUTPUT_FILE_TMP="$(mktemp ../tmp/tmp_cartola_csv.XXXXXXXXXX)"
> ${OUTPUT_FILE_CSV}

# SQL files
SQL_FILE_MAIN="../output/round${INPUT_ROUND_NUMBER}.sql"
SQL_FILE_TMP="$(mktemp ../tmp/tmp_cartola_sql.XXXXXXXXXX)"
SQL_FILE_TEAM="$(mktemp ../tmp/tmp_cartola_sql.XXXXXXXXXX)"
SQL_FILE_PLAYER="$(mktemp ../tmp/tmp_cartola_sql.XXXXXXXXXX)"
SQL_FILE_ROUND="$(mktemp ../tmp/tmp_cartola_sql.XXXXXXXXXX)"
SQL_FILE_MATCH="$(mktemp ../tmp/tmp_cartola_sql.XXXXXXXXXX)"
SQL_FILE_STAT="$(mktemp ../tmp/tmp_cartola_sql.XXXXXXXXXX)"
SQL_FILE_SCORE="$(mktemp ../tmp/tmp_cartola_sql.XXXXXXXXXX)"

# Data files
DATA_TABLE_TEAM="$(mktemp ../tmp/tmp_cartola_data.XXXXXXXXXX)"
DATA_TABLE_PLAYER="$(mktemp ../tmp/tmp_cartola_data.XXXXXXXXXX)"

# =======================
#  Usage
# =======================
Usage() {
	echo -e "\nUsage:\n$(basename $0)\n\nInput folder: '../$(readlink ../input)'"
}

# =======================
#  Abort on error
# =======================
Abort_Script() {
	EXIT_CODE=${1:-10}
	
	if [ $? -ne 0 ]; then
		Message -fail "Last command failed, check log file!"
		Exit_Script ${EXIT_CODE}
	fi
}

# =======================
#  Exit
# =======================
Exit_Script() {
	EXIT_CODE=$1
	
	CleanTemp
	Border "Finish"
	exit ${EXIT_CODE}
}

# =======================
#  Message
# =======================
Message() {
	MSG_TYPE="$1"
	MSG="$2"
	
	case "${MSG_TYPE}" in
		"-info")	echo -e "[+] ${MSG}" | tee -a ${LOG_FILE}	;;
		"-fail")	echo -e "[!] ${MSG}" | tee -a ${LOG_FILE}	;;
		"-more")	echo -e "[*] ${MSG}" | tee -a ${LOG_FILE}	;;
		      *)	echo -e "[-] ${MSG}" | tee -a ${LOG_FILE}	;;
	esac
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
#  Check DB status
# =======================
Check_DB_Conn() {
	echo "show status;" | mysql -N -B ${MYSQL_CONN} > /dev/null 2>&1
	
	if [ $? -eq 0 ]; then
		Message -info "Connection working [$(hostname) <---> MYHOST]"
	else
		Message -fail "Fail to connect to MYHOST"
		Exit_Script 2
	fi
}

# =======================
#  Remove temporary files
# =======================
CleanTemp() {
	rm -f ../tmp/tmp_cartola_*
}

# =======================
#  Parser input files
# =======================
Process_Files() {
	Message -info "Processing files"
	
	for file in ${INPUT_FILES}; do
		CURRENT_FILE="${file}"
		
		for line in $(seq 1 8 99999); do
			sed -n "${line},+7p" ${CURRENT_FILE} > ${TEMP_FILE}
			
			if [ -s ${TEMP_FILE} ]; then
				cat ${TEMP_FILE} | tr '\n' ';' | rev | cut -c 2- | rev >> ${OUTPUT_FILE_TMP}
			else
				break
			fi
		done
	done
	
	Abort_Script 6
}

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
#  Create SSH Tunnel
# =======================
Create_Tunnel() {
	TUNNEL_PORT=$(grep MYSQL_PORT ${DB_CONF} | cut -d '=' -f 2)
	TUNNEL_HOST=$(grep MYSQL_HOST ${DB_CONF} | cut -d '=' -f 2)
	
	if [ $(pgrep -U $USER -f "${TUNNEL_PORT}:${TUNNEL_HOST}:${TUNNEL_PORT}" | wc -l) -ne 0 ]; then
		Message -info "Running from host: ${HOSTNAME} (tunnel is running)"
		return
	else
		Message -info "Running from host: ${HOSTNAME} (creating tunnel)"
	fi
	
	if [ "${HOSTNAME}" != "MYHOST" ]; then
		ssh -f ssh_key -L ${TUNNEL_PORT}:${TUNNEL_HOST}:${TUNNEL_PORT} -N > /dev/null 2>&1
		
		if [ $? -ne 0 ]; then
			Message -fail "SSH Tunnel has been failed"
			Exit_Script 1
		fi
	fi
}

# =======================
#  Team Name
# =======================
Team_Name() {
	TEAM=$1
	TEAM=$(echo ${TEAM^})										# Upper case first letter
	TEAM=$(echo ${TEAM} | sed 's/-mg/-MG/g')					# Atlético Mineiro
	TEAM=$(echo ${TEAM} | sed 's/-pr/-PR/g')					# Atlético Paranaense
	TEAM=$(echo ${TEAM} | sed 's/Sãopaulo/São Paulo/g')			# São Paulo
	TEAM=$(echo ${TEAM} | sed 's/Pontepreta/Ponte Preta/g')		# Ponte Preta
	echo ${TEAM}
}

# =======================
#  Fetch Data
# =======================
Fetch_Data() {
	Message -info "Fetching information from DB"
	
	echo "call sp_get_team_info();" | mysql -N -B ${MYSQL_CONN} 2> /dev/null > ${DATA_TABLE_TEAM}
	Abort_Script 3
	
	echo "call sp_get_player_info();" | mysql -N -B ${MYSQL_CONN} 2> /dev/null > ${DATA_TABLE_PLAYER}
	Abort_Script 4
}

# =======================
#  Check files content
# =======================
Check_Files() {
	Message -info "Checking files"
	
	# Looking for score file
	if [ ! -f ${INPUT_ROUND_SCORE} ]; then
		Message -fail "Score file was not found: ${INPUT_ROUND_SCORE}"
		Exit_Script 51
	fi
	
	# Check files lines
	CHECK_FILES=$(wc -l ../input/cartola* | sort -n | grep -cw 159)
	
	if [ ${CHECK_FILES} -lt 10 ]; then
		Message -fail "Invalid line numbers for input files!"
		Exit_Script 52
	fi

	# Looking for [FD]
	CHECK_FILES=$(fgrep -l "[FD]" ../input/*)
	
	if [ -n "${CHECK_FILES}" ]; then
		Message -fail "Invalid character was found in: ${CHECK_FILES}"
		Exit_Script 52
	fi
	
	# Looking for [G]
	CHECK_FILES=$(fgrep -l "[G]" ../input/*)
	
	if [ -n "${CHECK_FILES}" ]; then
		Message -fail "Invalid character was found in: ${CHECK_FILES}"
		Exit_Script 53
	fi
}

# =======================
#  Generate CSV file
# =======================
Generate_CSV() {
	Message -info "Generating CSV ($(basename ${OUTPUT_FILE_CSV}))"
	echo -e "POSITION;PLAYER;TEAM;VALUE;SCORE;HOME;AWAY;FS#PE#A#FT#FD#FF#G#I#PP" > ${OUTPUT_FILE_CSV}
	
	while read line; do
		PLAYER_TEAM=$(echo ${line} | awk -F ';' '{ print $1 }' | tr -d ' ')
		PLAYER_POSITION=$(echo ${line} | awk -F ';' '{ print $2 }')
		PLAYER_NAME=$(echo ${line} | awk -F ';' '{ print $3 }')
		PLAYER_VALUE=$(echo ${line} | awk -F ';' '{ print $6 }' | awk '{ print $3 }')
		PLAYER_SCORE=$(echo ${line} | awk -F ';' '{ print $6 }' | awk '{ print $6 }')
		TEAM_HOME=$(echo ${line} | awk -F ';' '{ print $7 }' | sed 's/escudo //g' | cut -d 'X' -f 1)
		TEAM_AWAY=$(echo ${line} | awk -F ';' '{ print $7 }' | sed 's/escudo //g' | cut -d 'X' -f 2)
		PLAYER_STAT=$(echo ${line} | awk -F ';' '{ print $8 }' | tr ' ' '#')
	
		echo -e "${PLAYER_POSITION};${PLAYER_NAME};${PLAYER_TEAM};${PLAYER_VALUE};${PLAYER_SCORE};${TEAM_HOME};${TEAM_AWAY};${PLAYER_STAT}" >> ${OUTPUT_FILE_CSV}
	done < ${OUTPUT_FILE_TMP}
	
	Abort_Script 7
}

# =======================
#  Generate SQL file
# =======================
Generate_SQL() {
	Message -info "Generating SQL ($(basename ${SQL_FILE_MAIN}))"
	> ${SQL_FILE_TMP}

	while read line; do
		PLAYER_POSITION=$(echo ${line} | cut -d ';' -f 1)
		PLAYER_NAME=$(echo ${line} | cut -d ';' -f 2)
		PLAYER_TEAM_CODE=$(echo ${line} | cut -d ';' -f 3)
		PLAYER_TEAM_NAME=$(Team_Name "${PLAYER_TEAM_CODE}")
		PLAYER_VALUE=$(echo ${line} | cut -d ';' -f 4)
		PLAYER_SCORE=$(echo ${line} | cut -d ';' -f 5)
		PLAYER_TEAM_ID=$(Get_Team_ID "${PLAYER_TEAM_CODE}")
		PLAYER_ID=$(Get_Player_ID "${PLAYER_NAME}" "${PLAYER_POSITION}" "${PLAYER_TEAM_CODE}")
		PLAYER_STAT=$(echo ${line} | cut -d ';' -f 8)
		PLAYER_STAT_VALUE=$(Get_Player_Stat "${PLAYER_STAT}")
		TEAM_HOME=$(echo ${line} | cut -d ';' -f 6 | tr -d ' ')
		TEAM_AWAY=$(echo ${line} | cut -d ';' -f 7 | tr -d ' ')
		TEAM_HOME_ID=$(Get_Team_ID "${TEAM_HOME}")
		TEAM_AWAY_ID=$(Get_Team_ID "${TEAM_AWAY}")
		
		# Team
		if [ "${PLAYER_TEAM_NAME}" != "TEAM" ] && [ ${PLAYER_TEAM_ID} -eq 0 ]; then
			echo "INSERT INTO \`team\` (code, name, creation_date) VALUES ('"${PLAYER_TEAM_CODE}"', '"${PLAYER_TEAM_NAME}"', '"${INPUT_ROUND_DATE}"');" >> ${SQL_FILE_TEAM}
		fi
			
		# Player
		if [ "${PLAYER_NAME}" != "PLAYER" ] && [ ${PLAYER_ID} -eq 0 ]; then
			echo "INSERT INTO \`player\` (name, position, id_team, creation_date) VALUES ('"${PLAYER_NAME}"', '"${PLAYER_POSITION}"', ${PLAYER_TEAM_ID}, '"${INPUT_ROUND_DATE}"');" >> ${SQL_FILE_PLAYER}
		fi
		
		# Round
		if [ "${PLAYER_SCORE}" != "SCORE" ]; then
			echo "INSERT INTO \`round\` (id, player_id, player_score, player_value, date) VALUES (${INPUT_ROUND_NUMBER}, ${PLAYER_ID}, ${PLAYER_SCORE}, ${PLAYER_VALUE}, '"${INPUT_ROUND_DATE}"');" >> ${SQL_FILE_ROUND}
		fi
		
		# Match
		if [ "${TEAM_HOME}" != "HOME" ]; then
			echo "INSERT INTO \`match\` (round_id, team_id_home, team_id_away) VALUES (${INPUT_ROUND_NEXT}, ${TEAM_HOME_ID}, ${TEAM_AWAY_ID});" >> ${SQL_FILE_MATCH}
		fi
		
		# Statistics
		if [ "${TEAM_AWAY}" != "AWAY" ]; then
			echo "INSERT INTO \`stat\` (round_id, player_id, type, fs, pe, a, ft, fd, ff, g, i, pp) VALUES (${INPUT_ROUND_NUMBER}, ${PLAYER_ID}, 'A'${PLAYER_STAT_VALUE});" >> ${SQL_FILE_STAT}
		fi
	done < ${OUTPUT_FILE_CSV}
	Abort_Script 8

	# WA: fixing name (D'Alessandro) with quotes
	sed -i "s/D'/D''/g" ${SQL_FILE_PLAYER}

	# main SQL
	> ${SQL_FILE_MAIN}
	echo -e "\n-- Team" >> ${SQL_FILE_MAIN} ; cat ${SQL_FILE_TEAM} 2> /dev/null | sort | uniq >> ${SQL_FILE_MAIN}
	echo -e "\n-- Player" >> ${SQL_FILE_MAIN} ; cat ${SQL_FILE_PLAYER} 2> /dev/null | sort | uniq >> ${SQL_FILE_MAIN}
	echo -e "\n-- Round" >> ${SQL_FILE_MAIN} ; cat ${SQL_FILE_ROUND} 2> /dev/null | sort | uniq >> ${SQL_FILE_MAIN}
	echo -e "\n-- Match" >> ${SQL_FILE_MAIN} ; cat ${SQL_FILE_MATCH} 2> /dev/null | sort | uniq >> ${SQL_FILE_MAIN}
	echo -e "\n-- Statistics" >> ${SQL_FILE_MAIN} ; cat ${SQL_FILE_STAT} 2> /dev/null | sort | uniq  >> ${SQL_FILE_MAIN}
	echo -e "\n-- Score" >> ${SQL_FILE_MAIN} ; cat ${SQL_FILE_SCORE} 2> /dev/null | sort | uniq  >> ${SQL_FILE_MAIN}
	Abort_Script 9
}

# =======================
#  Create Score Files
# =======================
Create_Score() {
	Message -info "Including score file ($(basename ${INPUT_ROUND_SCORE}))"
	> ${SQL_FILE_SCORE}
	
	grep -v "VEJA COMO FOI" ${INPUT_ROUND_SCORE} | grep -v "[0-3][0-9]/[0-1][0-9]/201[0-9]" > ${TEMP_SCORE}
	while read line
	do
		TEAM_HOME_CODE=$(echo "${line}" | tr -d ' ' | awk '{print $1}' | cut -c 4- | tr '[A-Z]' '[a-z]')
		TEAM_AWAY_CODE=$(echo "${line}" | tr -d ' ' | awk '{print $3}' | sed 's/.\{3\}$//' | tr '[A-Z]' '[a-z]')

		TEAM_HOME_ID=$(cat ${DATA_TABLE_TEAM} | grep ${TEAM_HOME_CODE} | cut -d '#' -f 1)
		TEAM_AWAY_ID=$(cat ${DATA_TABLE_TEAM} | grep ${TEAM_AWAY_CODE} | cut -d '#' -f 1)
		
		TEAM_HOME_NAME=$(cat ${DATA_TABLE_TEAM} | grep ${TEAM_HOME_CODE} | cut -d '#' -f 3)
		TEAM_AWAY_NAME=$(cat ${DATA_TABLE_TEAM} | grep ${TEAM_AWAY_CODE} | cut -d '#' -f 3)
		
		TEAM_HOME_GOALS=$(echo "${line}" | tr -d ' ' | awk '{print $2}' | cut -c1)
		TEAM_AWAY_GOALS=$(echo "${line}" | tr -d ' ' | awk '{print $2}' | cut -c2)
	
		MATCH_DATETIME=$(cat ${INPUT_ROUND_SCORE} | egrep -B 1 "${TEAM_HOME_NAME}.*${TEAM_AWAY_NAME}" | head -1 | awk '{ print $2" "$NF }')
		MATCH_STADIUM=$(cat ${INPUT_ROUND_SCORE} | egrep -B 1 "${TEAM_HOME_NAME}.*${TEAM_AWAY_NAME}" | head -1 | awk '{ if (NF == 4) {print $3} else if (NF == 5) {print $3" "$4} else if (NF == 6) print $3" "$4" "$5 }')
	
		echo "UPDATE \`match\` SET team_home_goals = ${TEAM_HOME_GOALS}, team_away_goals = ${TEAM_AWAY_GOALS}, place = '${MATCH_STADIUM}', date_time = STR_TO_DATE('${MATCH_DATETIME}','%d/%m/%Y %H:%i') WHERE round_id = ${INPUT_ROUND_NUMBER} AND team_id_home = ${TEAM_HOME_ID} AND team_id_away = ${TEAM_AWAY_ID};" >> ${SQL_FILE_SCORE}
	done < ${TEMP_SCORE}	
	
	Abort_Script 10
}

# =======================
#  Display statistics
# =======================
Display_Stat() {
	echo -e " "
	Message -more "------> Summary <------"
	Message -more "Detected round: ${INPUT_ROUND_NUMBER}"
	Message -more "Detected date: ${INPUT_ROUND_DATE}"
	Message -more "Detected teams: $(grep -c "INSERT INTO \`team\`" ${SQL_FILE_MAIN})"
	Message -more "Detected players: $(grep -c "INSERT INTO \`player\`" ${SQL_FILE_MAIN})"
	Message -more "Detected scouts: $(grep -c "INSERT INTO \`round\`" ${SQL_FILE_MAIN})"
	Message -more "Detected matches: $(grep -c "INSERT INTO \`match\`" ${SQL_FILE_MAIN})"
	Message -more "Detected statistics: $(grep -c "INSERT INTO \`stat\`" ${SQL_FILE_MAIN})"
	Message -more "Detected score: $(grep -c "UPDATE \`match\`" ${SQL_FILE_MAIN})"
	Abort_Script 11
}

# =======================
#  Get Player Statistics
# =======================
Get_Player_Stat() {
	STAT=$1
	SQL_NULL=", null, null, null, null, null, null, null, null, null"
	SQL_VALUE=""
	
	if [ -n "${STAT}" ]; then
		if [ "${STAT}" == "-#-#-#-#-#-#-#-#-" ]; then
			SQL_VALUE="${SQL_NULL}"
		else
			for value in $(seq 1 9); do SQL_VALUE="${SQL_VALUE}, $(echo ${STAT} | cut -d '#' -f ${value})"; done
		fi
	else
		SQL_VALUE="${SQL_NULL}"
	fi
	
	echo "${SQL_VALUE}"
}

# =======================
#  Get Round Data
# =======================
Get_Round_Date() {
	echo "$(stat -c %y ../input/${FILE_PREFIX}* | awk '{ print $1 }' | uniq | head -1)"
}

# =======================
#  Get Team ID
# =======================
Get_Team_ID() {
	TEAM_CODE=$1
	RESULT=$(grep "#${TEAM_CODE}#" ${DATA_TABLE_TEAM} | cut -d '#' -f 1)
	TEAM_ID=0
		
	if [ -n "${RESULT}" ]; then
		TEAM_ID="${RESULT}"
	fi
	
	echo "${TEAM_ID}"
}

# =======================
#  Get Player ID
# =======================
Get_Player_ID() {
	PLAYER_NAME=$1
	PLAYER_POSITION=$2
	PLAYER_TEAM=$3
	RESULT=$(grep "#${PLAYER_NAME}#${PLAYER_POSITION}#${PLAYER_TEAM}#" ${DATA_TABLE_PLAYER} | cut -d '#' -f 1)
	PLAYER_ID=0
		
    if [ -n "${RESULT}" ]; then
		PLAYER_ID="${RESULT}"
    fi
    
    echo ${PLAYER_ID}
}

# =======================
#  MAIN
# =======================
LOG_FILE="../log/round${INPUT_ROUND_NUMBER}.log"
INPUT_ROUND_DATE="$(Get_Round_Date)"
MYSQL_CONN="$(Get_DB_Param)"

Border "Start"

Create_Tunnel

Check_DB_Conn

Check_Files

Fetch_Data

Create_Score

Process_Files

Generate_CSV

Generate_SQL

Display_Stat

Exit_Script 0
