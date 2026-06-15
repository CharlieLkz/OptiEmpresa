#!/usr/bin/env bash
# Despliegue automático del Nodo B (ESCLAVO) en Ubuntu nativo.
# Ejecutar desde la carpeta nodo-b:  bash setup.sh
# IMPORTANTE: el Nodo A debe estar ENCENDIDO y accesible (ping 10.0.0.10).
set -e
echo "==================== SETUP NODO B (ESCLAVO) ===================="

if ! command -v docker >/dev/null 2>&1; then
  echo ">> Instalando Docker (necesitas internet en este paso)..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  echo ""
  echo "!! Docker instalado. CIERRA SESION y vuelve a entrar,"
  echo "!! luego ejecuta de nuevo:  bash setup.sh"
  exit 0
fi

if ss -lntu 2>/dev/null | grep -q ':53 '; then
  echo ">> Liberando el puerto 53 (systemd-resolved)..."
  sudo sed -i 's/^#\?DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
  sudo systemctl restart systemd-resolved
fi

docker network inspect red_corp >/dev/null 2>&1 || docker network create red_corp

echo ">> Verificando conectividad con el Nodo A (10.0.0.10)..."
if ! ping -c2 10.0.0.10 >/dev/null 2>&1; then
  echo "!! NO hay ping al Nodo A. Revisa red/IP antes de continuar."
  echo "!! (Los contenedores se levantarán, pero la réplica fallará.)"
fi

echo ">> Levantando núcleo..."
docker compose up -d
echo ">> Levantando correo (Mailu)..."
docker compose -f docker-compose.mail.yml up -d
sleep 30
bash scripts/crear-correos.sh || echo "(Reintenta crear-correos.sh en 1-2 min si falló)"

echo ">> Enganchando la réplica de MariaDB al maestro..."
sleep 5
bash scripts/configurar-replica.sh || echo "(Reintenta configurar-replica.sh cuando el Nodo A esté listo)"

echo ""
echo "==================== NODO B LISTO ===================="
docker compose ps
