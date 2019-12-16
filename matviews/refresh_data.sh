#!/bin/bash
#

LOGFILE=/home/kumykov/refresh_data.log
/bin/date >> ${LOGFILE}

cat /home/kumykov/refresh.psql | \
/usr/bin/docker exec -i $(/usr/bin/docker ps | /bin/grep postgres | /usr/bin/awk '{print $1}') psql bds_hub >> \
${LOGFILE} 2>&1

