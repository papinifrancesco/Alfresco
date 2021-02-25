#!/bin/bash
# should be put in /opt/alfresco/scripts

LOGS=/opt/alfresco/tomcat/logs

# delete 0 size files not in use
find "$LOGS" -maxdepth 1 -type f -size 0 | while read -r filename ; do /sbin/fuser -s "$filename" || rm -f "$filename" ; done

# if a log file is not in use, move it to old/
find "$LOGS" -maxdepth 1 -type f | while read -r filename ; do /sbin/fuser -s "$filename" || mv "$filename" $LOGS/old/ ; done

# compress all files inside old/ that are not an .xz already
find "$LOGS/old" -maxdepth 1 -type f \! -name "*.xz" | while read -r filename ; do /usr/bin/xz -9 "$filename" ; done

# remove all compressed logs older than 180 days
find "$LOGS/old" -maxdepth 1 -mtime +180 -type f -name "*.xz" -exec rm -f {} \;
