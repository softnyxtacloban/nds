uci add cron job
uci set cron.@job[-1].enabled='1'
uci set cron.@job[-1].command='/etc/nodogsplash/session_monitor.sh'
uci set cron.@job[-1].minute='*'
uci set cron.@job[-1].hour='*'
uci set cron.@job[-1].day='*'
uci set cron.@job[-1].month='*'
uci set cron.@job[-1].week='*'
uci commit cron
/etc/init.d/cron restart
