# Gate 03 — PF transaccional

## 1. DNS de control

Antes de bloquear el plano WAN, `/etc/pf/tables/control_dns.txt` debe contener
al menos el `nameserver` IPv4 usado en `/etc/resolv.conf`, uno por línea.

Ejemplo:

```text
1.1.1.1
1.0.0.1
```

Use únicamente los resolvers que realmente haya decidido para el plano de
control.

## 2. Renderizar

```sh
/usr/local/libexec/fw0/render-pf
pfctl -nf /etc/pf.conf.candidate
```

`render-pf` también reconstruye `<vpn_endpoints>` desde perfiles VPN válidos.

## 3. Cargar con rollback autónomo

Mantenga consola local y la sesión SSH actual abiertas:

```sh
/usr/local/libexec/fw0/pf-safe-reload /etc/pf.conf.candidate
```

El comando devuelve un `TRANSACTION=<id>` y programa rollback automático. No
actualiza `lastgood` todavía.

## 4. Confirmar desde una NUEVA conexión SSH

Abra otra sesión desde Windows hacia la IP Tailscale de fw0. Solo desde esa
sesión nueva:

```sh
doas /usr/local/libexec/fw0/pf-safe-confirm <id>
```

La confirmación vuelve persistente PF (`pf_enable=YES`), guarda
`/etc/pf.conf.lastgood` y cancela lógicamente el rollback. Si la sesión nueva no
abre o no se confirma a tiempo, el worker restaura automáticamente la
configuración previa.

## 5. Gate

```sh
/usr/local/libexec/fw0/fw-verify 03
```

Además del PASS automático, vuelva a comprobar una nueva reconexión SSH.
