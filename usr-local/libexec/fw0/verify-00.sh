#!/bin/sh
set -eu
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH
INV=/usr/local/etc/fw0/inventory.conf
LIB=/usr/local/libexec/fw0/fw0-lib
. "$LIB"
[ -r "$INV" ] || { echo "GATE00=FAIL (falta inventario)"; exit 1; }
. "$INV"

for v in WAN_IF WAN_MAC LAN_IF LAN_MAC AUX_IF AUX_MAC LAN_NET LAN_GW LAN2_IF LAN2_MAC LAN2_NET LAN2_GW; do
    eval value=\"\${$v}\"
    [ -n "$value" ] && [ "${value#REEMPLAZAR}" = "$value" ] || { echo "GATE00=FAIL ($v pendiente)"; exit 1; }
done
[ "$WAN_IF" != "$LAN_IF" ] && [ "$WAN_IF" != "$AUX_IF" ] && [ "$LAN_IF" != "$AUX_IF" ] || { echo "GATE00=FAIL (roles físicos duplicados)"; exit 1; }
fw0_valid_cidr4 "$LAN_NET" || { echo "GATE00=FAIL (LAN_NET inválida)"; exit 1; }
fw0_valid_ipv4 "$LAN_GW" || { echo "GATE00=FAIL (LAN_GW inválida)"; exit 1; }
fw0_valid_cidr4 "$LAN2_NET" || { echo "GATE00=FAIL (LAN2_NET inválida)"; exit 1; }
fw0_valid_ipv4 "$LAN2_GW" || { echo "GATE00=FAIL (LAN2_GW inválida)"; exit 1; }
[ "$FIB_CONTROL" = 0 ] && [ "$FIB_DATA" = 1 ] || { echo "GATE00=FAIL (fw0 v2 exige FIB_CONTROL=0 y FIB_DATA=1)"; exit 1; }

for spec in "$WAN_IF:$WAN_MAC" "$LAN_IF:$LAN_MAC" "$LAN2_IF:$LAN2_MAC"; do
    iface=${spec%%:*}; expected=${spec#*:}
    ifconfig "$iface" >/dev/null 2>&1 || { echo "GATE00=FAIL ($iface no existe)"; exit 1; }
    actual=$(ifconfig "$iface" | awk '/ether / {print $2; exit}')
    [ "$(printf '%s' "$actual" | tr A-F a-f)" = "$(printf '%s' "$expected" | tr A-F a-f)" ] || { echo "GATE00=FAIL (MAC de $iface cambió: $actual)"; exit 1; }
done

case "$AUX_ROLE" in
    disabled)
        if ifconfig "$AUX_IF" | sed -n '1p' | grep -q '<[^>]*UP'; then echo "GATE00=FAIL (AUX_ROLE=disabled pero $AUX_IF está UP)"; exit 1; fi
        if ifconfig "$AUX_IF" inet 2>/dev/null | grep -q 'inet '; then echo "GATE00=FAIL (AUX_ROLE=disabled pero $AUX_IF tiene IPv4)"; exit 1; fi
        ;;
    lan2) [ "$LAN2_IF" = "$AUX_IF" ] || { echo "GATE00=FAIL (LAN2_IF debe coincidir con AUX_IF)"; exit 1; } ;;
    vlan-trunk|mgmt-oob) echo "GATE00=FAIL (AUX_ROLE incompatible con dual-LAN)"; exit 1 ;;
    *) echo "GATE00=FAIL (AUX_ROLE inválido)"; exit 1 ;;
esac

case "$WAN_MODE" in
    dhcp) : ;;
    static)
        fw0_valid_ipv4 "$WAN_ADDR" && fw0_valid_ipv4 "$WAN_GW" || { echo "GATE00=FAIL (WAN static incompleta)"; exit 1; }
        [ -n "$WAN_MASK" ] || { echo "GATE00=FAIL (WAN_MASK vacía)"; exit 1; }
        ;;
    pppoe) : ;;
    *) echo "GATE00=FAIL (WAN_MODE debe elegirse explícitamente: dhcp|static|pppoe)"; exit 1 ;;
esac

[ "$(sysctl -n hw.physmem)" -ge 3221225472 ] || { echo "GATE00=FAIL (RAM utilizable menor a 3 GiB)"; exit 1; }
echo "GATE00=PASS"
