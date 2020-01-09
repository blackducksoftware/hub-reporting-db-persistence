if [ "$1" = "" ]
then
	HOUR=20
else
	HOUR=$1
fi

echo "0 ${HOUR} * * * /opt/blackduck/hub/auditor/bin/updatepdata.sh > /tmp/pdataupdate.log 2>&1" | crontab

