#!/usr/bin/env bash
# Despliegue automático del Nodo A (MAESTRO) en Ubuntu nativo.
# Ejecutar desde la carpeta nodo-a:  bash setup.sh
set -e
echo "==================== SETUP NODO A (MAESTRO) ===================="

# 1) Docker
if ! command -v docker >/dev/null 2>&1; then
  echo ">> Instalando Docker (necesitas internet en este paso)..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  echo ""
  echo "!! Docker instalado. CIERRA SESION y vuelve a entrar,"
  echo "!! luego ejecuta de nuevo:  bash setup.sh"
  exit 0
fi

# 2) Liberar el puerto 53 (systemd-resolved) para que Pi-hole pueda usarlo
if ss -lntu 2>/dev/null | grep -q ':53 '; then
  echo ">> Liberando el puerto 53 (systemd-resolved)..."
  sudo sed -i 's/^#\?DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
  sudo systemctl restart systemd-resolved
fi

# 3) Red Docker compartida
docker network inspect red_corp >/dev/null 2>&1 || docker network create red_corp

# 4) Levantar servicios
echo ">> Levantando núcleo..."
docker compose up -d
echo ">> Levantando correo (Mailu)..."
docker compose -f docker-compose.mail.yml up -d

echo ">> Esperando a que Mailu inicialice (30s)..."
sleep 30
echo ">> Creando cuentas de correo..."
bash scripts/crear-correos.sh || echo "(Reintenta crear-correos.sh en 1-2 min si falló)"

echo ""
echo "==================== NODO A LISTO ===================="
echo "Revisa el estado:   docker compose ps"
echo "Prueba la BD:       docker compose exec mariadb-master mariadb -uroot -pRoot.Maestro.2026 -e 'SELECT * FROM empresa_db.empleados;'"
docker compose ps
