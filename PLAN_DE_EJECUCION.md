# Plan de ejecución fw0 v2

Cada fase conserva fail-close. `INCOMPLETE` impide considerar el appliance listo.

## 00 — inventario

Mapear NIC/MAC/roles, elegir `WAN_MODE`, mantener AUX apagada salvo decisión
explícita. Gate: `fw-verify 00`.

## 01 — administración

Tailscale + OpenSSH ligado solo a la IP Tailscale, reloj plausible y dos sesiones
SSH nuevas verificadas manualmente. Gate automático: `fw-verify 01`.

## 02 — routing

`net.fibs>=2`, WAN FIB0, LAN FIB1, IPv4 forwarding on, IPv6 forwarding off, FIB1
sin default. Gate: `fw-verify 02`.

## 03 — PF fail-close transaccional

Completar `control_dns`, renderizar PF, cargar con `pf-safe-reload`, abrir una
nueva sesión SSH y hacer commit con `pf-safe-confirm`. Gate: `fw-verify 03`.

## 04 — WireGuard + killswitch

Perfil estricto, wg0 `fib=1/tunnelfib=0`, prueba con ruta host, default solo tras
HEALTHY, rollback/quarantine y K4-A/B/C/D/E. Gate: `fw-verify 04`.

## 05 — DHCP/DNS de datos — pendiente

Resolver ligado a LAN/FIB1, sin fallback al resolver de control, bloqueo de DNS
directo/DoT y pruebas de fuga.

## 06 — operación VPN ampliada — pendiente

Matriz de concurrencia, endpoints caídos, perfiles corruptos y fault injection.
El state machine base ya existe en `vpnctl`.

## 07 — gestión permanente — pendiente

ACL Tailscale/allowlist y canal secundario solo si es realmente independiente.

## 08 — rescate XMPP — pendiente

Daemon sin shell, replay protection, rate limiting y comandos cerrados mediante
`fwctl`.

## 09 — observabilidad — pendiente

`healthd` puede alertar o forzar QUARANTINE; nunca crea fallback WAN.

## 10 — boot/fault matrix — pendiente

Los scripts `fw0_preflight`/`fw0_vpn` ya están incluidos, pero la aceptación exige
reboots repetidos con WAN/VPN/Tailscale presentes y ausentes.

## 11 — backup/DR — pendiente

Backup cifrado + restore bare-metal/VM demostrado.

## 12 — aceptación — pendiente

72 h soak, cambios de perfil, pérdida/retorno WAN, temperatura/carga y capturas.
