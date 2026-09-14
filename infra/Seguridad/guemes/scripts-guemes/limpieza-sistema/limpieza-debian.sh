#!/usr/bin/env bash
#
# Mantenimiento y limpieza de paquetes/logs

echo "=== Inicio de limpieza de sistema: $(date) ==="

# 1. Eliminar paquetes que ya no son necesarios y configuraciones residuales
echo "--> Limpiando paquetes huérfanos y dependencias..."
apt-get autoremove --purge -y
apt-get autoclean -y

# 2. Rotación y reducción de logs del systemd journal (restringe a 500MB max)
echo "--> Limpiando logs antiguos de systemd journal..."
journalctl --vacuum-size=500M --vacuum-time=14d

# 3. Limpieza de archivos temporales en /tmp y /var/tmp mayores a 7 días
echo "--> Limpiando archivos temporales antiguos..."
find /tmp /var/tmp -type f -atime +7 -delete

echo "=== Limpieza finalizada ==="