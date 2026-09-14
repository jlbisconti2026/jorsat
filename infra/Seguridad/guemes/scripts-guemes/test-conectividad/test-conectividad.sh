#!/usr/bin/env bash
#
# test-guemes.sh - Script de diagnóstico de red y servicios para Güemes

echo "=================================================="
echo "      DIAGNÓSTICO DE RED Y SERVICIOS - GÜEMES     "
echo "=================================================="
echo ""

# 1. Estado del servicio Squid 6.12
echo "--> 1. Estado del servicio squid-6.12:"
systemctl status squid-6.12 --no-pager
echo ""

# 2. Resolución DNS
echo "--> 2. Prueba de resolución DNS:"
HOST_TEST="google.com"
if command -v dig &> /dev/null; then
    dig +short $HOST_TEST && echo "[OK] DNS resolviendo con dig" || echo "[FAIL] Error al resolver DNS"
elif command -v nslookup &> /dev/null; then
    nslookup $HOST_TEST | grep -A1 "Name:" && echo "[OK] DNS resolviendo con nslookup" || echo "[FAIL] Error al resolver DNS"
else
    getent hosts $HOST_TEST && echo "[OK] DNS resolviendo con getent" || echo "[FAIL] Error al resolver DNS"
fi
echo ""

# 3. Pruebas de Latencia (Ping)
echo "--> 3. Conectividad ICMP (Ping):"
echo -n "  - Interface LAN Gateway (10.10.10.5): "
ping -c 2 -W 2 10.10.10.5 &> /dev/null && echo "SUCCESS" || echo "FAILED"

echo -n "  - Internet IP (1.1.1.1): "
ping -c 2 -W 2 1.1.1.1 &> /dev/null && echo "SUCCESS" || echo "FAILED"

echo -n "  - Dominio Externo ($HOST_TEST): "
ping -c 2 -W 2 $HOST_TEST &> /dev/null && echo "SUCCESS" || echo "FAILED"
echo ""

# 4. Verificación de Puertos Locales y Squid
echo "--> 4. Comprobación de sockets y puertos:"
if command -v ss &> /dev/null; then
    echo "  - Puertos en escucha relevantes:"
    ss -tulpn | grep -E ':(53|80|443|4555|3128)' || echo "  [!] No se detectaron sockets activos en los puertos estándar/4555."
fi
echo ""

# 5. Test HTTP básico vía Proxy local (Puerto 4555)
echo "--> 5. Test de respuesta HTTP vía Proxy local (10.10.10.5:4555):"
if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --proxy http://10.10.10.5:4555 http://www.google.com --connect-timeout 3)
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 301 ] || [ "$HTTP_CODE" -eq 302 ]; then
        echo "[OK] Proxy respondiendo correctamente en puerto 4555 (HTTP $HTTP_CODE)"
    else
        echo "[WARN/FAIL] Respuesta inesperada del proxy: HTTP $HTTP_CODE"
    fi
else
    echo "[!] 'curl' no está instalado para probar el proxy."
fi

echo ""
echo "=================================================="
echo "             DIAGNÓSTICO FINALIZADO               "
echo "=================================================="