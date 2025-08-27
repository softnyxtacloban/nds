#!/bin/sh

METHOD="$1"
MAC="$2"

VOUCHER_FILE="/etc/nodogsplash/vouchers.txt"
LOG_FILE="/var/log/nodogsplash_vouchers.log"
SESSIONS_FILE="/tmp/sessions.json"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$METHOD] MAC=$MAC INFO=$1" >> $LOG_FILE
}

case "$METHOD" in
  auth_client)
    USERNAME="$3"
    PASSWORD="$4"

    # Check voucher
    if [ -f "$VOUCHER_FILE" ]; then
      DURATION=$(grep -E "^$PASSWORD\|" "$VOUCHER_FILE" | cut -d'|' -f2)
      if [ -n "$DURATION" ]; then
        # Auth success
        echo "$DURATION 0 0"

        log "Voucher $PASSWORD authenticated for $DURATION seconds"

        # Track session in JSON
        START=$(date +%s)
        [ ! -f $SESSIONS_FILE ] && echo '{"sessions":[]}' > $SESSIONS_FILE

        # Remove previous session if exists
        jq --arg mac "$MAC" '.sessions |= map(select(.mac != $mac))' $SESSIONS_FILE > $SESSIONS_FILE.tmp && mv $SESSIONS_FILE.tmp $SESSIONS_FILE

        # Add new session
        jq --arg mac "$MAC" --arg code "$PASSWORD" --argjson start "$START" \
           '.sessions += [{"mac":$mac,"voucher":$code,"start":$start,"used_seconds":0}]' \
           $SESSIONS_FILE > $SESSIONS_FILE.tmp && mv $SESSIONS_FILE.tmp $SESSIONS_FILE

        exit 0
      fi
    fi

    # Optional hardcoded credentials
    if [ "$USERNAME" = "Bill" ] && [ "$PASSWORD" = "tms" ]; then
      echo 3600 0 0
      log "Fallback credentials Bill/tms authenticated for 3600 seconds"
      exit 0
    fi

    # Invalid voucher
    log "Failed login attempt with voucher $PASSWORD"
    exit 1
    ;;

  client_auth|client_deauth|idle_deauth|timeout_deauth|ndsctl_auth|ndsctl_deauth|shutdown_deauth)
    INGOING_BYTES="$3"
    OUTGOING_BYTES="$4"
    SESSION_START="$5"
    SESSION_END="$6"

    case "$METHOD" in
      client_deauth|idle_deauth|timeout_deauth|shutdown_deauth)
        log "Session ended MAC=$MAC IN=$INGOING_BYTES OUT=$OUTGOING_BYTES START=$SESSION_START END=$SESSION_END"

        # Remove from sessions.json
        if [ -f $SESSIONS_FILE ]; then
          jq --arg mac "$MAC" '.sessions |= map(select(.mac != $mac))' $SESSIONS_FILE > $SESSIONS_FILE.tmp && mv $SESSIONS_FILE.tmp $SESSIONS_FILE
        fi
        ;;
      client_auth)
        log "Client authenticated MAC=$MAC IN=$INGOING_BYTES OUT=$OUTGOING_BYTES START=$SESSION_START"
        ;;
    esac
    ;;
esac
