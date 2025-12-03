#!/bin/bash
# should be put in /opt/alfresco/scripts
# crontab -e -u root
# 59 23 * * * /opt/alfresco/scripts/AlfrescoLogsManager.sh

LOGS=/opt/alfresco/tomcat/logs
DATE_F=$(date +%F)

# --------------------------------------------------------
# DYNAMIC PATH DETECTION & SAFETY CHECKS
# --------------------------------------------------------

# Detect the location of fuser and xz
FUSER_BIN=$(command -v fuser)
XZ_BIN=$(command -v xz)

# Safety Check 1: Ensure fuser exists. 
# If fuser is missing, the original script would return an error code,
# causing the "|| rm" logic to trigger on ACTIVE files.
if [ -z "$FUSER_BIN" ]; then
    echo "CRITICAL ERROR: 'fuser' command not found in PATH. Aborting to prevent data loss."
    exit 1
fi

# Safety Check 2: Ensure xz exists
if [ -z "$XZ_BIN" ]; then
    echo "ERROR: 'xz' command not found. Aborting."
    exit 1
fi

# Safety Check 3: Ensure destination directory exists
if [ ! -d "$LOGS/old" ]; then
    mkdir -p "$LOGS/old"
fi

# --------------------------------------------------------
# LOG ROTATION LOGIC
# --------------------------------------------------------

# rotate catalina.out
if [ -s "$LOGS/catalina.out" ]; then
    cp -p "$LOGS/catalina.out" "$LOGS/catalina_${DATE_F}.out"
    cat /dev/null > "$LOGS/catalina.out"
fi

# rotate query-solr.log
if [ -s "$LOGS/query-solr.log" ]; then
    cp -p "$LOGS/query-solr.log" "$LOGS/query-solr_${DATE_F}.log"
    cat /dev/null > "$LOGS/query-solr.log"
fi

# rotate gc.log
if [ -s "$LOGS/gc.log" ]; then
    cp -p "$LOGS/gc.log" "$LOGS/gc_${DATE_F}.log"
    cat /dev/null > "$LOGS/gc.log"
fi

# --------------------------------------------------------
# CLEANUP AND COMPRESSION
# --------------------------------------------------------

# delete 0 size files not in use
# Using "$FUSER_BIN" instead of hardcoded path
find "$LOGS" -maxdepth 1 -type f -size 0 | while read -r filename ; do 
    "$FUSER_BIN" -s "$filename" || rm -f "$filename" 
done

# if a log file is not in use, move it to old/
find "$LOGS" -maxdepth 1 -type f | while read -r filename ; do 
    "$FUSER_BIN" -s "$filename" || mv "$filename" "$LOGS/old/" 
done

# compress all files inside old/ that are not an .xz already
# Using "$XZ_BIN" instead of hardcoded path
find "$LOGS/old" -maxdepth 1 -type f \! -name "*.xz" | while read -r filename ; do 
    "$XZ_BIN" -9 "$filename" 
done

# remove all compressed logs older than 30 days
find "$LOGS/old" -maxdepth 1 -mtime +30 -type f -name "*.xz" -exec rm -f {} \;
