#!/bin/bash
#===============================================================
# NAME      :  cartola_db.sh
# Programmer:  Pedro Pavan
# Date      :  16-June-2015
# Purpose   :  Insert data in cartola DB
#
# Changes history:
#
#  Date     |    By       |  Changes/New features
# ----------+-------------+-------------------------------------
# Pedro	      06-16-2015    Initial release
# Pedro	      12-21-2015    Support to score files
#===============================================================

# =======================
#  Variables
# =======================
DB_CONF="../conf/db.conf"

# =======================
#  Usage
# =======================
Usage() {
	echo -e "
Usage:\n$(basename $0) <type> <round>\n
- type:  team|player|round|stat|match
- round: 1..38
	"
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
	
	rm ../tmp/tmp_cartola_sql.*
	Border "Finish"
	exit ${EXIT_CODE}
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
#  Check data
# =======================
Check_Data() {
	TABLE=$1
	
	echo "select count(*) from \`${TABLE}\`;" | mysql -N -B ${MYSQL_CONN} 2> /dev/null
}

# =======================
#  Insert data
# =======================
Insert_Data() {
	Message -info "Starting..."
	COUNT_TABLE_BEFORE=$(Check_Data ${PATTERN})
	cat ${TMP_FILE} | mysql -B ${MYSQL_CONN} >> ${LOG_FILE} 2>&1
	
	if [ $? -eq 0 ]; then
		COUNT_TABLE_AFTER=$(Check_Data ${PATTERN})
		COUNT_TABLE_CHECK=$(expr ${COUNT_TABLE_BEFORE} + ${COUNT_LINES})
		
		if [ ${COUNT_TABLE_AFTER} -eq ${COUNT_TABLE_CHECK} ]; then
			Message -info "Data has been inserted successfully (${COUNT_TABLE_AFTER} lines)"
		else
			Message -fail "Missing lines"
			Exit_Script 5
		fi
	else
		Message -fail "There is a problem to insert data"
		Exit_Script 4
	fi
}

# =======================
#  MAIN
# =======================
if [ $# -ne 2 ]; then
	Usage
	exit 1
fi

PATTERN=$1
ROUND=$2

MYSQL_CONN="$(Get_DB_Param)"
TMP_FILE="$(mktemp ../tmp/tmp_cartola_sql.XXXXXXXXXX)"
LOG_FILE="../log/round${ROUND}.log"
SQL_FILE="../output/round${ROUND}.sql"
touch ${SQL_FILE}

Border "Start"

Message -info "LOG: ${LOG_FILE}"
Message -info "SQL: ${SQL_FILE}"
Message -info "TYPE: ${PATTERN}"

if [ "${PATTERN}" == "score" ]; then
	egrep "^UPDATE \`match\`" ${SQL_FILE} > ${TMP_FILE}
	COUNT_LINES=$(wc -l ${TMP_FILE} | awk '{ print $1 }')
	
	if [ ${COUNT_LINES} -eq 0 ]; then
		Message -fail "Pattern: 'match' was not found"
		Exit_Script 5
	fi	
else
	egrep "^INSERT INTO \`${PATTERN}\`" ${SQL_FILE} > ${TMP_FILE}
	COUNT_LINES=$(wc -l ${TMP_FILE} | awk '{ print $1 }')

	if [ ${COUNT_LINES} -eq 0 ]; then
		Message -fail "Pattern: '${PATTERN}' was not found"
		Exit_Script 6
	fi
fi

echo "commit;" >> ${TMP_FILE}

Message -info "LINES: ${COUNT_LINES}"
sleep 1
Check_DB_Conn

if [ "${PATTERN}" == "score" ]; then
	Message -info "Starting..."
	cat ${TMP_FILE} | mysql -B ${MYSQL_CONN} >> ${LOG_FILE} 2>&1
	
	if [ $? -eq 0 ]; then
		Message -info "Data has been inserted successfully"
	else
		Message -fail "There is a problem to insert data"
		Exit_Script 4
	fi
else
	Insert_Data
fi

Exit_Script 0
