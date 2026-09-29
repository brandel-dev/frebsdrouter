#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail() { echo "STATIC_CHECK=FAIL $*" >&2; exit 1; }

# POSIX shell syntax for executables/scripts.
for f in "$ROOT/install.sh" "$ROOT"/usr-local/libexec/fw0/* "$ROOT"/usr-local/rc.d/*; do
    sh -n "$f" || fail "shell syntax: $f"
done

# Every PF marker must be rendered.
markers=$(grep -o '@[A-Z_][A-Z_]*@' "$ROOT/etc/pf.conf" | sort -u || true)
for marker in $markers; do
    grep -F "$marker" "$ROOT/usr-local/libexec/fw0/render-pf" >/dev/null || fail "render-pf no sustituye $marker"
done

# Security regressions we specifically fixed.
! grep -R -n -E '\. "\$META"|source .*\.meta|eval .*\.meta' "$ROOT/usr-local/libexec/fw0" >/dev/null || fail ".meta vuelve a ejecutarse como shell"
grep -F 'pfctl -M -i "$WG_IF" -k 0.0.0.0/0' "$ROOT/usr-local/libexec/fw0/vpnctl" >/dev/null || fail "vpnctl no usa pfctl -M"
grep -F 'fw0:block-lan-to-wan' "$ROOT/etc/pf.conf" >/dev/null || fail "falta invariante LAN->WAN"
grep -F 'tunnelfib "$FIB_CONTROL"' "$ROOT/usr-local/libexec/fw0/vpnctl" >/dev/null || fail "falta tunnelfib control"
! grep -R -n --exclude='static-check.sh' 'proton_endpoints' "$ROOT" >/dev/null || fail "quedó nombre de tabla v1 proton_endpoints"

for rel in \
    runbooks/00-preambulo.md runbooks/02-fibs.md runbooks/03-pf-bootstrap.md \
    runbooks/04-wireguard-profile.md runbooks/04-killswitch-test.md \
    etc/pf/tables/control_dns.txt etc/pf/tables/vpn_endpoints.txt \
    usr-local/libexec/fw0/pf-safe-confirm usr-local/libexec/fw0/pf-auto-rollback \
    usr-local/libexec/fw0/k4-record usr-local/rc.d/fw0_preflight usr-local/rc.d/fw0_vpn; do
    [ -e "$ROOT/$rel" ] || fail "falta $rel"
done

echo "STATIC_CHECK=PASS"
