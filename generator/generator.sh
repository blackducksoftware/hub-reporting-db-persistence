#!/bin/bash
#

TABLENAME=$1
COLUMNS=$(cat ${1}.tbl  | grep -v Column | grep "|*|" | awk '{print $1}')
PKEY_LIST=$(cat ${1}.tbl  | grep PRIMARY | cut -d '(' -f 2 | cut -d ')' -f 1)
UKEY_LIST=$(cat ${1}.tbl  | grep UNIQUE | cut -d '(' -f 2 | cut -d ')' -f 1 | sed 's/, /,/g')

FIELD_LIST=$(echo ${COLUMNS} | sed 's/ /,/g')
VALUE_LIST=$(for i in $COLUMNS ; do echo -n "new.${i}," ; done | sed 's/,$//' )
UPDATE_SET=$(for i in $COLUMNS ; do echo -n " ${i} = new.${i}," ; done | sed 's/,$//' )
WHERE_CLAUSE=$(for i in $UKEY_LIST $PKEY_LIST ; do echo -n " ${i%,} = new.${i%,} AND" ; done | sed 's/AND$//' )
for i in $UKEY_LIST
do
  for j in $(echo $i | sed 's/,/ /g') 
  do
    echo -n "-- ${j%,} = new.${j%,} AND" 
  done | sed 's/AND$//' 
  echo 
done

echo -- $TABLENAME
echo -- $COLUMNS
echo -- $PKEY_LIST
echo -- $UKEY_LIST
echo -- $WHERE_CLAUSE

cat <<!
CREATE OR REPLACE FUNCTION ${TABLENAME}_update()
  RETURNS trigger AS
\$BODY\$
begin
     if (select EXISTS(select 1 from pdata.${TABLENAME} where ${WHERE_CLAUSE} )) then
        --found; delete the row to allow clean insert
        DELETE FROM pdata.${TABLENAME} WHERE ${WHERE_CLAUSE};
     end if;
!
for i in $UKEY_LIST
do
  UWHERE_CLAUSE=$(for j in $(echo $i | sed 's/,/ /g') ; do echo -n " ${j} = new.${j} AND" ; done | sed 's/AND$//' )
cat <<!
     if (select EXISTS(select 1 from pdata.${TABLENAME} where ${UWHERE_CLAUSE} )) then
        --found delete the row to allow clean insert
        DELETE FROM pdata.${TABLENAME} WHERE ${UWHERE_CLAUSE};
     end if;
!
done

cat <<!
     insert into pdata.${TABLENAME} (
        ${FIELD_LIST} )
        VALUES (
        ${VALUE_LIST} );
     return new;
end
\$BODY\$
LANGUAGE plpgsql;

create trigger ${TABLENAME}_update after update on ${TABLENAME}
for each row execute procedure ${TABLENAME}_update();

create trigger ${TABLENAME}_insert after insert on ${TABLENAME}
for each row execute procedure ${TABLENAME}_update();
!

