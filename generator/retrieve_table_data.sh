#!/bin/bash
#
#

echo "\\dt " | docker exec -i $(docker ps | awk '/postgres/ {print $1}') psql bds_hub_report | grep table >tables

for i in $(cat tables | awk '{print $3}') 
do
echo "\\d $i" | docker exec -i $(docker ps | awk '/postgres/ {print $1}') psql bds_hub_report >${i}.tbl
done

