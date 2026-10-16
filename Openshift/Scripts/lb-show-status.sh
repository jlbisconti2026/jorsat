    #!/bin/bash

    OUTPUT_FILE="/var/www/html/index.html"

    # Nodos y puertos de infraestructura y control
    TARGETS=(
        "Bootstrap:10.92.186.39:6443"
        "Bootstrap:10.92.186.39:22623"
        "Master-01:10.92.186.11:6443"
        "Master-02:10.92.186.12:6443"
        "Master-03:10.92.186.13:6443"
        "Infra-01:10.92.186.14:80"
        "Infra-01:10.92.186.14:443"
        "Infra-02:10.92.186.15:80"
        "Infra-02:10.92.186.15:443"
        "Infra-03:10.92.186.16:80"
        "Infra-03:10.92.186.16:443"
    )

    # Pruebas de DNS a incluir
    DNS_TARGETS=(
        "api.osesapeic01.claro.amx:api.osesapeic01.claro.amx"
        "api-int.osesapeic01.claro.amx:api-int.osesapeic01.claro.amx"
        "Apps Wildcard:test-validacion.apps.osesapeic01.claro.amx"
        "Apps-SSL Wildcard:test-validacion.apps-ssl.osesapeic01.claro.amx"
    )

    # Pruebas de conectividad TCP a LBs
    TCP_TARGETS=(
        "LB API:10.92.150.246:6443"
        "LB API-Int:10.92.150.247:6443"
        "LB API-Int (Machine Config):10.92.150.247:22623"
    )

    # Pruebas de Healthz
    HEALTH_TARGETS=(
        "API Server (External):https://api.osesapeic01.claro.amx:6443/healthz"
        "API Server (Internal):https://10.92.150.247:6443/healthz"
    )

    check_port() {
        local host=$1
        local port=$2
        timeout 1 bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "<span style='color: #4caf50; font-weight: bold;'>UP</span>"
        else
            echo -e "<span style='color: #f44336; font-weight: bold;'>DOWN</span>"
        fi
    }

    check_dns() {
        local name=$1
        local domain=$2
        local ip=$(dig +short "$domain" | tail -n1)
        if [ -n "$ip" ]; then
            echo "<span style='color: #4caf50;'>[OK] Resuelve a: <b>$ip</b></span>"
        else
            echo "<span style='color: #f44336;'>[FAIL] Sin resolución DNS</span>"
        fi
    }

    check_http_health() {
        local name=$1
        local url=$2
        local code=$(curl -k -s -o /dev/null -w "%{http_code}" --max-time 2 "$url")
        if [ "$code" -eq 200 ]; then
            echo "<span style='color: #4caf50;'>[OK] HTTP 200</span>"
        else
            echo "<span style='color: #f44336;'>[FAIL] HTTP Código: $code</span>"
        fi
    }

    echo "Generando estado completo de la infraestructura..."

    # 1. Filas de Nodos
    rows_nodes=""
    for item in "${TARGETS[@]}"; do
        IFS=':' read -r name host port <<< "$item"
        status=$(check_port "$host" "$port")
        rows_nodes+="<tr><td><b>$name</b></td><td>$host</td><td>$port</td><td>$status</td></tr>"
    done

    # 2. Filas de DNS
    rows_dns=""
    for item in "${DNS_TARGETS[@]}"; do
        IFS=':' read -r name domain <<< "$item"
        res=$(check_dns "$name" "$domain")
        rows_dns+="<tr><td><b>$name</b></td><td>$domain</td><td>$res</td></tr>"
    done

    # 3. Filas de TCP LBs
    rows_tcp=""
    for item in "${TCP_TARGETS[@]}"; do
        IFS=':' read -r name host port <<< "$item"
        status=$(check_port "$host" "$port")
        rows_tcp+="<tr><td><b>$name</b></td><td>$host</td><td>$port</td><td>$status</td></tr>"
    done

    # 4. Filas de Healthz
    rows_health=""
    for item in "${HEALTH_TARGETS[@]}"; do
        IFS=':' read -r name url <<< "$item"
        res=$(check_http_health "$name" "$url")
        rows_health+="<tr><td><b>$name</b></td><td><small>$url</small></td><td>$res</td></tr>"
    done

    # Generar HTML completo
    cat <<EOF > "$OUTPUT_FILE"
    <!DOCTYPE html>
    <html>
    <head>
        <title>Health y status de blanaceos</title>
        <meta http-equiv="refresh" content="5">
        <style>
            body { font-family: Arial, sans-serif; background: #121212; color: #e0e0e0; margin: 30px; }
            h1 { color: #ff5722; }
            h2 { color: #03a9f4; border-bottom: 1px solid #333; padding-bottom: 5px; margin-top: 30px; }
            table { border-collapse: collapse; width: 100%; margin-top: 10px; background: #1e1e1e; margin-bottom: 20px; }
            th, td { border: 1px solid #333; padding: 10px; text-align: left; }
            th { background: #333; color: #fff; }
        </style>
    </head>
    <body>
        <h1>Dashboard nodos y balanceo</h1>
        <p>Estado de servicios, DNS y conectividad del cluster (Actualización automática cada 5s)</p>

        <h2>1. Resolución DNS (API y Apps)</h2>
        <table>
            <tr><th>Componente</th><th>Dominio / Wildcard</th><th>Resultado</th></tr>
            $rows_dns
        </table>

        <h2>2. Conectividad TCP a Load Balancers</h2>
        <table>
            <tr><th>Load Balancer</th><th>IP</th><th>Puerto</th><th>Estado</th></tr>
            $rows_tcp
        </table>

        <h2>3. Respuesta HTTP del API Server (/healthz)</h2>
        <table>
            <tr><th>Endpoint</th><th>URL</th><th>Estado</th></tr>
            $rows_health
        </table>

        <h2>4. Estado de Nodos (Control Plane & Infra)</h2>
        <table>
            <tr><th>Componente</th><th>IP</th><th>Puerto</th><th>Estado</th></tr>
            $rows_nodes
        </table>
    </body>
    </html>
    EOF

    echo "¡Listo! Dashboard actualizado con DNS, LBs y Healthz en $OUTPUT_FILE"