# Configura las variables con el nombre de tu clúster y dominio
CLUSTER_NAME="labokdipi"
BASE_DOMAIN="claro.amx"

API_FQDN="api.${CLUSTER_NAME}.${BASE_DOMAIN}"
API_INT_FQDN="api-int.${CLUSTER_NAME}.${BASE_DOMAIN}"

# Dominios de aplicaciones con comodín (Wildcard)
APPS_WILDCARD_1="apps.labokdipi.claro.amx"
APPS_WILDCARD_2="apps-ssl.labokdipi.claro.amx"

# Definición de pruebas TCP (FQDN:PUERTO)
TARGETS=(
  "${API_FQDN}:6443"
  "${API_INT_FQDN}:6443"
  "${API_INT_FQDN}:22623"
)

echo "=== 1. Probando resolución DNS (API y Comodines de Apps) ==="
# Lista de dominios a verificar en DNS
DNS_TARGETS=(
  "${API_FQDN}"
  "${API_INT_FQDN}"
  "${APPS_WILDCARD_1}"
  "${APPS_WILDCARD_2}"
)

for domain in "${DNS_TARGETS[@]}"; do
  # Si el dominio es un comodín (*), probamos resolviendo un subdominio de prueba para evaluar el wildcard
  query_target="${domain}"
  if [[ "${domain}" == *"*"* ]] || [[ "${domain}" == "apps"* ]]; then
    # Genera una prueba del tipo test.apps.osepaihub.claro.amx
    clean_domain=$(echo "${domain}" | tr -d '*')
    query_target="test-validacion.${clean_domain}"
  fi

  ip=$(dig +short "${query_target}" | tail -n1)
  if [ -n "$ip" ]; then
    echo -e "[\e[32mOK\e[0m] ${domain} (probado con ${query_target}) resuelve a la IP: ${ip}"
  else
    echo -e "[\e[31mFAIL\e[0m] ${domain} NO resuelve en DNS"
  fi
done

echo -e "\n=== 2. Probando conectividad TCP a Load Balancers ==="
for item in "${TARGETS[@]}"; do
  host=$(echo $item | cut -d: -f1)
  port=$(echo $item | cut -d: -f2)

  nc -zv -w 3 "$host" "$port" &>/dev/null
  if [ $? -eq 0 ]; then
    echo -e "[\e[32mOK\e[0m] Conexión TCP exitosa a ${host}:${port}"
  else
    echo -e "[\e[31mFAIL\e[0m] No se puede conectar a ${host}:${port}"
  fi
done

echo -e "\n=== 3. Probando respuesta HTTP del API Server (/healthz) ==="
for fqdn in "${API_FQDN}" "${API_INT_FQDN}"; do
  http_code=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "https://${fqdn}:6443/healthz")
  if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 401 ]; then
    echo -e "[\e[32mOK\e[0m] ${fqdn}:6443/healthz respondió HTTP ${http_code}"
  else
    echo -e "[\e[33mWARN\e[0m] ${fqdn}:6443/healthz respondió HTTP ${http_code} (se espera 200/401 si los masters están activos)"
  fi
done
