#!/bin/bash
# should be put in /opt/alfresco/scripts
# crontab -e -u alfresco
# 59 23 * * * /opt/alfresco/scripts/TransformServiceLogsManager.sh

LOGS=/opt/alfresco/transform-service/logs
DATE_F=$(date +%F)


# rotate file
rotate_file () {
if [ -s "$LOGS/$1.out" ]; then
cp -pf "$LOGS/$1.out" "$LOGS/$1-${DATE_F}.out"
cat /dev/null > "$LOGS/$1.out"
fi
}

rotate_file "transform-router"

rotate_file "transform-core-aio"

rotate_file "shared-file-store"

# delete files older than 5 days if not in use
find "$LOGS" -maxdepth 1 -type f -mtime 5 | while read -r filename ; do fuser -s "$filename" || rm -f "$filename" ; done
