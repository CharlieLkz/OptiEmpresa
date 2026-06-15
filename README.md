# Red Espejo Corporativa — Interconexión de Redes 2

Infraestructura de **Alta Disponibilidad** 100 % aislada de internet, sobre dos
nodos, con DNS, proxy inverso, base de datos replicada, VoIP, correo y
sincronización de archivos. Todo en Docker y administrable por interfaz web.

| | Nodo A (Principal) | Nodo B (Espejo) |
|---|---|---|
| SO | Ubuntu nativo | VM Ubuntu sobre Windows |
| IP fija | `10.0.0.10` | `10.0.0.20` |
| Dominio | `empresa.ComSoc` | `empresa.Opticom` |
| MariaDB | **Maestro** (lectura/escritura) | **Esclavo** (solo lectura) |

> **Nota de terminología para el profesor:** `10.0.0.0/24` usa un bloque de
> direcciones privadas del **rango Clase A** (`10.0.0.0/8`, RFC 1918) pero con
> **máscara /24** (254 hosts útiles). Es correcto decir "direccionamiento
> privado Clase A subneteado a /24". Así suena preciso y defendible.

---

## Mapa de puertos (qué vive en cada uno)

| Servicio | Puerto host | Acceso |
|---|---|---|
| Portainer | `9443/tcp` | `https://10.0.0.10:9443` |
| Pi-hole (DNS) | `53/tcp+udp` | resolución de nombres |
| Pi-hole (UI) | `8053/tcp` | `http://10.0.0.10:8053/admin` |
| Nginx Proxy Manager (web) | `80`, `443` | subdominios sin puerto |
| Nginx Proxy Manager (panel) | `81/tcp` | `http://10.0.0.10:81` |
| MariaDB | `3306/tcp` | replicación A→B |
| phpMyAdmin / FreePBX / Pi-hole | — | vía NPM (por nombre) |
| Correo SMTP/IMAP/POP | `25,465,587,110,995,143,993,4190` | clientes de correo |
| VoIP SIP | `5060/udp`, `5160/udp` | softphones |
| VoIP RTP (audio) | `18000-18100/udp` | audio de llamadas |
| Syncthing | `8384/tcp`, `22000`, `21027/udp` | sincronización |

**Arquitectura clave:** todos los contenedores comparten la red Docker
externa `red_corp`. Así **Nginx Proxy Manager alcanza a cada servicio por su
nombre de contenedor** (ej. `phpmyadmin`, `freepbx`, `mailu-front`) y no hace
falta publicar los puertos web 80/443 de cada uno → cero conflictos de puertos
y URLs limpias (`db.empresa.ComSoc` en vez de `10.0.0.10:8080`).

---

# ENTREGABLE 1 — GitHub desde cero

## 1.1 En el Nodo A (Ubuntu nativo): inicializar y subir

```bash
# Instalar git si no está
sudo apt update && sudo apt install -y git

# Identidad (una sola vez)
git config --global user.name  "Equipo ComSoc"
git config --global user.email "equipo@empresa.comsoc"

# Entrar a la carpeta del proyecto
cd ~/red-espejo

# Inicializar el repositorio
git init -b main

# El .gitignore ya viene incluido (ignora datos en runtime, versiona configs)
git add .
git commit -m "Infraestructura red espejo: Nodo A y Nodo B"
```

Crea un repositorio **vacío** en GitHub (sin README) llamado `red-espejo` y
conéctalo. Usa un **Personal Access Token** como contraseña (GitHub ya no
acepta contraseña normal):

```bash
git remote add origin https://github.com/TU_USUARIO/red-espejo.git
git push -u origin main
# Usuario: TU_USUARIO   |   Contraseña: <pega tu token de github>
```

> Para no escribir el token cada vez: `git config --global credential.helper store`
> (lo guarda tras el primer push). En un equipo, mejor usar SSH keys.

## 1.2 En el Nodo B (dentro de la VM): clonar y replicar

```bash
sudo apt update && sudo apt install -y git
cd ~
git clone https://github.com/TU_USUARIO/red-espejo.git
cd red-espejo
```

Para traer cambios posteriores del Nodo A:

```bash
git pull origin main
```

## 1.3 Flujo de trabajo diario

```bash
# En el Nodo A, tras editar algo:
git add . && git commit -m "Ajuste X" && git push

# En el Nodo B, para sincronizar la config:
git pull
docker compose up -d   # aplica los cambios
```

> ⚠️ El `.gitignore` deja fuera los **datos** (correos, BD, grabaciones). Esos
> se replican por **MariaDB** (la BD) y **Syncthing** (correo y audio), NO por
> git. Git solo versiona la **configuración** de la infraestructura.

---

# ENTREGABLE 2 — VM en Windows (red en Modo Puente)

El objetivo: que la VM tome una IP **real** de `10.0.0.0/24` y hable de tú a tú
con el Nodo A físico. Eso solo se logra con **adaptador puente (bridged)**, no
con NAT.

## 2.1 VirtualBox — Modo Puente

1. Apaga la VM. **Configuración → Red → Adaptador 1**.
2. **Conectado a:** `Adaptador puente`.
3. **Nombre:** elige la tarjeta física que está conectada al switch
   (la Ethernet del cable, no "Wi-Fi" si usas cable).
4. Despliega **Avanzado → Modo promiscuo:** `Permitir todo`.
5. Aceptar y arrancar la VM.

## 2.2 VMware Workstation/Player — Modo Puente

1. VM apagada → **Settings → Network Adapter**.
2. Marca **Bridged: Connected directly to the physical network**.
3. Marca **Replicate physical network connection state**.
4. Si tienes varias tarjetas: **Edit → Virtual Network Editor → VMnet0**,
   y fija "Bridged to:" a la tarjeta Ethernet correcta.

## 2.3 IP estática dentro de la VM Ubuntu (Netplan)

Dentro de la VM:

```bash
# Ver el nombre de la interfaz (suele ser enp0s3 o ens33)
ip a

sudo nano /etc/netplan/01-static.yaml
```

Contenido (ajusta el nombre de interfaz al tuyo):

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses: [10.0.0.20/24]
      nameservers:
        addresses: [10.0.0.20, 10.0.0.10]   # su propio Pi-hole y el del Nodo A
      # Sin "gateway/routes": red aislada, sin salida a internet.
```

```bash
sudo netplan apply
ip a                 # confirma 10.0.0.20
ping -c3 10.0.0.10   # debe responder el Nodo A
```

Haz lo mismo en el **Nodo A físico** con `addresses: [10.0.0.10/24]` y
`nameservers: [10.0.0.10, 10.0.0.20]`.

## 2.4 Si el modo puente falla → comprobaciones rápidas

- ¿El Nodo A te hace `ping`? Si no, revisa que **ambos** estén en el mismo
  switch/módem y que UFW del Nodo A permita ICMP (`sudo ufw allow proto icmp`).
- En VirtualBox, el **Modo promiscuo "Permitir todo"** es la causa #1 cuando
  el puente "ve" la red pero no recibe tráfico.
- Wi-Fi + bridged a veces bloquea direcciones por el AP; usa **cable**.

## 2.5 Plan de contingencia: WSL2 (si la VM no logra bridged)

WSL2 corre detrás de NAT y **no** toma IP de la LAN por defecto. Hay que
**reenviar puertos** desde Windows hacia WSL2 y abrir el firewall de Windows.

```powershell
# --- Ejecutar en PowerShell de Windows como ADMINISTRADOR ---

# 1) IP interna de WSL2
wsl hostname -I        # ejemplo: 172.20.0.2

# 2) Reenviar los puertos clave de la LAN (10.0.0.20) hacia WSL2
$wsl = (wsl hostname -I).Trim().Split(" ")[0]
$puertos = @(53,80,443,81,3306,5060,5160,8053,8384,9443,25,465,587,143,993,22000)
foreach ($p in $puertos) {
  netsh interface portproxy add v4tov4 `
    listenaddress=10.0.0.20 listenport=$p connectaddress=$wsl connectport=$p
}

# 3) Abrir el firewall de Windows para esos puertos
New-NetFirewallRule -DisplayName "RedEspejo-WSL2" -Direction Inbound `
  -Action Allow -Protocol TCP -LocalPort 53,80,443,81,3306,8053,8384,9443,25,465,587,143,993,22000

# Ver reglas activas:
netsh interface portproxy show all
```

> En Windows, asigna a la tarjeta física la IP `10.0.0.20/24` para que la LAN
> "vea" ese nodo, y WSL2 atiende detrás vía portproxy. Limitación honesta:
> los **rangos UDP grandes (RTP 18000-18100)** son tediosos por portproxy;
> por eso el **bridged real es muy preferible para VoIP**. Si vas a WSL2,
> considera dejar la centralita VoIP solo en el Nodo A.

---

# ENTREGABLE 3 — Docker Compose

Los archivos completos están en el repo:

- `nodo-a/docker-compose.yml` — núcleo del Maestro
- `nodo-a/docker-compose.mail.yml` — correo Mailu (A)
- `nodo-b/docker-compose.yml` — núcleo del Esclavo
- `nodo-b/docker-compose.mail.yml` — correo Mailu (B)

## 3.1 Requisitos previos (en AMBOS nodos)

```bash
# Docker + Compose plugin
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER   # cierra y reabre sesión

# Red compartida externa (UNA sola vez por nodo)
docker network create red_corp
```

## 3.2 Orden de arranque — NODO A

```bash
cd ~/red-espejo/nodo-a

# 1) Núcleo (DNS, proxy, BD maestro, phpMyAdmin, VoIP, Syncthing, Portainer)
docker compose up -d

# 2) Correo (stack Mailu)
docker compose -f docker-compose.mail.yml up -d

# 3) Crear las cuentas de correo (5 usuarios x 2 dominios)
bash scripts/crear-correos.sh

docker compose ps     # todo "running/healthy"
```

## 3.3 Orden de arranque — NODO B

```bash
cd ~/red-espejo/nodo-b
docker compose up -d
docker compose -f docker-compose.mail.yml up -d
bash scripts/crear-correos.sh

# Enganchar la réplica al Maestro (Nodo A debe estar arriba)
bash scripts/configurar-replica.sh
# Debe mostrar: Slave_IO_Running: Yes / Slave_SQL_Running: Yes
```

## 3.4 Variables de entorno de la replicación MariaDB

| Variable | Nodo A (`.env`) | Nodo B (`.env`) |
|---|---|---|
| `server-id` | 1 (en `master.cnf`) | 2 (en `slave.cnf`) |
| Usuario réplica | `replicador` (creado por `init-master.sql`) | usa `REPL_USER` |
| Password réplica | `Replica.Pass.2026` | `REPL_PASSWORD` |
| Maestro | — | `MASTER_HOST=10.0.0.10` |
| GTID | `MASTER_USE_GTID=slave_pos` (auto-engancha sin file/pos) | |

El maestro emite **binlog en formato ROW** y el esclavo está en
**`read-only=1`**: intentar escribir en el Nodo B dará error (justo lo que
quieres demostrar: "el espejo es solo lectura").

## 3.5 Configurar Nginx Proxy Manager (subdominios sin puerto)

1. Entra a `http://10.0.0.10:81`
   (login inicial: `admin@example.com` / `changeme` → te obliga a cambiarlo).
2. **Hosts → Proxy Hosts → Add Proxy Host** y crea uno por servicio:

| Domain Names | Forward Hostname | Forward Port |
|---|---|---|
| `db.empresa.ComSoc` | `phpmyadmin` | `80` |
| `pbx.empresa.ComSoc` | `freepbx` | `80` |
| `dns.empresa.ComSoc` | `pihole` | `80` |
| `correo.empresa.ComSoc` | `mailu-front` | `80` |
| `panel.empresa.ComSoc` | `portainer` | `9443` (esquema **https**) |

> "Forward Hostname" = **nombre del contenedor** (funciona porque comparten
> `red_corp`). Marca *Block Common Exploits* y guarda. Repite en el Nodo B con
> los nombres `.Opticom` apuntando a sus propios contenedores.

## 3.6 Configurar Pi-hole (registros DNS locales)

Entra a `http://10.0.0.10:8053/admin` → **Settings → Local DNS → DNS Records**
y carga los registros del archivo `scripts/registros-pihole.txt` en **ambos**
Pi-hole. Luego apunta el DNS de cada laptop/cliente a `10.0.0.10` (primario) y
`10.0.0.20` (secundario).

## 3.7 Configurar Syncthing (correo + audios bidireccional)

1. UI Nodo A: `http://10.0.0.10:8384` — UI Nodo B: `http://10.0.0.20:8384`.
2. En A: **Actions → Show ID**, copia el ID. En B: **Add Remote Device**, pega
   el ID de A (y viceversa). Acepta la solicitud en ambos.
3. **Add Folder** en A apuntando a `/sync/mail` (label `correo`) y otro a
   `/sync/voip` (label `audios`). Compártelos con el dispositivo B.
4. En B acepta las carpetas y fija la ruta a `/sync/mail` y `/sync/voip`.
5. Verás "Up to Date" cuando sincronicen. Es **bidireccional** por defecto.

> ⚠️ Syncthing sincroniza correo y grabaciones VoIP. **NO** sincronices la
> carpeta de datos vivos de MariaDB: eso lo hace la replicación nativa de la BD.
> Mezclar ambos corrompe la base.

---

# ENTREGABLE 4 — Firewall UFW

Los comandos están en `scripts/ufw-nodo-a.sh` y `scripts/ufw-nodo-b.sh`.
Política: **denegar todo lo entrante**, permitir solo lo necesario y **limitado
a la subred** `10.0.0.0/24`.

```bash
# Nodo A
cd ~/red-espejo/nodo-a && bash scripts/ufw-nodo-a.sh

# Nodo B
cd ~/red-espejo/nodo-b && bash scripts/ufw-nodo-b.sh
```

Resumen de puertos abiertos (con justificación):

| Puerto | Proto | Servicio | Alcance |
|---|---|---|---|
| 22 | tcp | SSH admin | subred |
| 53 | tcp+udp | DNS Pi-hole | subred |
| 8053 | tcp | UI Pi-hole | subred |
| 80, 443 | tcp | Nginx Proxy Manager | subred |
| 81 | tcp | Panel NPM | subred |
| 9443 | tcp | Portainer | subred |
| **3306** | tcp | **MariaDB replicación** | **solo el otro nodo** |
| 25,465,587 | tcp | SMTP correo | subred |
| 110,995,143,993 | tcp | POP/IMAP correo | subred |
| 4190 | tcp | Sieve | subred |
| 5060, 5160 | udp | SIP VoIP | subred |
| 18000-18100 | udp | RTP audio | subred |
| 8384 | tcp | UI Syncthing | subred |
| 22000 | tcp+udp | Sync datos | subred |
| 21027 | udp | Descubrimiento | subred |

> El 3306 se restringe con `ufw allow from 10.0.0.20 ...` (en A) y
> `from 10.0.0.10 ...` (en B): solo el nodo pareja puede tocar la BD.

```bash
# Verificar y, si algo falla, ver qué bloquea:
sudo ufw status verbose
sudo tail -f /var/log/ufw.log
```

---

# ENTREGABLE 5 — Plan de demostración para el profesor

Guion de ~10 minutos. Ten los dos navegadores y dos softphones listos.

### Paso 0 — Panorama (30 s)
Abre **Portainer** (`panel.empresa.ComSoc`) en cada nodo y muestra todos los
contenedores en verde: "toda la infraestructura corre en Docker, gestionada
visualmente y sin tocar internet".

### Paso 1 — DNS local funcionando
En una terminal: `nslookup correo.empresa.ComSoc` → responde `10.0.0.10`.
"El Pi-hole resuelve nuestros dominios corporativos ficticios sin internet."
Abre `dns.empresa.ComSoc` y enseña los **Local DNS Records**.

### Paso 2 — Proxy inverso (URLs limpias)
Navega a `db.empresa.ComSoc`, `pbx.empresa.ComSoc`, `correo.empresa.ComSoc`.
"Nginx Proxy Manager enruta cada subdominio a su contenedor; nadie escribe
puertos en la URL."

### Paso 3 — Replicación de base de datos EN VIVO
- Abre **phpMyAdmin del Nodo A** (`db.empresa.ComSoc`) y el del **Nodo B**
  (`db.empresa.Opticom`) lado a lado.
- En el Nodo A, base `empresa_db → empleados`, inserta un registro:
  `INSERT INTO empleados (nombre, puesto) VALUES ('Dibri','Soporte');`
- Refresca el Nodo B → el registro **ya está ahí**. "Replicación maestro-esclavo
  por GTID en tiempo real."
- Intenta insertar EN el Nodo B → error `--read-only`. "El espejo es de solo
  lectura, protegido contra escrituras."

### Paso 4 — Llamada VoIP por número y por nombre
- Softphone 1 registrado como ext. **1001** (Charlie), softphone 2 como **1002**
  (Emir).
- Marca `1002` desde 1001 → timbra y hay audio.
- Cuelga y marca `emir` (texto) → el dialplan lo enruta a 1002. "La centralita
  acepta número y alias."

### Paso 5 — Correo interno entre dominios
- Entra al webmail `correo.empresa.ComSoc` como `charlie@empresa.comsoc`.
- Envía un correo a `luis@empresa.opticom`.
- Entra al webmail del Nodo B como Luis → el correo llegó. "Correo corporativo
  en ambos dominios, sin internet."

### Paso 6 — Sincronización Syncthing
Muestra Syncthing en ambos nodos en estado **Up to Date**. "Los buzones y los
audios de las llamadas se replican en segundo plano entre los dos nodos."

### Paso 7 — Alta Disponibilidad (el momento estelar)
- **Desconecta virtualmente el Nodo A** (apaga sus contenedores o el cable):
  `docker compose stop` en el Nodo A.
- En un cliente cuyo DNS secundario es `10.0.0.20`, vuelve a abrir
  `empresa.ComSoc`: el **Pi-hole del Nodo B** responde (porque cargaste también
  los registros `.ComSoc → 10.0.0.20` en su Pi-hole espejo).
- Registra el softphone contra `10.0.0.20` y haz otra llamada.
- "Aunque cae el nodo principal, el espejo mantiene DNS, base de datos (lectura),
  correo y telefonía. Eso es Alta Disponibilidad."

### Cierre
"Resumen: dos nodos, replicación de datos nativa, DNS y telefonía redundantes,
correo multidominio y sincronización continua, todo aislado de internet,
versionado en GitHub y desplegable con `docker compose up`."

---

## Apéndice — Solución de problemas rápida

| Síntoma | Causa probable | Arreglo |
|---|---|---|
| `port is already allocated` | otro contenedor usa 80/443 | solo NPM publica 80/443; el resto va por `red_corp` |
| Réplica `Slave_IO_Running: No` | UFW bloquea 3306 o falta usuario | abre 3306 al nodo pareja; revisa `init-master.sql` |
| Mailu no levanta | `SECRET_KEY` ≠ 16 caracteres | corrige `mailu.env` |
| VoIP timbra pero sin audio | RTP bloqueado | abre `18000-18100/udp` en UFW |
| NPM "502 Bad Gateway" | nombre/puerto de contenedor mal | usa el nombre exacto del contenedor y su puerto interno |
| Nodo B no resuelve nombres | DNS mal en netplan | `nameservers: [10.0.0.20, 10.0.0.10]` |

## Credenciales por defecto (cámbialas en producción)

| Servicio | Usuario | Password |
|---|---|---|
| Pi-hole | — | `Admin.Pihole.2026` |
| Portainer | (creas al entrar) | (creas al entrar) |
| NPM | `admin@example.com` | `changeme` (cambiar al 1er login) |
| MariaDB root (A) | `root` | `Root.Maestro.2026` |
| MariaDB root (B) | `root` | `Root.Esclavo.2026` |
| Correo (webmail) | `usuario@dominio` | `Correo.2026` |
| Correo admin | `admin@empresa.comsoc` | `Admin.2026` |
