# Gate 02 — separación de FIB

Ejecute con consola local disponible.

En `/boot/loader.conf`:

```conf
net.fibs="2"
if_wg_load="YES"
```

En `/etc/rc.conf`, configure la LAN con la dirección de `LAN_GW`, pero **sin
ruta por defecto en FIB1**. Después del reinicio:

```sh
ifconfig <WAN_IF> fib 0
ifconfig <LAN_IF> fib 1
sysctl net.inet.ip.forwarding=1
sysctl net.inet6.ip6.forwarding=0
route delete -fib 1 default 2>/dev/null || true

setfib 0 netstat -rn -f inet
setfib 1 netstat -rn -f inet
/usr/local/libexec/fw0/fw-verify 02
```

La default de FIB0 debe utilizar WAN. FIB1 debe quedar sin default hasta que
`vpnctl` pruebe WireGuard. Cuando Gate 04 quede cerrado podrá habilitar:

```sh
sysrc fw0_preflight_enable=YES
```

`fw0_preflight` repite el fail-close en cada arranque: retira primero cualquier
default de FIB1 y después aplica las FIB de WAN/LAN.
