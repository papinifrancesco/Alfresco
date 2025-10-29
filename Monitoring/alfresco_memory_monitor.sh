#!/bin/bash

#===============================================================================
# Alfresco Memory Monitor & Restart Script (Full Sampling)
#
# This script monitors the memory usage of the Alfresco Java process.
# It takes a specified number of memory samples at defined intervals.
# It will always attempt to take all samples.
# If ALL collected samples show Resident Set Size (RSS) exceeding a defined
# percentage of the configured maximum Java heap size (Xmx), it attempts
# to restart the Alfresco service.
#
# PREREQUISITES:
# 1. Adjust the CONFIGURATION VARIABLES below.
# 2. Ensure this script has execute permissions (chmod +x script_name.sh).
# 3. The user running this script needs sudo privileges to restart the
#    Alfresco service without a password, or the script must be run as root.
#    Example for sudoers: your_user ALL=(ALL) NOPASSWD: /bin/systemctl restart alfresco.service
# 4. Consider setting this up as a cron job to run periodically.
#    Example cron job (runs every 15 minutes):
#    */15 * * * * /path/to/your/alfresco_memory_monitor.sh
#
#===============================================================================

#-------------------------------------------------------------------------------
# CONFIGURATION VARIABLES - MODIFY THESE TO MATCH YOUR ENVIRONMENT
#-------------------------------------------------------------------------------

# Pattern to identify the Alfresco Java process.
# Test with: pgrep -f "YOUR_PATTERN"
ALFRESCO_PROCESS_NAME_PATTERN="/opt/alfresco/tomcat/shared/classes/"

# Maximum Java Heap Size (Xmx) configured for Alfresco, in Megabytes (MB).
# This should match the -Xmx value in your Alfresco startup options.
MAX_HEAP_MB=20480

# Memory usage threshold (percentage).
# If RSS exceeds this percentage of MAX_HEAP_MB, it's considered above threshold.
MEMORY_THRESHOLD_PERCENTAGE=90 # Example: 90%

# Number of memory samples to take.
SAMPLE_COUNT=10

# Interval between samples, in seconds.
SAMPLE_INTERVAL_SECONDS=10

# Name of the Alfresco systemd service.
# Check with: systemctl list-units | grep -i alfresco
SERVICE_NAME="alfresco.service"

# Log file path. Ensure the user running the script has write permissions.
LOG_FILE="/prd/daf/log/alfresco_memory_monitor.log"

#-------------------------------------------------------------------------------
# SCRIPT LOGIC - DO NOT MODIFY BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING
#-------------------------------------------------------------------------------

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_message "--- Script execution started (Full Sampling Logic) ---"

# Calculate the memory threshold in Kilobytes (KB)
MAX_HEAP_KB=$((MAX_HEAP_MB * 1024))
MEMORY_TRIGGER_KB=$(( (MAX_HEAP_KB * MEMORY_THRESHOLD_PERCENTAGE) / 100 ))

log_message "Configuration: Process Pattern='${ALFRESCO_PROCESS_NAME_PATTERN}', Max Heap=${MAX_HEAP_MB}MB (${MAX_HEAP_KB}KB), Threshold=${MEMORY_THRESHOLD_PERCENTAGE}%, Trigger RSS=${MEMORY_TRIGGER_KB}KB"
log_message "Sampling: ${SAMPLE_COUNT} samples every ${SAMPLE_INTERVAL_SECONDS} seconds. Service='${SERVICE_NAME}'"

# Find the PID of the Alfresco Java process
PID=$(pgrep -f "$ALFRESCO_PROCESS_NAME_PATTERN" | head -n 1)

if [ -z "$PID" ]; then
    log_message "ERROR: Alfresco process matching pattern '${ALFRESCO_PROCESS_NAME_PATTERN}' not found."
    log_message "--- Script execution finished ---"
    exit 1
fi

log_message "Found Alfresco process with PID: $PID"

samples_above_threshold_count=0
all_samples_consistently_above_threshold=true # Assume true initially
loop_iterations_completed=0 # To track how many loop iterations actually ran

for i in $(seq 1 "$SAMPLE_COUNT"); do
    loop_iterations_completed=$i # Record that this iteration is being processed
    log_message "Taking sample $i of $SAMPLE_COUNT for PID $PID..."

    # Get the current Resident Set Size (RSS) in Kilobytes (KB) for the PID
    CURRENT_RSS_KB=$(ps -p "$PID" -o rss= | tr -d ' ')

    if [ -z "$CURRENT_RSS_KB" ]; then
        log_message "ERROR: Could not retrieve memory usage (RSS) for PID $PID on sample $i. Process might have terminated."
        all_samples_consistently_above_threshold=false # Mark as failed as we couldn't get this sample
        break # Exit sampling loop, critical error, cannot continue sampling
    fi

    CURRENT_RSS_MB=$((CURRENT_RSS_KB / 1024))
    log_message "Sample $i: Current Alfresco RSS: ${CURRENT_RSS_KB}KB (approx. ${CURRENT_RSS_MB}MB)"

    if [ "$CURRENT_RSS_KB" -gt "$MEMORY_TRIGGER_KB" ]; then
        log_message "Sample $i: Memory usage (${CURRENT_RSS_KB}KB) IS ABOVE threshold (${MEMORY_TRIGGER_KB}KB)."
        samples_above_threshold_count=$((samples_above_threshold_count + 1))
    else
        log_message "Sample $i: Memory usage (${CURRENT_RSS_KB}KB) is NOT above threshold (${MEMORY_TRIGGER_KB}KB)."
        all_samples_consistently_above_threshold=false # As soon as one sample is not above, set this to false. Loop continues.
    fi

    # Sleep only if it's not the last sample
    if [ "$i" -lt "$SAMPLE_COUNT" ]; then
        log_message "Waiting ${SAMPLE_INTERVAL_SECONDS} seconds before next sample..."
        sleep "$SAMPLE_INTERVAL_SECONDS"
    fi
done

log_message "Sampling complete. Loop iterations attempted/completed: $loop_iterations_completed. Samples found above threshold: $samples_above_threshold_count."

# Condition for restart:
# 1. All SAMPLE_COUNT iterations of the loop must have been completed (i.e., loop_iterations_completed reached SAMPLE_COUNT, meaning no process error break).
# 2. The all_samples_consistently_above_threshold flag must be true (meaning every sample processed was above threshold).
if [ "$loop_iterations_completed" -eq "$SAMPLE_COUNT" ] && [ "$all_samples_consistently_above_threshold" = true ]; then
    log_message "WARNING: All $SAMPLE_COUNT memory samples were successfully processed AND ALL were found to be above the threshold (${MEMORY_TRIGGER_KB}KB)."
    log_message "Attempting to restart Alfresco service: $SERVICE_NAME"

    if sudo systemctl restart "$SERVICE_NAME"; then
        log_message "SUCCESS: Alfresco service '$SERVICE_NAME' restart command issued."
    else
        log_message "ERROR: Failed to issue restart command for Alfresco service '$SERVICE_NAME'. Check permissions and service status."
    fi
else
    # If we are here, either not all samples were processed (process died, so loop_iterations_completed < SAMPLE_COUNT)
    # OR all samples were processed (loop_iterations_completed == SAMPLE_COUNT) but not all of them were above threshold (all_samples_consistently_above_threshold is false).
    if [ "$loop_iterations_completed" -lt "$SAMPLE_COUNT" ]; then
        # This implies a 'break' occurred due to process error (CURRENT_RSS_KB was empty)
        log_message "INFO: Sampling interrupted. Only $loop_iterations_completed out of $SAMPLE_COUNT samples were processed because the process may have terminated or memory could not be read. Restart condition not met."
    else
        # This implies all $SAMPLE_COUNT samples were processed (loop_iterations_completed == SAMPLE_COUNT),
        # but all_samples_consistently_above_threshold is false (meaning at least one sample was not above threshold).
        log_message "INFO: All $SAMPLE_COUNT samples were processed. However, not all samples were above the threshold (Actual count above: $samples_above_threshold_count). Restart condition not met."
    fi
fi

log_message "--- Script execution finished ---"
exit 0
