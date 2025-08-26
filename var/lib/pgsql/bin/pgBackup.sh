#!/bin/bash
# 59 23 * * * /var/lib/pgsql/bin/pgBackup.sh
PG_HOME=/var/lib/pgsql/17
export PGDATA="$PG_HOME/data"

[ ! -d "$PGDATA" ] && echo "PostgreSQL not installed" && exit 1

DBNAMES=`psql -l | grep "^ [[:alnum:]]" | awk '{print $1}' | egrep -v "alfrescosvil|postgres|template0|template1"`  # Elenco database da NON backuppare (es "a b c")
PORT=5432

### Script per il dump database postgres

PGDUMP="pg_dump --clean -F c -b -p $PORT "
#XZ=/bin/xz
REPOSITORY=$PG_HOME/backups
#DATE_F=`date +%Y%m%d-%H%M%S`
DATE_F=`date +%Y-%m-%d`

FILE="-$DATE_F.dump"

for db in `echo $DBNAMES` ; do
        $PGDUMP -f "${REPOSITORY}/${db}${FILE}" ${db}
 #       $XZ -9 "${REPOSITORY}/${db}${FILE}"
done

# Rimuove i files di backup piu' vecchi di 10 giorni
find $REPOSITORY -type f -name "*.dump" -mtime +10 -exec rm {} \;
