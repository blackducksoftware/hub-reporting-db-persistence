#!/bin/bash
#

cat sql/reporting_database_persistence_cleanup.psql | docker exec -i $(docker ps | awk '/postgres/ {print $1}') psql bds_hub_report
