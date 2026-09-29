# Notas de implementación y límites de validación

Esta revisión implementa los hallazgos de la auditoría en el núcleo de fw0.

## Validado en este paquete

- sintaxis POSIX `sh -n` de scripts y rc.d;
- parser de perfiles `.meta` como datos (incluye prueba de inyección);
- presencia de invariantes/labels críticos;
- uso de `pfctl -M` para purga de estados;
- sustitución completa de marcadores de la plantilla PF;
- coherencia documental básica y archivos requeridos.

## Debe validarse en el FreeBSD objetivo

Este entorno de construcción no es FreeBSD, por lo que antes de producción se
debe ejecutar en la mini PC:

```sh
pfctl -nf /etc/pf.conf.candidate
/usr/local/libexec/fw0/fw-verify 00
/usr/local/libexec/fw0/fw-verify 01
/usr/local/libexec/fw0/fw-verify 02
/usr/local/libexec/fw0/fw-verify 03
/usr/local/libexec/fw0/fw-verify 04
```

Las pruebas K4-A/B/C/D/E requieren consola local y observación de tráfico real.
No deben sustituirse por una simulación de este repositorio.

## No implementado todavía

Gates 05–12 continúan deliberadamente `INCOMPLETE`: DHCP/DNS de datos,
management avanzado, XMPP rescue, healthd, matriz completa de boot/fault,
backup/DR y soak de 72 horas.
