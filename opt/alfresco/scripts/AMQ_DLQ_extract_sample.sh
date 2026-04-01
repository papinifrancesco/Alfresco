#!/bin/bash
SAVE_DIR="/opt/alfresco/scripts/dlq_samples"
SAVE_COUNT=50
JOLOKIA_URL="http://127.0.0.1:8161/api/jolokia/"
CREDS="admin:admin"
MBEAN="org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=ActiveMQ.DLQ"

mkdir -p "$SAVE_DIR"

# Check queue size before attempting browse
QUEUE_SIZE=$(/usr/bin/curl -s -u "$CREDS" -H "Origin: http://localhost" -H "Content-Type: application/json" \
  -X POST -d "{\"type\":\"read\",\"mbean\":\"$MBEAN\",\"attribute\":\"QueueSize\"}" \
  "$JOLOKIA_URL" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('value', 0))" 2>/dev/null)

echo "DLQ size: ${QUEUE_SIZE:-unknown}"

if [ "${QUEUE_SIZE:-0}" -eq 0 ] 2>/dev/null; then
  echo "DLQ is empty, nothing to sample."
  exit 0
fi

# Browse and save up to SAVE_COUNT messages
BROWSE_RESULT=$(/usr/bin/curl -s -u "$CREDS" -H "Origin: http://localhost" -H "Content-Type: application/json" \
  -X POST -d "{\"type\":\"exec\",\"mbean\":\"$MBEAN\",\"operation\":\"browse()\"}" \
  "$JOLOKIA_URL")

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
# Always save raw response for debugging
echo "$BROWSE_RESULT" > "$SAVE_DIR/dlq_raw_${TIMESTAMP}.json"

SAMPLE_FILE="$SAVE_DIR/dlq_sample_${TIMESTAMP}.json"
echo "$BROWSE_RESULT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if data.get('status') != 200:
    print('Jolokia error:', data.get('error', 'unknown'), file=sys.stderr)
    sys.exit(1)
msgs = (data.get('value') or [])[:${SAVE_COUNT}]
print(json.dumps(msgs, indent=2))
" > "$SAMPLE_FILE" 2>&1 && echo "Saved ${SAVE_COUNT} sample(s) to $SAMPLE_FILE" \
  || echo "Browse failed — check $SAVE_DIR/dlq_raw_${TIMESTAMP}.json for the raw Jolokia response"
