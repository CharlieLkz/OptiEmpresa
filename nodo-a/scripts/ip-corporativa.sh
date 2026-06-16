#!/usr/bin/env bash
# Asigna una IP "corporativa" 10.0.0.X/24 como dirección SECUNDARIA sobre el
# Wi-Fi, manteniendo el internet de la Wi-Fi. Persistente (NetworkManager dispatcher).
# Uso:  bash ip-corporativa.sh 10.0.0.10      (Nodo A)
#       bash ip-corporativa.sh 10.0.0.20      (Nodo B)
set -e
CORP_IP="${1:?Uso: bash ip-corporativa.sh 10.0.0.10}"

WIFI=$(ip -br link | awk '$1 ~ /^wl/ {print $1; exit}')
[ -z "$WIFI" ] && { echo "No encontré interfaz Wi-Fi (wl*)."; exit 1; }
echo "Wi-Fi detectada: $WIFI  |  IP corporativa: ${CORP_IP}/24"

# 1) Dispatcher: reaplica la IP en cada (re)conexión y tras reiniciar
sudo tee /etc/NetworkManager/dispatcher.d/50-corp-ip.sh >/dev/null <<DISP
#!/bin/sh
case "\$1" in
  wl*) [ "\$2" = "up" ] && ip addr add ${CORP_IP}/24 dev "\$1" 2>/dev/null ;;
esac
exit 0
DISP
sudo chmod 755 /etc/NetworkManager/dispatcher.d/50-corp-ip.sh

# 2) Aplicarla ahora mismo (sin esperar reconexión)
sudo ip addr add ${CORP_IP}/24 dev "$WIFI" 2>/dev/null || true

echo ">> Direcciones actuales en $WIFI:"
ip -br addr show "$WIFI"
