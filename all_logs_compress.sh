#!/bin/bash
# should be put in /usr/local/scripts

TCAT_HOME=$1

find "$TCAT_HOME/logs" -maxdepth 1 -type f -size 0 | while read -r filename ; do /sbin/fuser -s "$filename" || rm -f "$filename" ; done

find "$TCAT_HOME/logs" -maxdepth 1 -type f -mmin +180 -exec bash -c "file {} | grep -q xz || /usr/sbin/lsof {} > /dev/null || [ ! -s {} ] || xz -9 {}" \;

find "$TCAT_HOME/logs" -maxdepth 1 -type f -name "*.xz" -exec mv {} "$TCAT_HOME/logs/old/" \;

find "$TCAT_HOME/logs/old/" -maxdepth 1 -mtime +180 -type f -name "*.xz" -exec rm -f {} \;
