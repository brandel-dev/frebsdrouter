#!/bin/sh
set -eu
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH
. /usr/local/etc/fw0/inventory.conf

[ "$(sysctl -n net.fibs)" -ge 2 ] || { echo "GATE02=FAIL (se requieren >=2 FIB)"; exit 1; }
lan_fib=$(ifconfig "$LAN_IF" | awk '/fib: / {for(i=1;i<=NF;i++) if($i=="fib:"){print $(i+1); exit}}')
[ "${lan_fib:-}" = "$FIB_DATA" ] || { echo "GATE02=FAIL ($LAN_IF no está en FIB $FIB_DATA)"; exit 1; }
lan2_fib=$(ifconfig "$LAN2_IF" | awk '/fib: / {for(i=1;i<=NF;i++) if($i=="fib:"){print $(i+1); exit}}')
[ "${lan2_fib:-}" = "$FIB_DATA" ] || { echo "GATE02=FAIL ($LAN2_IF no está en FIB $FIB_DATA)"; exit 1; }
wan_fib=$(ifconfig "$WAN_IF" | awk '/fib: / {for(i=1;i<=NF;i++) if($i=="fib:"){print $(i+1); exit}}')
[ "${wan_fib:-0}" = "$FIB_CONTROL" ] || { echo "GATE02=FAIL ($WAN_IF no está en FIB $FIB_CONTROL)"; exit 1; }
control_route=$(route -n get -fib "$FIB_CONTROL" default 2>/dev/null) || { echo "GATE02=FAIL (FIB control sin default)"; exit 1; }
printf '%s\n' "$control_route" | grep -q "interface: $WAN_IF" || { echo "GATE02=FAIL (default de control no usa $WAN_IF)"; exit 1; }
if route -n get -fib "$FIB_DATA" default >/dev/null 2>&1; then echo "GATE02=FAIL (FIB datos ya tiene default)"; exit 1; fi
[ "$(sysctl -n net.inet.ip.forwarding)" = 1 ] || { echo "GATE02=FAIL (forwarding IPv4 apagado)"; exit 1; }
[ "$(sysctl -n net.inet6.ip6.forwarding)" = 0 ] || { echo "GATE02=FAIL (forwarding IPv6 debe seguir apagado)"; exit 1; }
echo "GATE02=PASS"
