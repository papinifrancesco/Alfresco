#!/bin/bash
# Clean stale subdirectories from the Alfresco Transform Service tmp directory.
# Removes directories older than 2 hours whose files are not currently in use.
#
# Schedule (alfresco crontab): 0 * * * * /opt/alfresco/scripts/transformers_tmp_clean.sh

TMP_DIR="/opt/alfresco/transform-service/tmp"
MIN_AGE_MINUTES=120
LOG_FILE="/opt/alfresco/transform-service/logs/tmp_clean.log"

find "$TMP_DIR" -maxdepth 1 -mindepth 1 -type d -mmin +"$MIN_AGE_MINUTES" | while IFS= read -r dir; do
    # Check if any file within this directory tree is currently open by a process
    in_use=false
    while IFS= read -r -d '' file; do
        if fuser -s "$file" 2>/dev/null; then
            in_use=true
            break
        fi
    done < <(find "$dir" -type f -print0 2>/dev/null)

    if [ "$in_use" = false ]; then
        rm -rf -- "$dir" && echo "$(date '+%Y-%m-%d %H:%M:%S') DELETED  $dir" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') IN USE   $dir" >> "$LOG_FILE"
    fi
done
