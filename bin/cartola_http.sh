#!/bin/bash
#===============================================================
# NAME      :  cartola_http.sh
# Programmer:  Pedro Pavan
# Date      :  23-June-2015
# Purpose   :  Provide HTTP access to cartola.html
#
# Changes history:
#
#  Date     |    By       |  Changes/New features
# ----------+-------------+-------------------------------------
# Pedro	      06-23-2015    Initial release
#===============================================================

# =======================
#  Variables
# =======================
HTTP_LOG="../log/http.log"
#HTTP_DIR="../html"
HTTP_DIR="../html_dev"
HTTP_MODULE="SimpleHTTPServer"
HTTP_PORT=9090
HTTP_IP=$(ifconfig | grep "inet addr" | grep -v "127.0.0.1" | cut -d ':' -f 2 | awk '{ print $1 }')
HTTP_URL="http://${HTTP_IP}:${HTTP_PORT}"
HTTP_ACTION=${1}
HTTP_TIME=$(date '+%F %T')


# =======================
#  Usage
# =======================
Usage() {
	echo -e "Usage:\n"
	echo -e "$(basename $0) start|stop|status|open"
	exit 1
}

# =======================
#  MAIN
# =======================
HTTP_ACTION="${1}"
case $# in
	1) HTTP_DIR="${HTTP_DIR}/site"	;;
	2) HTTP_DIR="${HTTP_DIR}/${2}"	;;
	*) Usage						;;
esac

case "${HTTP_ACTION}" in
	"start")
		echo -e "\n***************** $(echo ${HTTP_ACTION} | tr '[a-z]' '[A-Z]') [${HTTP_TIME} | ${HTTP_DIR}] *****************" >> ${HTTP_LOG}
		cd ${HTTP_DIR}
		python -m ${HTTP_MODULE} ${HTTP_PORT} >> ../${HTTP_LOG} 2>&1 &
	;;
	
	"stop")
		echo -e "***************** $(echo ${HTTP_ACTION} | tr '[a-z]' '[A-Z]') [${HTTP_TIME}] *****************" >> ${HTTP_LOG}
		pkill -U ${USER} -f ${HTTP_MODULE}
	;;
	
	"status")
		if [ $(pgrep -U ${USER} -f "${HTTP_MODULE}" | wc -l) -gt 0 ]; then
			echo "Cartola HTTP is Running - ${HTTP_URL}"
			exit 0
		else
			echo "Cartola HTTP is Dead"
			exit 1
		fi
	;;
	
	"open")
		TARGET_ROUND=$2
		firefox ${HTTP_URL} > /dev/null 2>&1 &
	;;	
	
	*)
		Usage
		exit 2
	;;
esac

exit 0
