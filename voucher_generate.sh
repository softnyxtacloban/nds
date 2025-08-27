#!/bin/sh
echo "Content-type: application/json"
echo ""

QUERY=$(echo "$QUERY_STRING" | tr '&' '\n')
for param in $QUERY; do
    key=$(echo "$param" | cut -d= -f1)
    value=$(echo "$param" | cut -d= -f2)
    case $key in
      hours) HOURS="$value" ;;
      count) COUNT="$value" ;;
    esac
done

VOUCHERS_FILE="/etc/nodogsplash/vouchers.json"
[ ! -f "$VOUCHERS_FILE" ] && echo '{"vouchers":[]}' > $VOUCHERS_FILE

CODES=()
for i in $(seq 1 $COUNT); do
  CODE=$(tr -dc A-Z0-9 </dev/urandom | head -c6)
  jq --arg code "$CODE" --argjson hours "$HOURS" \
     '.vouchers += [{"code":$code,"hours":$hours,"used":0,"active":true}]' \
     $VOUCHERS_FILE > $VOUCHERS_FILE.tmp && mv $VOUCHERS_FILE.tmp $VOUCHERS_FILE
  CODES+=("$CODE")
done

printf '{"codes": ['
for i in "${!CODES[@]}"; do
  [ $i -ne 0 ] && printf ','
  printf '"%s"' "${CODES[$i]}"
done
printf ']}\n'
