#!/bin/bash

OUTPUT_FILE="/var/www/html/ocp-status.html"

# Asegurar rutas y credenciales de OpenShift
export PATH=$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export KUBECONFIG="${KUBECONFIG:-/root/auth/kubeconfig}"

get_pods_failing() {
    oc get pods --all-namespaces -o json 2>/dev/null | \
        jq -r '.items[] | select(.status.containerStatuses[]?.state.waiting != null) | "\(.metadata.namespace)|\(.metadata.name)|\(.status.containerStatuses[].state.waiting.reason)"' | \
        while IFS='|' read -r ns pod reason; do
            if [[ "$reason" == "CrashLoopBackOff" || "$reason" == "ImagePullBackOff" ]]; then
                echo "<tr><td>$ns</td><td><b>$pod</b></td><td><span style='color: #f44336;'>$reason</span></td></tr>"
            else
                echo "<tr><td>$ns</td><td><b>$pod</b></td><td><span style='color: #ff9800;'>$reason</span></td></tr>"
            fi
        done
}

get_top_nodes() {
    oc adm top nodes 2>/dev/null | tail -n +2 | while read -r node cpu cpupct mem mempct; do
        [ -z "$node" ] && continue
        echo "<tr><td><b>$node</b></td><td>$cpu ($cpupct)</td><td>$mem ($mempct)</td></tr>"
    done
}

get_cluster_operators() {
    oc get clusteroperators --no-headers 2>/dev/null | while read -r co_name co_avail co_prog co_deg rest; do
        [ -z "$co_name" ] && continue
        color="#4caf50"
        status="OK"
        if [ "$co_avail" != "True" ] || [ "$co_prog" != "False" ] || [ "$co_deg" != "True" ]; then
            color="#f44336"
            status="DEGRADED"
        fi
        echo "<tr><td><b>$co_name</b></td><td>$co_avail</td><td>$co_prog</td><td>$co_deg</td><td><span style='color: $color;'>$status</span></td></tr>"
    done
}

get_mcp() {
    oc get mcp --no-headers 2>/dev/null | while read -r name upd up deg dej rest; do
        [ -z "$name" ] && continue
        echo "<tr><td><b>$name</b></td><td>$upd</td><td>$up</td><td>$deg</td><td>$dej</td></tr>"
    done
}

get_pvc_errors() {
    oc get pvc --all-namespaces --no-headers 2>/dev/null | grep -Ev 'Bound' | while read -r ns name status rest; do
        [ -z "$ns" ] && continue
        echo "<tr><td>$ns</td><td><b>$name</b></td><td><span style='color: #f44336;'>$status</span></td></tr>"
    done
}

get_pods_pending() {
    oc get pods --all-namespaces --field-selector=status.phase=Pending --no-headers 2>/dev/null | while read -r ns name rest; do
        [ -z "$ns" ] && continue
        echo "<tr><td>$ns</td><td><b>$name</b></td><td><span style='color: #ff9800;'>Pending</span></td></tr>"
    done
}

get_ingress() {
    oc get po -n openshift-ingress -o wide --no-headers 2>/dev/null | while read -r name rready rstatus restarts age ip node nomin_node nomination_gce_zone; do
        [ -z "$name" ] && continue
        echo "<tr><td><b>$name</b></td><td>Corriendo</td><td><code style='color: #03a9f4;'>$node</code></td></tr>"
    done
}

get_registry() {
    oc get po -n openshift-image-registry -o wide --no-headers 2>/dev/null | grep -i "image-registry" | while read -r name rready rstatus restarts age ip node nomin_node nomination_gce_zone; do
        [ -z "$name" ] && continue
        echo "<tr><td><b>$name</b></td><td>Activo</td><td><code style='color: #03a9f4;'>$node</code></td></tr>"
    done
}

# Recolectar datos
html_pods_failing=$(get_pods_failing)
html_top_nodes=$(get_top_nodes)
html_co=$(get_cluster_operators)
html_mcp=$(get_mcp)
html_pvc=$(get_pvc_errors)
html_pending=$(get_pods_pending)
html_ingress=$(get_ingress)
html_registry=$(get_registry)

# Generar HTML
cat <<EOF > "$OUTPUT_FILE"
<!DOCTYPE html>
<html>
<head>
    <title>OCP Cluster Health Dashboard</title>
    <meta http-equiv="refresh" content="10">
    <style>
        body { font-family: Arial, sans-serif; background: #121212; color: #e0e0e0; margin: 30px; }
        h1 { color: #ff5722; }
        h2 { color: #03a9f4; border-bottom: 1px solid #333; padding-bottom: 5px; margin-top: 30px; }
        table { border-collapse: collapse; width: 100%; margin-top: 10px; background: #1e1e1e; margin-bottom: 20px; }
        th, td { border: 1px solid #333; padding: 10px; text-align: left; }
        th { background: #333; color: #fff; }
        .ok { color: #4caf50; font-weight: bold; }
    </style>
</head>
<body>
    <h1>OpenShift Cluster Live Dashboard</h1>
    <p>Monitoreo en tiempo real de recursos y salud del clúster (Actualización automática cada 10s)</p>

    <h2>1. ClusterOperators</h2>
    <table>
        <tr><th>Operador</th><th>Available</th><th>Progressing</th><th>Degraded</th><th>Estado General</th></tr>
        ${html_co:-"<tr><td colspan='5' class='ok'>✅ Todos los operadores OK</td></tr>"}
    </table>

    <h2>2. MachineConfigPools (MCP)</h2>
    <table>
        <tr><th>ConfigPool</th><th>Updated</th><th>Updating</th><th>Degraded</th><th>Degraded(Machines)</th></tr>
        ${html_mcp:-"<tr><td colspan='5' class='ok'>No se pudieron leer los MCP</td></tr>"}
    </table>

    <h2>3. Uso de Nodos (CPU y Memoria)</h2>
    <table>
        <tr><th>Nodo</th><th>CPU Usado (% del total)</th><th>Memoria Usada (% del total)</th></tr>
        ${html_top_nodes:-"<tr><td colspan='3' class='ok'>Métricas de nodos no disponibles</td></tr>"}
    </table>

    <h2>4. Pods con Errores (CrashLoop / ImagePull)</h2>
    <table>
        <tr><th>Namespace</th><th>Pod</th><th>Razón</th></tr>
        ${html_pods_failing:-"<tr><td colspan='3' class='ok'>✅ No hay pods fallando por CrashLoop/ImagePull</td></tr>"}
    </table>

    <h2>5. Pods en Estado Pending</h2>
    <table>
        <tr><th>Namespace</th><th>Pod</th><th>Estado</th></tr>
        ${html_pending:-"<tr><td colspan='3' class='ok'>✅ No hay pods en Pending</td></tr>"}
    </table>

    <h2>6. PVCs con Problemas</h2>
    <table>
        <tr><th>Namespace</th><th>PVC</th><th>Estado</th></tr>
        ${html_pvc:-"<tr><td colspan='3' class='ok'>✅ Todos los PVCs están Bound</td></tr>"}
    </table>

    <h2>7. Routers de Ingress e Image Registry</h2>
    <table>
        <tr><th>Pod Ingress</th><th>Estado</th><th>Nodo Asignado</th></tr>
        ${html_ingress:-"<tr><td colspan='3' class='ok'>Sin datos de ingress</td></tr>"}
    </table>
    <table>
        <tr><th>Pod Image Registry</th><th>Estado</th><th>Nodo Asignado</th></tr>
        ${html_registry:-"<tr><td colspan='3' class='ok'>Sin datos de image-registry</td></tr>"}
    </table>
</body>
</html>
EOF

echo "¡Listo! Dashboard actualizado correctamente en $OUTPUT_FILE"
