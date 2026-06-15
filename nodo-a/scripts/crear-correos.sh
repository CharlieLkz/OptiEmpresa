#!/usr/bin/env bash
# Crea las cuentas de correo en AMBOS dominios dentro de Mailu.
# Ejecutar DESPUÉS de levantar docker-compose.mail.yml
set -e
MC="docker compose -f docker-compose.mail.yml exec -T admin flask mailu"
PASS="Correo.2026"

# 1) Registrar ambos dominios
$MC domain empresa.comsoc  || true
$MC domain empresa.opticom || true

# 2) Crear usuarios en cada dominio
for USER in charlie emir dibri diego luis; do
  for DOM in empresa.comsoc empresa.opticom; do
    echo ">> Creando ${USER}@${DOM}"
    $MC user "$USER" "$DOM" "$PASS" || true
  done
done

# 3) Un administrador para entrar al panel /admin
$MC admin admin empresa.comsoc "Admin.2026" || true
echo "LISTO. Panel: http://correo.empresa.ComSoc/admin  (admin@empresa.comsoc / Admin.2026)"
echo "Webmail: http://correo.empresa.ComSoc/  (usuario@dominio / ${PASS})"
