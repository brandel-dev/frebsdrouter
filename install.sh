#!/bin/sh
set -eu
[ "$(id -u)" -eq 0 ] || { echo "Ejecutar como root/doas" >&2; exit 1; }
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

install -d -m 0755 /usr/local/libexec/fw0 /usr/local/etc/fw0/templates /usr/local/etc/rc.d
install -d -m 0700 /usr/local/etc/fw0/vpn/profiles /usr/local/etc/fw0/secrets /var/db/fw0
install -d -m 0755 /etc/pf/tables /usr/local/etc/ssh/sshd_config.d

install -m 0640 "$ROOT/usr-local/etc/fw0/inventory.conf" /usr/local/etc/fw0/inventory.conf.sample
if [ ! -e /usr/local/etc/fw0/inventory.conf ]; then
    install -m 0640 "$ROOT/usr-local/etc/fw0/inventory.conf" /usr/local/etc/fw0/inventory.conf
fi
install -m 0644 "$ROOT/etc/pf.conf" /usr/local/etc/fw0/templates/pf.conf.in
install -m 0600 "$ROOT/etc/doas.conf" /usr/local/etc/doas.conf.fw0.sample

for f in "$ROOT"/usr-local/libexec/fw0/*; do
    install -m 0755 "$f" "/usr/local/libexec/fw0/$(basename "$f")"
done
for f in "$ROOT"/usr-local/rc.d/*; do
    install -m 0755 "$f" "/usr/local/etc/rc.d/$(basename "$f")"
done
for f in "$ROOT"/etc/pf/tables/*.txt; do
    name=$(basename "$f")
    # Never overwrite operator-populated endpoint/DNS tables on upgrade.
    [ -e "/etc/pf/tables/$name" ] || install -m 0644 "$f" "/etc/pf/tables/$name"
done
for f in "$ROOT"/usr-local/etc/fw0/vpn/profiles/*.example; do
    install -m 0600 "$f" "/usr/local/etc/fw0/vpn/profiles/$(basename "$f")"
done

echo "fw0 v2 instalado en modo inerte. No se cargó PF ni se modificó routing."
echo "1) complete inventory.conf y control_dns.txt"
echo "2) siga README.md / PLAN_DE_EJECUCION.md desde consola local"
