#!/bin/bash
#


cat <<!
-- This will destroy pdata tables and data
-- Use at your own peril


\c bds_hub_report
!

for i in `cat tables | awk '{print $3}'`
do
cat << !

-- cleanup for $i
drop trigger if exists ${i}_insert on ${i};
drop trigger if exists ${i}_update on ${i};
drop function if exists ${i}_update();
!

done

cat <<!

-- dropping pdata schema
drop schema if exists pdata cascade;
!


