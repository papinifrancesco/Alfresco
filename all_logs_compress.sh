#!/bin/bash

TCAT_HOME=$1

find $TCAT_HOME/logs -type f -mtime +1 -exec bash -c "file {} | grep -q gzip || /usr/sbin/lsof {} > /dev/null || [ ! -s {} ] || gzip -9 {}" \;
