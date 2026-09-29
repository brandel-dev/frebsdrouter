# Gate 04 — pruebas destructivas K4 del killswitch

**Solo desde consola local**, con un cliente en LAN y captura simultánea de WAN.
No ejecute estas pruebas únicamente por SSH.

Antes de empezar, asegure `vpnctl status = HEALTHY` y abra una captura en WAN:

```sh
tcpdump -ni <WAN_IF> 'net <LAN_NET>'
```

## K4-A — operación normal

El cliente LAN debe navegar por la VPN. En WAN no debe verse ninguna dirección
origen perteneciente a `LAN_NET`.

## K4-B — desaparición de wg0

Use el orden de producción:

```sh
route delete -fib 1 default
pfctl -M -i wg0 -k 0.0.0.0/0
ifconfig wg0 destroy
```

El cliente debe perder Internet inmediatamente y no debe aparecer tráfico LAN
en WAN. Restaure:

```sh
/usr/local/libexec/fw0/vpnctl restore-last-good
```

## K4-C — PF ausente, routing todavía fail-close

Con `wg0` retirado y FIB1 sin default:

```sh
pfctl -d
```

El cliente debe continuar sin Internet. Esto demuestra que la barrera de
routing es independiente de PF. Reactive inmediatamente:

```sh
pfctl -e
pfctl -f /etc/pf.conf
/usr/local/libexec/fw0/vpnctl restore-last-good
```

## K4-D — ruta WAN errónea en FIB1, PF todavía bloquea

Esta prueba demuestra la segunda barrera. Obtenga el gateway WAN desde FIB0:

```sh
GW=$(route -n get -fib 0 default | awk '/gateway:/ {print $2; exit}')
```

Desde consola, retire temporalmente la default VPN e intente introducir una
ruta de WAN en FIB1. Dependiendo de la topología puede ser necesario añadir
primero una ruta host hacia el gateway. El objetivo es que FIB1 tenga una ruta
que físicamente intentaría salir por WAN. Durante la prueba:

- el cliente **no** debe recuperar Internet;
- el contador de `fw0:block-lan-to-wan` debe aumentar;
- `tcpdump` no debe mostrar paquetes LAN reenviados exitosamente por WAN.

Retire inmediatamente las rutas de prueba y restaure `vpnctl restore-last-good`.
Si la topología impide construir una ruta WAN utilizable en FIB1, documente esa
limitación y no registre Gate 04 como completo hasta reproducir K4-D en una VM o
laboratorio equivalente.

## K4-E — fallo durante cambio de perfil

Con un perfil bueno activo, cree una copia temporal cuyo `Endpoint` apunte a una
IPv4 de documentación no enrutable (por ejemplo `192.0.2.1`) manteniendo las
mismas claves. Su `.meta` debe coincidir exactamente con el endpoint del `.conf`.
Ejecute `vpnctl switch <perfil-roto>`.

Resultado aceptable:

1. `vpnctl` falla el candidato y vuelve al `last-good`, o
2. entra en `QUARANTINE` con FIB1 sin default.

Nunca debe aparecer fallback a WAN.

## Registrar evidencia fresca

Después de observar **las cinco pruebas** con la configuración actualmente
instalada:

```sh
doas /usr/local/libexec/fw0/k4-record I_OBSERVED_K4_A_B_C_D_E
doas /usr/local/libexec/fw0/fw-verify 04
```

El comprobante incluye hashes de `inventory.conf`, `/etc/pf.conf` y del perfil
activo. Cualquier cambio posterior lo convierte automáticamente en `STALE` y
obliga a repetir K4.
