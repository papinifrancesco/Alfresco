#!/bin/bash
# should be put in /opt/alfresco/scripts
# crontab -e -u alfresco
# 50 23 * * * /opt/alfresco/scripts/clean-contentstore.deleted.sh

# Let's have a look, manually, at how much space we could reclaim:
# find /opt/alf_data/contentstore.deleted/ -mtime +20 -type f -exec du -c {} + | awk '/total/{sum += $1} END {print sum/1048576}'

# Then, the real thing:
find /opt/alf_data/contentstore.deleted/ -mtime +20 -type f -delete
