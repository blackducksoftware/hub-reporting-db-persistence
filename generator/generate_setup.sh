#!/bin/bash
#

cat preamble.psql

for i in $(cat tables | awk '{print $3}')
do
echo ""
echo "-----------------------------------"
echo "-- processing table ${i}"
bash generator.sh ${i}
done
