# Preámbulo de acceso remoto e inventario

Este preámbulo se ejecuta desde teclado y pantalla locales después de instalar
FreeBSD. Su único objetivo es obtener administración remota segura antes de
construir el router.

## 1. Conexión temporal y actualización

Conecte únicamente la interfaz elegida provisionalmente como WAN al Huawei.
No conecte todavía clientes a LAN/AUX. Obtenga DHCP, compruebe hora y aplique
actualizaciones:

```sh
dhclient <WAN_IF>
freebsd-update fetch install
pkg update
pkg install tailscale
```

Registre si el Huawei entrega una dirección privada (modo router/NAT) o una
dirección pública (bridge). El ruleset admite ambos casos y nunca considera
RFC1918 en WAN como prueba suficiente de spoofing.

## 2. Revisión breve del hardware

```sh
mkdir -p /var/tmp/fw0-inventory
pciconf -lv > /var/tmp/fw0-inventory/pciconf.txt
ifconfig -a > /var/tmp/fw0-inventory/ifconfig.txt
dmesg > /var/tmp/fw0-inventory/dmesg.txt
camcontrol devlist > /var/tmp/fw0-inventory/storage.txt
sysctl hw.model hw.ncpu hw.physmem > /var/tmp/fw0-inventory/system.txt
```

Identifique cada puerto conectando un cable por vez y observando `status` y
MAC. No asigne roles usando solamente `em0`, `re0`, etc.

## 3. Tailscale y OpenSSH

```sh
sysrc tailscaled_enable=YES
service tailscaled start
tailscale up
tailscale ip -4
```

En Windows genere una clave si todavía no existe:

```powershell
ssh-keygen -t ed25519
```

Copie solamente `id_ed25519.pub` a un USB o péguela en un archivo de la mini
PC desde la consola. `tailscale up` muestra una URL de autenticación; ábrala
desde Windows. Luego ejecute el preparador indicando usuario y clave pública:

```sh
doas /usr/local/libexec/fw0/bootstrap-remote-access <usuario> /ruta/id_ed25519.pub
```

El script autoriza clave pública, fija OpenSSH a la IP IPv4 de Tailscale y
reinicia `sshd`. No habilita el servidor especial “Tailscale SSH”.

## 4. Prueba desde Windows

Instale/inicie Tailscale en Windows bajo el mismo tailnet y pruebe:

```powershell
tailscale status
ssh <usuario>@<IP_TAILSCALE_FW0>
```

Mantenga la consola local abierta. Confirme dos sesiones SSH nuevas antes de
cerrarla. Ejecute después:

```sh
doas /usr/local/libexec/fw0/fw-verify 01
```

No continúe si SSH responde por la dirección WAN o si Gate 01 falla.
