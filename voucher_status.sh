#!/bin/sh
echo "Content-type: application/json"
echo ""

MAC="$REMOTE_ADDR"
SESSIONS_FILE="/tmp/sessions.json"
VOUCHERS_FILE="/etc/nodogsplash/vouchers.json"

if [ ! -f $SESSIONS_FILE ]; then
  echo '{"connected": false, "remaining_minutes": 0}'
  exit 0
fi

SESSION=$(jq --arg mac "$MAC" '.sessions[] | select(.mac==$mac)' $SESSIONS_FILE)
if [ -z "$SESSION" ]; then
  echo '{"connected": false, "remaining_minutes": 0}'
  exit 0
fi

VOUCHER=$(echo $SESSION | jq -r '.voucher')
USED=$(echo $SESSION | jq -r '.used_seconds')
HOURS=$(jq -r --arg code "$VOUCHER" '.vouchers[] | select(.code==$code) | .hours' $VOUCHERS_FILE)
REMAINING=$((HOURS*60 - USED/60))
[ $REMAINING -lt 0 ] && REMAINING=0

echo "{\"connected\": true, \"voucher\": \"$VOUCHER\", \"mac\": \"$MAC\", \"remaining_minutes\": $REMAINING}"
