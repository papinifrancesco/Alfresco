#!/bin/bash
# should be put in /opt/alfresco/scripts
# crontab -e -u root
# 59 23 * * * /opt/alfresco/scripts/AlfrescoLogsManager.sh

# --------------------------------------------------------
# LOGGING SETUP
# --------------------------------------------------------
# Log file path (overwritten on every run)
SCRIPT_LOG="/tmp/AlfrescoLogsManager.log"

# Redirect STDOUT and STDERR to the log file
exec > "$SCRIPT_LOG" 2>&1

# CRON FIX: Explicitly set PATH to include sbin directories
# Cron environments often lack /sbin and /usr/sbin by default
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

echo "----------------------------------------------------"
echo "Starting AlfrescoLogsManager execution at $(date)"
echo "PATH is: $PATH"
echo "----------------------------------------------------"

LOGS=/opt/alfresco/tomcat/logs
DATE_F=$(date +%F)

# --------------------------------------------------------
# DYNAMIC PATH DETECTION & SAFETY CHECKS
# --------------------------------------------------------

# Detect the location of fuser and xz
FUSER_BIN=$(command -v fuser)
XZ_BIN=$(command -v xz)

# Safety Check 1: Ensure fuser exists. 
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
    echo "Creating directory $LOGS/old"
    mkdir -p "$LOGS/old"
fi

echo "Safety checks passed. Using fuser at: $FUSER_BIN"

# --------------------------------------------------------
# LOG ROTATION LOGIC
# --------------------------------------------------------

# rotate catalina.out
if [ -s "$LOGS/catalina.out" ]; then
    echo "Rotating catalina.out..."
    cp -p "$LOGS/catalina.out" "$LOGS/catalina_${DATE_F}.out"
    cat /dev/null > "$LOGS/catalina.out"
else
    echo "catalina.out is empty or does not exist. Skipping rotation."
fi

# rotate query-solr.log
if [ -s "$LOGS/query-solr.log" ]; then
    echo "Rotating query-solr.log..."
    cp -p "$LOGS/query-solr.log" "$LOGS/query-solr_${DATE_F}.log"
    cat /dev/null > "$LOGS/query-solr.log"
fi

# rotate gc.log
if [ -s "$LOGS/gc.log" ]; then
    echo "Rotating gc.log..."
    cp -p "$LOGS/gc.log" "$LOGS/gc_${DATE_F}.log"
    cat /dev/null > "$LOGS/gc.log"
fi

# --------------------------------------------------------
# CLEANUP AND COMPRESSION
# --------------------------------------------------------

echo "Starting cleanup of 0 byte files..."
# delete 0 size files not in use
find "$LOGS"/ -maxdepth 1 -type f -size 0 | while read -r filename ; do 
    "$FUSER_BIN" -s "$filename" || { echo "Deleting empty file: $filename"; rm -f "$filename"; }
done

echo "Moving unused log files to old/..."
# if a log file is not in use, move it to old/
find "$LOGS"/ -maxdepth 1 -type f | while read -r filename ; do 
    "$FUSER_BIN" -s "$filename" || { echo "Moving $filename to old/"; mv "$filename" "$LOGS/old/"; }
done

echo "Compressing files in old/..."
# compress all files inside old/ that are not an .xz already
find "$LOGS/old/" -maxdepth 1 -type f \! -name "*.xz" | while read -r filename ; do 
    echo "Compressing $filename"
    "$XZ_BIN" -9 "$filename" 
done

echo "Deleting compressed logs older than 30 days..."
# remove all compressed logs older than 30 days
find "$LOGS/old/" -maxdepth 1 -mtime +30 -type f -name "*.xz" -exec rm -vf {} \;

echo "----------------------------------------------------"
echo "Execution finished at $(date)"
echo "----------------------------------------------------"
