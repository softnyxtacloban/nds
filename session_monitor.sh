#!/bin/sh

SESSIONS_FILE="/tmp/sessions.json"
VOUCHERS_FILE="/etc/nodogsplash/vouchers.json"
LOG_FILE="/var/log/nodogsplash_vouchers.log"
CURRENT=$(date +%s)
TMP=$(mktemp)

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SESSION_MONITOR] $1" >> $LOG_FILE
}

# Increment session usage
if [ -f $SESSIONS_FILE ]; then
    jq --argjson now "$CURRENT" '.sessions |= map(.used_seconds += ($now - .start) | .start=$now)' $SESSIONS_FILE > $TMP && mv $TMP $SESSIONS_FILE
fi

# Check for expired sessions
if [ -f $SESSIONS_FILE ]; then
    jq -c '.sessions[]' $SESSIONS_FILE | while read s; do
        MAC=$(echo $s | jq -r '.mac')
        VOUCHER=$(echo $s | jq -r '.voucher')
        USED=$(echo $s | jq -r '.used_seconds')
        HOURS=$(jq -r --arg code "$VOUCHER" '.vouchers[] | select(.code==$code) | .hours' $VOUCHERS_FILE)
        
        if [ "$USED" -ge $(($HOURS*3600)) ]; then
            # Disconnect client
            nodogsplash -k $MAC

            # Log auto-disconnect
            log "Session auto-disconnected MAC=$MAC Voucher=$VOUCHER Duration=${HOURS}h Used_seconds=$USED"

            # Update voucher: mark as used/disable
            jq --arg code "$VOUCHER" --argjson used "$HOURS" \
               '(.vouchers[] | select(.code==$code) | .used) |= $used |
                (.vouchers[] | select(.code==$code) | .active) |= false' \
               $VOUCHERS_FILE > $VOUCHERS_FILE.tmp && mv $VOUCHERS_FILE.tmp $VOUCHERS_FILE

            # Remove session
            jq --arg mac "$MAC" '.sessions |= map(select(.mac != $mac))' $SESSIONS_FILE > $SESSIONS_FILE.tmp && mv $SESSIONS_FILE.tmp $SESSIONS_FILE
        fi
    done
fi
