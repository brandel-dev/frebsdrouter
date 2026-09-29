# fw0 v2 — FreeBSD fail-close router

`fw0` separa el plano de administración del plano de datos usando dos FIB:

```text
FIB0 / CONTROL : WAN + Tailscale + DNS de control + paquetes encapsulados WG
FIB1 / DATA    : LAN -> wg0 solamente
wg0            : fib=1, tunnelfib=0
```

## Invariantes

1. Una dirección de `LAN_NET` o `LAN2_NET` nunca debe salir por `WAN_IF`.
2. FIB1 no tiene default salvo cuando `vpnctl` está `HEALTHY`.
3. Caída/cambio/error de WireGuard produce rollback o `QUARANTINE`, nunca WAN.
4. PF es una segunda barrera independiente del routing.
5. Una recarga PF no se considera buena hasta confirmarla desde otra conexión.
6. Gate 04 queda obsoleto automáticamente si cambia PF, inventario o perfil.

## Qué cambió respecto de v1

- `pf-safe-reload` ahora implementa carga transaccional con rollback autónomo.
- `pf-safe-confirm` hace el commit y solo entonces activa PF para futuros boots.
- `vpnctl` vuelve a usar correctamente `pfctl -M` al purgar estados.
- perfiles `.meta` se parsean como datos y nunca se ejecutan como root.
- la default de FIB1 se instala **después** de handshake + egress probado.
- `<vpn_endpoints>` se genera desde todos los perfiles válidos.
- `control_dns` es obligatorio antes de Gate 03.
- PF tiene labels estables para verificar invariantes.
- K4 ahora cubre A/B/C/D/E y el proof lleva hashes/versiones.
- MSS scrub se evalúa antes de reglas `quick`.
- IPv6 forwarding permanece desactivado hasta diseñarlo explícitamente.
- se incluyen `rc.d/fw0_preflight` y `rc.d/fw0_vpn` para arranque fail-close.

## Instalación inerte

Desde consola local:

```sh
doas sh ./install.sh
```

El instalador **no** carga PF, no toca routing y no habilita servicios.

A continuación:

```sh
doas vi /usr/local/etc/fw0/inventory.conf
# elegir WAN_MODE y verificar AUX_ROLE=lan2 para la segunda LAN

doas /usr/local/libexec/fw0/fw-verify 00
```

Siga los runbooks en orden:

1. `runbooks/00-preambulo.md`
2. `runbooks/02-fibs.md`
3. `runbooks/03-pf-bootstrap.md`
4. `runbooks/04-wireguard-profile.md`
5. `runbooks/04-killswitch-test.md`

## PF: flujo correcto

```sh
doas vi /etc/pf/tables/control_dns.txt
doas /usr/local/libexec/fw0/render-pf
doas /usr/local/libexec/fw0/pf-safe-reload /etc/pf.conf.candidate
```

El último comando imprime un ID. Abra una **nueva** sesión SSH por Tailscale y:

```sh
doas /usr/local/libexec/fw0/pf-safe-confirm <transaction-id>
doas /usr/local/libexec/fw0/fw-verify 03
```

Sin confirmación, el ruleset anterior se restaura automáticamente.

## VPN

```sh
doas /usr/local/libexec/fw0/vpnctl switch <perfil>
doas /usr/local/libexec/fw0/vpnctl status
doas /usr/local/libexec/fw0/fw-verify 04
```

`fw-verify 04` devolverá `INCOMPLETE` hasta completar K4-A/B/C/D/E y registrar
la evidencia con `k4-record`.

## Arranque

No habilite los scripts rc hasta cerrar sus gates. Después:

```sh
sysrc fw0_preflight_enable=YES
sysrc fw0_vpn_enable=YES
```

`fw0_preflight` elimina primero cualquier default de FIB1. `fw0_vpn` se niega a
levantar datos si PF no coincide con el `lastgood` confirmado.

## Estado de implementación

**Implementado en este paquete:** núcleo 00–04, PF transaccional, state machine
VPN, proof K4 fresco y scaffolding de boot.

**Pendiente deliberadamente:** DHCP/DNS de datos (05), gestión avanzada (07),
XMPP rescue (08), healthd/métricas (09), matriz completa de reboot/fault tests
(10), backup/DR (11) y aceptación 72 h (12). `fw-verify all` continúa devolviendo
`INCOMPLETE` hasta que esos gates existan; no se presentan como terminados.
