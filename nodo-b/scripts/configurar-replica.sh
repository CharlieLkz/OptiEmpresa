#!/usr/bin/env bash
# Engancha el esclavo (Nodo B) al maestro (Nodo A) usando GTID.
# Ejecutar en el NODO B una vez que AMBAS bases estén arriba
# y exista conectividad (ping 10.0.0.10 OK, puerto 3306 abierto).
set -e
source ../.env

echo ">> Verificando conectividad con el maestro ${MASTER_HOST}:3306 ..."
docker compose exec -T mariadb-slave bash -c \
  "mariadb -uroot -p${DB_ROOT_PASSWORD} -e 'SELECT 1;'" >/dev/null

echo ">> Configurando CHANGE MASTER (GTID)..."
docker compose exec -T mariadb-slave \
  mariadb -uroot -p"${DB_ROOT_PASSWORD}" -e "
    STOP SLAVE;
    RESET SLAVE;
    CHANGE MASTER TO
      MASTER_HOST='${MASTER_HOST}',
      MASTER_PORT=3306,
      MASTER_USER='${REPL_USER}',
      MASTER_PASSWORD='${REPL_PASSWORD}',
      MASTER_USE_GTID=slave_pos;
    START SLAVE;
  "

sleep 3
echo ">> Estado de la réplica (busca Slave_IO_Running: Yes / Slave_SQL_Running: Yes):"
docker compose exec -T mariadb-slave \
  mariadb -uroot -p"${DB_ROOT_PASSWORD}" -e "SHOW SLAVE STATUS\G" \
  | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|Last_Error"
