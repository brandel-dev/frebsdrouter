#!/bin/sh
set -eu
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH
INV=/usr/local/etc/fw0/inventory.conf
LIB=/usr/local/libexec/fw0/fw0-lib
. "$LIB"
. "$INV"
PF_CONF=/etc/pf.conf
LASTGOOD=/etc/pf.conf.lastgood
DNS_TABLE=/etc/pf/tables/control_dns.txt

[ -r "$PF_CONF" ] || { echo "GATE03=FAIL (falta $PF_CONF)"; exit 1; }
pfctl -nf "$PF_CONF" || { echo "GATE03=FAIL (sintaxis PF)"; exit 1; }
fw0_pf_enabled || { echo "GATE03=FAIL (PF apagado)"; exit 1; }
[ -r "$LASTGOOD" ] || { echo "GATE03=FAIL (PF no fue confirmado con pf-safe-confirm)"; exit 1; }
[ "$(fw0_hash_file "$PF_CONF")" = "$(fw0_hash_file "$LASTGOOD")" ] || { echo "GATE03=FAIL (ruleset activo difiere de last-good confirmado)"; exit 1; }

# Control DNS must be explicitly populated and correspond to the resolver in use.
count=0
while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|'#'*) continue;; esac
    fw0_valid_ipv4 "$line" || { echo "GATE03=FAIL (control_dns contiene IPv4 inválida: $line)"; exit 1; }
    count=$((count + 1))
done < "$DNS_TABLE"
[ "$count" -ge 1 ] || { echo "GATE03=FAIL (control_dns vacío)"; exit 1; }
resolver=$(awk '/^nameserver[[:space:]]+/ {print $2; exit}' /etc/resolv.conf)
[ -n "$resolver" ] || { echo "GATE03=FAIL (/etc/resolv.conf sin nameserver)"; exit 1; }
pfctl -t control_dns -T show | awk '{print $1}' | grep -Fx "$resolver" >/dev/null || { echo "GATE03=FAIL (resolver $resolver no está en <control_dns>)"; exit 1; }
setfib "$FIB_CONTROL" getent hosts "$DNS_PROBE_HOST" >/dev/null 2>&1 || { echo "GATE03=FAIL (DNS de control no resuelve $DNS_PROBE_HOST)"; exit 1; }

for label in fw0:block-lan-to-wan fw0:block-wan-ssh fw0:allow-ts-ssh fw0:lan-vpn-egress fw0:lan2-ingress fw0:tailscale-stun fw0:control-dns; do
    pfctl -s labels | grep -F "$label" >/dev/null || { echo "GATE03=FAIL (falta label $label)"; exit 1; }
done
pfctl -sn | grep -F "$WAN_IF" | grep -F "$LAN_NET" >/dev/null && { echo "GATE03=FAIL (NAT LAN sobre WAN)"; exit 1; }
pfctl -sn | grep -F "$WAN_IF" | grep -F "$LAN2_NET" >/dev/null && { echo "GATE03=FAIL (NAT LAN2 sobre WAN)"; exit 1; }
service tailscaled onestatus >/dev/null 2>&1 || { echo "GATE03=FAIL (tailscaled apagado)"; exit 1; }
ifconfig "$TS_IF" >/dev/null 2>&1 || { echo "GATE03=FAIL ($TS_IF ausente)"; exit 1; }
ts_ip=$(tailscale ip -4 | awk 'NR==1{print;exit}')
sockstat -4 -l | grep -E "[[:space:]]${ts_ip}:22[[:space:]]" >/dev/null || { echo "GATE03=FAIL (sshd no escucha por Tailscale)"; exit 1; }
echo "GATE03_AUTOMATED=PASS"
echo "GATE03_MANUAL=REQUIRED (confirmar reconexión desde una sesión SSH nueva)"
