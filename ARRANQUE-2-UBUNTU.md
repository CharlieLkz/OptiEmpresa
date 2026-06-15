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
