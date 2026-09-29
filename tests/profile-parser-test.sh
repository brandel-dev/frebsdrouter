#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$ROOT/usr-local/libexec/fw0/fw0-lib"
D=$(mktemp -d)
trap 'rm -rf "$D"' EXIT HUP INT TERM
FW0_PROFILES_DIR=$D; export FW0_PROFILES_DIR

cat > "$D/good.meta" <<'EOM'
WG_ADDRESS="10.2.0.2/32"
WG_ENDPOINT_IP="203.0.113.10"
WG_ENDPOINT_PORT="51820"
EOM
cat > "$D/good.conf" <<'EOC'
[Interface]
PrivateKey = abc
[Peer]
PublicKey = def
AllowedIPs = 0.0.0.0/0
Endpoint = 203.0.113.10:51820
EOC
fw0_profile_validate good || { echo "PROFILE_TEST=FAIL good rejected"; exit 1; }

PWN="$D/pwned"
cat > "$D/bad.meta" <<EOM
WG_ADDRESS="10.2.0.2/32"
WG_ENDPOINT_IP="203.0.113.10"
WG_ENDPOINT_PORT="51820"
EVIL=\$(touch "$PWN")
EOM
cp "$D/good.conf" "$D/bad.conf"
if fw0_profile_validate bad; then echo "PROFILE_TEST=FAIL malicious meta accepted"; exit 1; fi
[ ! -e "$PWN" ] || { echo "PROFILE_TEST=FAIL malicious meta executed"; exit 1; }

echo "PROFILE_TEST=PASS"
