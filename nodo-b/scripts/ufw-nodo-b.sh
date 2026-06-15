#!/usr/bin/env bash
# Firewall estricto Nodo B (10.0.0.20). Solo abre lo necesario,
# y limitado a la subred local 10.0.0.0/24.
set -e
SUBNET="10.0.0.0/24"

sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Administración
sudo ufw allow from $SUBNET to any port 22   proto tcp   comment 'SSH'
sudo ufw allow from $SUBNET to any port 81    proto tcp   comment 'Panel NPM'
sudo ufw allow from $SUBNET to any port 9443  proto tcp   comment 'Portainer'

# DNS (Pi-hole)
sudo ufw allow from $SUBNET to any port 53    proto tcp   comment 'DNS'
sudo ufw allow from $SUBNET to any port 53    proto udp   comment 'DNS'
sudo ufw allow from $SUBNET to any port 8053  proto tcp   comment 'Pi-hole UI'

# Proxy inverso (web de todos los servicios)
sudo ufw allow from $SUBNET to any port 80    proto tcp   comment 'HTTP'
sudo ufw allow from $SUBNET to any port 443   proto tcp   comment 'HTTPS'

# Base de datos (replicación: solo desde el Nodo B)
sudo ufw allow from 10.0.0.10 to any port 3306 proto tcp  comment 'MariaDB replica'

# Correo (Mailu)
for P in 25 465 587 110 995 143 993 4190; do
  sudo ufw allow from $SUBNET to any port $P proto tcp comment "Mail $P"
done

# VoIP (FreePBX)
sudo ufw allow from $SUBNET to any port 5060 proto udp comment 'SIP pjsip'
sudo ufw allow from $SUBNET to any port 5160 proto udp comment 'SIP chan_sip'
sudo ufw allow from $SUBNET to any port 18000:18100 proto udp comment 'RTP audio'

# Syncthing
sudo ufw allow from $SUBNET to any port 8384  proto tcp comment 'Syncthing UI'
sudo ufw allow from $SUBNET to any port 22000 proto tcp comment 'Syncthing sync'
sudo ufw allow from $SUBNET to any port 22000 proto udp comment 'Syncthing QUIC'
sudo ufw allow from $SUBNET to any port 21027 proto udp comment 'Syncthing discovery'

sudo ufw --force enable
sudo ufw status verbose
