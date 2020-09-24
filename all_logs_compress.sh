#!/bin/bash
# should be put in /usr/local/scripts

TCAT_HOME=$1

find $TCAT_HOME/logs -type f -mtime +1 -exec bash -c "file {} | grep -q xz || /usr/sbin/lsof {} > /dev/null || [ ! -s {} ] || xz -9 {}" \;
