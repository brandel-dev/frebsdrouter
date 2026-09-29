#!/bin/sh
set -eu
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH
INV=/usr/local/etc/fw0/inventory.conf
LIB=/usr/local/libexec/fw0/fw0-lib
VPN_DIR=/usr/local/etc/fw0/vpn
PROOF=/var/db/fw0/gate04-k4.ok
. "$LIB"
. "$INV"

ifconfig "$WG_IF" >/dev/null 2>&1 || { echo "GATE04=FAIL ($WG_IF no existe)"; exit 1; }
ifconfig "$WG_IF" | grep -q "fib: $FIB_DATA" || { echo "GATE04=FAIL (fib incorrecta)"; exit 1; }
tunnelfib=$(ifconfig "$WG_IF" | awk '/tunnelfib:/ {print $2; exit}')
if [ "$FIB_CONTROL" = 0 ]; then
    [ -z "$tunnelfib" ] || [ "$tunnelfib" = 0 ] || { echo "GATE04=FAIL (tunnelfib incorrecta)"; exit 1; }
else
    [ "$tunnelfib" = "$FIB_CONTROL" ] || { echo "GATE04=FAIL (tunnelfib incorrecta)"; exit 1; }
fi

profile=$(cat "$VPN_DIR/active" 2>/dev/null || true)
fw0_valid_profile "$profile" || { echo "GATE04=FAIL (sin perfil activo válido)"; exit 1; }
FW0_PROFILES_DIR=$VPN_DIR/profiles; export FW0_PROFILES_DIR
fw0_profile_validate "$profile" || { echo "GATE04=FAIL (perfil activo inválido)"; exit 1; }

now=$(date +%s)
hs=$(wg show "$WG_IF" latest-handshakes 2>/dev/null | awk 'BEGIN{m=0} $2>m{m=$2} END{print m}')
[ "${hs:-0}" -gt 0 ] 2>/dev/null && [ $((now - hs)) -le 180 ] || { echo "GATE04=FAIL (handshake ausente o antiguo)"; exit 1; }
route -n get -fib "$FIB_DATA" "$EGRESS_PROBE_IP" | grep -q "interface: $WG_IF" || { echo "GATE04=FAIL (FIB datos no usa $WG_IF)"; exit 1; }
setfib "$FIB_DATA" ping -c 2 -t 5 "$EGRESS_PROBE_IP" >/dev/null 2>&1 || { echo "GATE04=FAIL (sin egress dentro del túnel)"; exit 1; }

[ -r "$PROOF" ] || {
    echo "GATE04=INCOMPLETE (estado estático correcto; faltan K4-A/B/C/D/E)"
    echo "Ejecute runbooks/04-killswitch-test.md"
    exit 2
}

need_eq() {
    key=$1 expected=$2
    actual=$(fw0_kv_get "$key" "$PROOF")
    [ "$actual" = "$expected" ] || { echo "GATE04=INCOMPLETE (proof stale: $key)"; exit 2; }
}
need_eq VERSION 2
need_eq WAN_IF "$WAN_IF"
need_eq LAN_IF "$LAN_IF"
need_eq WG_IF "$WG_IF"
need_eq PROFILE "$profile"
need_eq INVENTORY_SHA256 "$(fw0_hash_file "$INV")"
need_eq PF_SHA256 "$(fw0_hash_file /etc/pf.conf)"
need_eq PROFILE_CONF_SHA256 "$(fw0_hash_file "$FW0_PROFILE_CONF")"
need_eq PROFILE_META_SHA256 "$(fw0_hash_file "$FW0_PROFILE_META")"
for k in K4_A K4_B K4_C K4_D K4_E; do need_eq "$k" PASS; done

version=$(freebsd-version -ku 2>/dev/null | tr '\n' ',' | sed 's/,$//')
[ -n "$version" ] || version=$(uname -K)
need_eq FREEBSD_VERSION "$version"
echo "GATE04=PASS (runtime + K4-A/B/C/D/E vinculados por hash; perfil=$profile)"
