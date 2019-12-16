#!/bin/bash
#

LOGFILE=/home/kumykov/refresh_data.log
/bin/date >> ${LOGFILE}

cat /home/kumykov/re-materialize.psql | \
/usr/bin/docker exec -i $(/usr/bin/docker ps | /bin/grep postgres | /usr/bin/awk '{print $1}') psql bds_hub >> \
${LOGFILE} 2>&1


exit

time cat /home/kumykov/pdata-update.psqlkumykov@sa-incubator0:~$ cp refresh.psql re-materialize.psql
kumykov@sa-incubator0:~$ cp refresh.psql | \
/usr/bin/docker exec -i $(/usr/bin/docker ps | /bin/grep postgres | /usr/bin/awk '{print $1}') psql bds_hub >> \
${LOGFILE} 2>&1


