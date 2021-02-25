#!/bin/bash
# should be put in /opt/alfresco/scripts
# crontab -e -u alfresco
# 59 23 * * * /opt/alfresco/scripst/AlfrescoLogsManager.sh

LOGS=/opt/alfresco/tomcat/logs
DATE_F=$(date +%F)

# rotate catalina.out
if [ -s "$LOGS/catalina.out" ]; then
cp -p "$LOGS/catalina.out" "$LOGS/catalina_${DATE_F}.out"
cat /dev/null > "$LOGS/catalina.out"
fi


# delete 0 size files not in use
find "$LOGS" -maxdepth 1 -type f -size 0 | while read -r filename ; do /sbin/fuser -s "$filename" || rm -f "$filename" ; done

# if a log file is not in use, move it to old/
find "$LOGS" -maxdepth 1 -type f | while read -r filename ; do /sbin/fuser -s "$filename" || mv "$filename" $LOGS/old/ ; done

# compress all files inside old/ that are not an .xz already
find "$LOGS/old" -maxdepth 1 -type f \! -name "*.xz" | while read -r filename ; do /usr/bin/xz -9 "$filename" ; done

# remove all compressed logs older than 180 days
find "$LOGS/old" -maxdepth 1 -mtime +180 -type f -name "*.xz" -exec rm -f {} \;
