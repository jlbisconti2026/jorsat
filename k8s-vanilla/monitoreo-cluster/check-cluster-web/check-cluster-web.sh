#!/bin/bash

OUTPUT_FILE="/var/www/html/index.html"

# Definir rutas obligatorias
export PATH=$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
KUBECTL_BIN="/usr/bin/kubectl"
KUBECONFIG_PATH="/home/jlb/.kube/config"

get_cluster_nodes_status() {
    local output
    output=$($KUBECTL_BIN --kubeconfig="$KUBECONFIG_PATH" get nodes -o json 2>&1)
    if [ $? -ne 0 ]; then
        echo "<tr><td colspan='3' style='color: #f44336;'>❌ Error ejecutando kubectl: <pre>$output</pre></td></tr>"
        return
    fi

    echo "$output" | jq -r '
        .items[] |
        {
            name: .metadata.name,
            ready: (.status.conditions[] | select(.type=="Ready") | .status),
            roles: [.metadata.labels | to_entries[] | select(.key | startswith("node-role.kubernetes.io/")) | .key | split("/")[1]] | join(", ")
        } |
        "\(.name)|\(.ready)|\(.roles)"
    ' | while IFS='|' read -r name ready roles; do
        [ -z "$name" ] && continue
        [ -z "$roles" ] && roles="worker"

        color="#4caf50"
        status="Ready"
        if [ "$ready" != "True" ]; then
            color="#f44336"
            status="NotReady"
        fi

        echo "<tr><td><b>$name</b></td><td>$roles</td><td><span style='color: $color;'>$status</span></td></tr>"
    done
}

get_control_plane_pods() {
    $KUBECTL_BIN --kubeconfig="$KUBECONFIG_PATH" get pods -n kube-system -o wide --no-headers 2>&1 | grep -E "etcd-|kube-apiserver-|kube-controller-manager-|kube-scheduler-" | while read -r name rready rstatus restarts age ip node rest; do
        [ -z "$name" ] && continue
        color="#e0e0e0"
        if [ "$restarts" -gt 0 ]; then
            color="#ff9800"
        fi
        echo "<tr><td><small>kube-system</small></td><td><b>$name</b></td><td>$rstatus</td><td><span style='color: $color;'>$restarts</span></td><td><code style='color: #03a9f4;'>$node</code></td></tr>"
    done
}

get_etcd_deep_health() {
    local etcd_pod=$($KUBECTL_BIN --kubeconfig="$KUBECONFIG_PATH" get pods -n kube-system --no-headers -l component=etcd 2>/dev/null | awk '{print $1}' | head -n 1)

    if [ -z "$etcd_pod" ]; then
        echo "<p style='color: #f44336;'>No se encontró ningún pod de etcd activo en kube-system.</p>"
        return
    fi

    local node_name=$($KUBECTL_BIN --kubeconfig="$KUBECONFIG_PATH" get pod "$etcd_pod" -n kube-system -o jsonpath='{.spec.nodeName}' 2>/dev/null)
    local cert="/etc/kubernetes/pki/etcd/peer.crt"
    local key="/etc/kubernetes/pki/etcd/peer.key"
    local ca="/etc/kubernetes/pki/etcd/ca.crt"

    echo "<p style='color: #03a9f4; font-size: 13px; margin-bottom: 5px;'>📍 <b>Nodo analizado:</b> $node_name</p>"
    echo "<h4>📡 Salud de Endpoints</h4>"
    echo "<pre style='background: #111; color: #4caf50; padding: 10px; border-radius: 5px; font-family: monospace; overflow-x: auto;'>"
    $KUBECTL_BIN --kubeconfig="$KUBECONFIG_PATH" -n kube-system exec --stdin "$etcd_pod" -- \
        etcdctl --cacert="$ca" --cert="$cert" --key="$key" --endpoints="https://127.0.0.1:2379" endpoint health -w table 2>&1
    echo "</pre>"
}

get_top_nodes() {
    local output
    output=$($KUBECTL_BIN --kubeconfig="$KUBECONFIG_PATH" top nodes 2>&1)
    if [ $? -ne 0 ] || echo "$output" | grep -qi "error"; then
        echo "<tr><td colspan='3' style='color: #ff9800;'>⚠️ Métricas de nodos no disponibles (¿Metrics-server instalado?)</td></tr>"
        return
    fi

    echo "$output" | tail -n +2 | while read -r node cpu cpupct mem mempct; do
        [ -z "$node" ] && continue
        echo "<tr><td><b>$node</b></td><td>$cpu ($cpupct)</td><td>$mem ($mempct)</td></tr>"
    done
}

get_pods_failing() {
    $KUBECTL_BIN --kubeconfig="$KUBECONFIG_PATH" get pods --all-namespaces -o json 2>/dev/null | \
        jq -r '.items[] | select(.status.containerStatuses[]?.state.waiting != null) | "\(.metadata.namespace)|\(.metadata.name)|\(.status.containerStatuses[].state.waiting.reason)"' | \
        while IFS='|' read -r ns pod reason; do
            echo "<tr><td>$ns</td><td><b>$pod</b></td><td><span style='color: #f44336;'>$reason</span></td></tr>"
        done
}

get_pvc_errors() {
    $KUBECTL_BIN --kubeconfig="$KUBECONFIG_PATH" get pvc --all-namespaces --no-headers 2>/dev/null | grep -Ev 'Bound' | while read -r ns name status rest; do
        echo "<tr><td>$ns</td><td><b>$name</b></td><td><span style='color: #f44336;'>$status</span></td></tr>"
    done
}

get_ingress() {
    $KUBECTL_BIN --kubeconfig="$KUBECONFIG_PATH" get po -n ingress-nginx -o wide --no-headers 2>/dev/null | while read -r name rready rstatus restarts age ip node rest; do
        echo "<tr><td><b>$name</b></td><td>Corriendo</td><td><code style='color: #03a9f4;'>$node</code></td></tr>"
    done
}

# Bucle infinito para que el servicio systemd se mantenga activo y actualice cada 10s
while true; do
    # Recolectar datos
    html_nodes_status=$(get_cluster_nodes_status)
    html_cp=$(get_control_plane_pods)
    html_etcd=$(get_etcd_deep_health)
    html_top_nodes=$(get_top_nodes)
    html_pods_failing=$(get_pods_failing)
    html_pvc=$(get_pvc_errors)
    html_ingress=$(get_ingress)

    # Generar HTML
    cat <<EOF > "$OUTPUT_FILE"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Kubernetes Home Cluster Live Dashboard</title>
    <meta http-equiv="refresh" content="10">
    <style>
        body { font-family: Arial, sans-serif; background: #121212; color: #e0e0e0; margin: 30px; }
        h1 { color: #326ce5; }
        h2 { color: #03a9f4; border-bottom: 1px solid #333; padding-bottom: 5px; margin-top: 30px; }
        h4 { color: #ff9800; margin-bottom: 5px; }
        table { border-collapse: collapse; width: 100%; margin-top: 10px; background: #1e1e1e; margin-bottom: 20px; }
        th, td { border: 1px solid #333; padding: 10px; text-align: left; }
        th { background: #333; color: #fff; }
        .ok { color: #4caf50; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Kubernetes Home Cluster Live Dashboard</h1>
    <p>Monitoreo en tiempo real de recursos y salud del clúster (Actualización automática cada 10s)</p>

    <h2>1. Estado de los Nodos</h2>
    <table>
        <tr><th>Nodo</th><th>Roles</th><th>Estado</th></tr>
        ${html_nodes_status:-"<tr><td colspan='3' class='ok'>No se pudieron leer los nodos</td></tr>"}
    </table>

    <h2>2. Control Plane Pods (Etcd, API Server, Controllers, Scheduler)</h2>
    <table>
        <tr><th>Namespace</th><th>Pod / Componente</th><th>Estado</th><th>Reinicios</th><th>Nodo Asignado</th></tr>
        ${html_cp:-"<tr><td colspan='5' class='ok'>Sin datos del control plane</td></tr>"}
    </table>

    <h2>3. Diagnóstico Profundo de Etcd</h2>
    <div style="background: #1e1e1e; border: 1px solid #333; padding: 15px; border-radius: 5px; margin-bottom: 20px;">
        ${html_etcd:-"<p class='ok'>Sin datos de etcd</p>"}
    </div>

    <h2>4. Uso de Nodos (CPU y Memoria)</h2>
    <table>
        <tr><th>Nodo</th><th>CPU Usado (% del total)</th><th>Memoria Usada (% del total)</th></tr>
        ${html_top_nodes:-"<tr><td colspan='3' class='ok'>Métricas de nodos no disponibles (¿Metrics-server instalado?)</td></tr>"}
    </table>

    <h2>5. Pods con Errores</h2>
    <table>
        <tr><th>Namespace</th><th>Pod</th><th>Razón</th></tr>
        ${html_pods_failing:-"<tr><td colspan='3' class='ok'>✅ No hay pods fallando</td></tr>"}
    </table>

    <h2>6. PVCs con Problemas</h2>
    <table>
        <tr><th>Namespace</th><th>PVC</th><th>Estado</th></tr>
        ${html_pvc:-"<tr><td colspan='3' class='ok'>✅ Todos los PVCs están Bound</td></tr>"}
    </table>

    <h2>7. Ingress Controller (nginx)</h2>
    <table>
        <tr><th>Pod Ingress</th><th>Estado</th><th>Nodo Asignado</th></tr>
        ${html_ingress:-"<tr><td colspan='3' class='ok'>Sin datos de ingress</td></tr>"}
    </table>
</body>
</html>
EOF

    sleep 10
done
