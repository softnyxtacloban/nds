#!/bin/sh

METHOD="$1"
MAC="$2"

# Path to your voucher database
VOUCHER_FILE="/etc/nodogsplash/vouchers.txt"

case "$METHOD" in
  auth_client)
    USERNAME="$3"
    PASSWORD="$4"

    # Check if voucher code exists in database
    if [ -f "$VOUCHER_FILE" ]; then
      # Each line: CODE|DURATION_SECONDS
      DURATION=$(grep -E "^$PASSWORD\|" "$VOUCHER_FILE" | cut -d'|' -f2)
      if [ -n "$DURATION" ]; then
        # Authenticated: echo <duration_seconds> <upload_bytes> <download_bytes>
        # 0 for unlimited upload/download
        echo "$DURATION 0 0"
        exit 0
      fi
    fi

    # Optional: fallback for hardcoded credentials
    if [ "$USERNAME" = "Bill" ] && [ "$PASSWORD" = "tms" ]; then
      echo 3600 0 0   # 1 hour
      exit 0
    fi

    # Invalid credentials / voucher
    exit 1
    ;;

  client_auth|client_deauth|idle_deauth|timeout_deauth|ndsctl_auth|ndsctl_deauth|shutdown_deauth)
    INGOING_BYTES="$3"
    OUTGOING_BYTES="$4"
    SESSION_START="$5"
    SESSION_END="$6"
    # Optional: log or process session events here
    ;;
esac
