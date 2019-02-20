#!/bin/bash
#

TABLENAME=$1
COLUMNS=$(cat ${1}.tbl  | grep -v Column | grep "|*|" | awk '{print $1}')
PKEY_LIST=$(cat ${1}.tbl  | grep PRIMARY | cut -d '(' -f 2 | cut -d ')' -f 1)

FIELD_LIST=$(echo ${COLUMNS} | sed 's/ /,/g')
VALUE_LIST=$(for i in $COLUMNS ; do echo -n "new.${i}," ; done | sed 's/,$//' )
UPDATE_SET=$(for i in $COLUMNS ; do echo -n " ${i} = new.${i}," ; done | sed 's/,$//' )
WHERE_CLAUSE=$(for i in $PKEY_LIST ; do echo -n " ${i%,} = new.${i%,} AND" ; done | sed 's/AND$//' )

echo -- $TABLENAME
echo -- $COLUMNS
echo -- $PKEY_LIST
echo -- $WHERE_CLAUSE

cat <<!
CREATE OR REPLACE FUNCTION ${TABLENAME}_update()
  RETURNS trigger AS
\$BODY\$
begin
     if (select EXISTS(select 1 from pdata.${TABLENAME} where ${WHERE_CLAUSE} )) then
        --found; update, and return null to prevent insert
        UPDATE pdata.${TABLENAME} SET
             ${UPDATE_SET}
        WHERE ${WHERE_CLAUSE};
     else
        insert into pdata.${TABLENAME} (
          ${FIELD_LIST} )
        VALUES (
          ${VALUE_LIST} );
     end if;
     return new;
end
\$BODY\$
LANGUAGE plpgsql;

create trigger ${TABLENAME}_update after update on ${TABLENAME}
for each row execute procedure ${TABLENAME}_update();

create trigger ${TABLENAME}_insert after insert on ${TABLENAME}
for each row execute procedure ${TABLENAME}_update();
!

