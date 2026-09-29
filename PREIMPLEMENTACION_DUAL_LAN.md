# Preimplementación dual-LAN

## Topología objetivo

- `re0`: WAN hacia el Huawei; el modo (`dhcp` o `static`) debe confirmarse.
- `ue1`: cliente Linux, `10.10.80.1/24`.
- `ue0`: enlace hacia el router downstream, `10.10.90.1/24`.
- Ambas redes usan FIB1 y salen exclusivamente por `wg0` hacia ProtonVPN.
- La administración usa Tailscale en FIB0.

## Suposiciones que deben confirmarse antes del despliegue

1. `ue0` será una red enrutada independiente, no un bridge con `ue1`.
2. El router downstream tendrá su interfaz WAN en `10.10.90.0/24` y usará
   `10.10.90.1` como gateway.
3. FreeBSD entregará DHCP únicamente en `ue1` y `ue0`, salvo que el router
   downstream se configure con IP estática.
4. Las dos LAN estarán aisladas entre sí inicialmente.
5. IPv6 permanecerá deshabilitado hasta diseñar su política VPN.

## Cambios bloqueantes en el paquete actual

- Mantener `LAN_IF/LAN_NET` como primera red y añadir `LAN2_IF/LAN2_NET` en PF,
  NAT, preflight y verificadores.
- Cambiar `AUX_ROLE` a `lan2` y validar MAC/enlace de `ue0`.
- Añadir DHCP/DNS por interfaz, con leases y resolutores separados.
- Aplicar bloqueo LAN→WAN para ambas redes y NAT de ambas redes en `wg0`.
- Bloquear `10.10.80.0/24 ↔ 10.10.90.0/24` por defecto.
- Extender K4 para probar egress y killswitch desde ambas redes.
- Confirmar el nombre real de la interfaz Tailscale; `tailscale0` no debe
  asumirse sin verificarlo con `ifconfig`.
- Completar `control_dns.txt`, el modo WAN y el perfil real de ProtonVPN.

## Secuencia segura

1. Inventario y enlaces, sin PF.
2. FIB0/FIB1 y rutas, conservando consola local.
3. PF candidato validado sintácticamente.
4. Recarga transaccional y confirmación desde una nueva sesión Tailscale.
5. WireGuard con prueba de una IP por cada LAN.
6. DHCP/DNS y pruebas de fuga.
7. Router downstream y cliente Linux.
8. Reinicios, pérdida de WAN/VPN y prueba de recuperación.

No se debe conectar la LAN productiva ni habilitar DHCP hasta pasar los gates
anteriores.
