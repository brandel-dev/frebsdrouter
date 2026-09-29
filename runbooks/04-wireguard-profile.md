# Gate 04 — perfiles WireGuard y estado VPN

Cada perfil consta de dos archivos `root:wheel 0600`:

- `<nombre>.conf`: formato de `wg setconf`, con secretos.
- `<nombre>.meta`: **datos estrictos**, no shell; solo `WG_ADDRESS`,
  `WG_ENDPOINT_IP` y `WG_ENDPOINT_PORT`.

`.meta` nunca se ejecuta con `source`, `.` ni `eval`.

El endpoint de `.conf` debe coincidir exactamente con `.meta`. `AllowedIPs`
debe incluir `0.0.0.0/0`. No use `Address`, `DNS`, `MTU` ni `Table` dentro del
`.conf`.

```sh
chown root:wheel /usr/local/etc/fw0/vpn/profiles/<nombre>.{conf,meta}
chmod 0600 /usr/local/etc/fw0/vpn/profiles/<nombre>.{conf,meta}
/usr/local/libexec/fw0/rebuild-vpn-endpoints
/usr/local/libexec/fw0/vpnctl switch <nombre>
```

Secuencia de `vpnctl`:

1. retira la default de FIB1;
2. purga estados con `pfctl -M`;
3. destruye `wg0` anterior;
4. crea `wg0` con `fib=1` y `tunnelfib=0`;
5. añade **solo una ruta host** hacia `EGRESS_PROBE_IP`;
6. exige handshake y egress real;
7. elimina la ruta host;
8. recién entonces instala `default -> wg0` en FIB1;
9. repite la prueba de egress y marca `HEALTHY`.

Si el candidato falla, intenta `last-good`. Si también falla, entra en
`QUARANTINE`, destruye wg0 y deja FIB1 sin default.

Después ejecute `runbooks/04-killswitch-test.md`.
