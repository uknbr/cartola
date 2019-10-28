#  cartola.sh
#  
#  Copyright 2016 Pedro Pavan <pedro.pavan@linuxmail.org>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
#  
#!/usr/bin/env bash
#===============================================================
# Changes history:
#
#  Date     |    By       |  Changes/New features
# ----------+-------------+-------------------------------------
# Pedro	      08-17-2015    Initial release
# Pedro	      08-31-2015    Complete flow
#===============================================================

# =======================
#  Usage
# =======================
Usage() {
	echo -e "Usage:\n"
	echo -e "$(basename $0) <round_number>"
	exit 1
}

# =======================
#  New Line
# =======================
Line() {
	if [ $? -ne 0 ]; then
		echo -e "Something wrong!\nExiting..."
		exit 1
	fi
	
	MSG=$1
	echo -e "\n********** ${MSG} **********"
	sleep 1
}

# =======================
#  Main
# =======================
if [ $# -ne 1 ]; then
	Usage
fi

# Round
clear
TARGET_ROUND=$1

# Adjust link
Line "Adjusting link to round ${TARGET_ROUND}"
cd ../ ; unlink input ; ln -sf data/${TARGET_ROUND} input ; cd bin/
ls -l ../ | grep input

# Parse files
Line "Parsing files"
bash cartola_files.sh

# Insert players
Line "Inserting new players"
bash cartola_db.sh player ${TARGET_ROUND}

# Parse files (again)
Line "Parsing files (again)"
bash cartola_files.sh

# Insert remaining items
for element in match round stat; do
	Line "Inserting ${element}"
	bash cartola_db.sh ${element} ${TARGET_ROUND}
done

# Update score
Line "Updating scores"
bash cartola_db.sh score ${TARGET_ROUND}

# Generate HTML
Line "Generating HTML pages"
bash cartola_html.sh

# Start HTTP
Line "Starting HTTP server"
bash cartola_http.sh stop
bash cartola_http.sh start
bash cartola_http.sh status
bash cartola_http.sh open

exit 0
