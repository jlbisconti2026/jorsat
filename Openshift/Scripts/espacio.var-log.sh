#!/bin/bash
# Script: top_log_dirs.sh
# Analiza los directorios en /var/log y muestra los que más espacio consumen

echo "Analizando uso de espacio en /var/log..."
echo "-----------------------------------------"

# Verifica que exista el directorio
if [ ! -d /var/log ]; then
    echo "Error: /var/log no existe en este sistema."
    exit 1
fi

# Usa du para calcular tamaños, los ordena y muestra los 10 más grandes
du -h --max-depth=1 /var/log 2>/dev/null | sort -hr | head -n 10

echo "-----------------------------------------"
echo "Los resultados están ordenados de mayor a menor uso."
