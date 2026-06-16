# Arranque rápido — 2 computadoras Ubuntu nativas

Escenario: dos laptops con Ubuntu nativo conectadas al mismo switch.
Nodo A = `10.0.0.10` (maestro) · Nodo B = `10.0.0.20` (esclavo/espejo).

> Sin VM, sin modo puente, sin WSL2. Esto reemplaza al Entregable 2 del README.

## Orden general
1. Red e IP estática en AMBOS (sección 1).
2. Desplegar el Nodo A (sección 2).
3. Desplegar el Nodo B (sección 3).
4. Configurar NPM, Pi-hole, Syncthing, UFW (README, Entregables 3.5–3.7 y 4).
5. Verificar (README, Entregable 5).

> Sugerencia: instala Docker y descarga las imágenes (`docker compose pull`)
> MIENTRAS tengas internet. Después desconecta y trabaja aislado.

## 1. Red e IP estática (en cada nodo)

> ¿Conectados por Wi-Fi (sin cable)? Salta a la sección **1-bis**. La
> configuración por Netplan de abajo es solo para conexión por cable.

```bash
# Ver el nombre de tu tarjeta de red
ip a

# Editar el archivo de red incluido y copiarlo a netplan
# (CAMBIA enp0s3 por tu interfaz dentro del archivo)
nano nodo-a/config/red/01-static.yaml      # en el Nodo A
sudo cp nodo-a/config/red/01-static.yaml /etc/netplan/01-static.yaml
sudo chmod 600 /etc/netplan/01-static.yaml
sudo netplan apply

ip a                  # confirma 10.0.0.10 (o .20 en el Nodo B)
```

En el Nodo B usa `nodo-b/config/red/01-static.yaml` (IP 10.0.0.20).
Comprueba el enlace entre ambos: desde el Nodo A → `ping -c3 10.0.0.20`.


## 1-bis. Red por Wi-Fi (sin cable)

Si ambas laptops están en la MISMA Wi-Fi, no toques Netplan. Dale a cada una
una IP corporativa 10.0.0.X como dirección secundaria sobre el Wi-Fi (conservas
internet y el esquema 10.0.0.0/24):

```bash
# Nodo A
bash nodo-a/scripts/ip-corporativa.sh 10.0.0.10
# Nodo B
bash nodo-b/scripts/ip-corporativa.sh 10.0.0.20
```

Comprueba que se ven entre sí:  `ping -c3 10.0.0.20` (desde A).

> Si el ping FALLA pero ambas tienen su 10.0.0.X, casi seguro el router/AP
> tiene "aislamiento de clientes" activado. Solución: usar un AP que controles
> (un hotspot de celular o un router propio) y desactivar esa opción, o conectar
> por cable a un switch.

## 2. Desplegar el Nodo A (maestro)

```bash
cd ~/red-espejo/nodo-a
chmod +x setup.sh scripts/*.sh
bash setup.sh
# Si instala Docker, cierra sesión, vuelve a entrar y re-ejecuta bash setup.sh
```

El script: instala Docker (si falta), libera el puerto 53, crea la red
`red_corp`, levanta todos los contenedores y crea las cuentas de correo.

## 3. Desplegar el Nodo B (esclavo) — con el Nodo A ya encendido

```bash
cd ~/red-espejo/nodo-b
chmod +x setup.sh scripts/*.sh
bash setup.sh
```

Además de lo anterior, el Nodo B verifica el ping al maestro y engancha la
réplica de MariaDB automáticamente.

## 4. Verificación mínima (en cada nodo)

```bash
docker compose ps      # todo en "running"

# Nodo A: la tabla de demo debe mostrar a Charlie y Emir
docker compose exec mariadb-master \
  mariadb -uroot -pRoot.Maestro.2026 -e "SELECT * FROM empresa_db.empleados;"

# Nodo B: la réplica debe ir bien
cd ~/red-espejo/nodo-b
docker compose exec mariadb-slave \
  mariadb -uroot -pRoot.Esclavo.2026 -e "SHOW SLAVE STATUS\G" | grep Running
```

Interfaces web (desde el propio nodo usa localhost; desde la red, la IP):
Portainer `:9443` · NPM `:81` · Pi-hole `:8053/admin` · Syncthing `:8384`.

## Prueba de la replicación en vivo
En el Nodo A inserta un registro y comprueba que aparece en el Nodo B:

```bash
# Nodo A
docker compose exec mariadb-master \
  mariadb -uroot -pRoot.Maestro.2026 -e \
  "INSERT INTO empresa_db.empleados (nombre,puesto) VALUES ('Dibri','Soporte');"

# Nodo B (debe aparecer Dibri)
docker compose exec mariadb-slave \
  mariadb -uroot -pRoot.Esclavo.2026 -e "SELECT * FROM empresa_db.empleados;"
```

## 6. Panel de bienvenida OptiComSoc (GUI)

Una ventana de escritorio que da la bienvenida y abre cada servicio con un clic.

```bash
cd ~/red-espejo/gui
./abrir-gui.sh        # instala python3-tk la primera vez y abre la ventana
```

Tiene un selector Nodo A / Nodo B: cambia el destino de los botones entre
`empresa.ComSoc` (10.0.0.10) y `empresa.Opticom` (10.0.0.20). Los servicios
con nombre (phpMyAdmin, Correo, VoIP) requieren tener configurados Pi-hole y
Nginx Proxy Manager; los demás (Portainer, Pi-hole, NPM, Syncthing) abren por IP.

## 7. Si las imágenes de Docker no descargan (Wi-Fi)

Bajar 7 imágenes a la vez por Wi-Fi puede provocar "TLS handshake timeout".
Solución: limitar descargas en paralelo y bajarlas una por una con reintento.

```bash
sudo mkdir -p /etc/docker
echo '{ "max-concurrent-downloads": 1 }' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker

cd ~/red-espejo/nodo-a   # (o nodo-b)
for img in mariadb:11.4 pihole/pihole:latest jc21/nginx-proxy-manager:latest \
           phpmyadmin:latest portainer/portainer-ce:latest \
           syncthing/syncthing:latest flaviostutz/freepbx; do
  until docker pull "$img"; do echo "...reintentando $img"; sleep 5; done
done
```

Luego `bash setup.sh` arranca al instante (las imágenes ya están en caché).
