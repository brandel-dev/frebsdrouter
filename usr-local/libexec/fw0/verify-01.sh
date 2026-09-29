#!/bin/sh
set -eu
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH
. /usr/local/etc/fw0/inventory.conf

service tailscaled onestatus >/dev/null 2>&1 || { echo "GATE01=FAIL (tailscaled apagado)"; exit 1; }
ifconfig "$TS_IF" >/dev/null 2>&1 || { echo "GATE01=FAIL ($TS_IF no existe)"; exit 1; }
ts_ip=$(tailscale ip -4 | awk 'NR==1 {print; exit}')
[ -n "$ts_ip" ] || { echo "GATE01=FAIL (sin IP Tailscale)"; exit 1; }
sockstat -4 -l | grep -E "[[:space:]]${ts_ip}:22[[:space:]]" >/dev/null || { echo "GATE01=FAIL (sshd no escucha en IP Tailscale)"; exit 1; }
wan_ip=$(ifconfig "$WAN_IF" inet 2>/dev/null | awk '/inet / {print $2; exit}')
if [ -n "${wan_ip:-}" ] && sockstat -4 -l | grep -E "[[:space:]](${wan_ip}|\*):22[[:space:]]" >/dev/null; then
    echo "GATE01=FAIL (sshd expuesto en WAN o wildcard)"; exit 1
fi
# Reject obviously wrong clocks (2024-01-01); TLS/control-plane depends on sane time.
[ "$(date +%s)" -ge 1704067200 ] || { echo "GATE01=FAIL (reloj del sistema no es plausible)"; exit 1; }
echo "GATE01_AUTOMATED=PASS"
echo "GATE01_MANUAL=REQUIRED (abra una segunda sesión SSH nueva por Tailscale)"
