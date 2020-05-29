#!/bin/sh
#
# Source PG environment
#
. /tmp/environment
. /opt/blackduck/hub/auditor/bin/setpgenv.sh

# Check if FDW and PDATA are configured
date
echo
if psql bds_hub_report -c "select schema_name from information_schema.schemata where schema_name='bds_hub';" | grep bds_hub
then
	echo bds_hub schema is present
        echo
else
	echo bds_hub schema is not present, exiting.
	echo
	exit 1
fi

date
echo
echo "Executing Materialized views refresh ..."
echo 
time -p  psql -f /opt/blackduck/hub/auditor/query/refresh_mat_views.psql bds_hub
time -p  psql -f /opt/blackduck/hub/auditor/query/refresh_mat_views_aux.psql bds_hub

echo 
echo "Done"
echo

date
echo 
echo "Executing data synchronization"
echo

time -p  psql -f /opt/blackduck/hub/auditor/query/update_pdata.psql bds_hub_report
time -p  psql -f /opt/blackduck/hub/auditor/query/update_pdata_aux.psql bds_hub_report

echo
echo "Done"
echo


