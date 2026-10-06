#!/bin/bash

# check-etcd-health.sh
# Verifica salud, miembros y líder del clúster etcd desde bastión OpenShift

NAMESPACE="openshift-etcd"
LABEL="k8s-app=etcd"
NODE="master0.labogsve.com"  # ⚠️ Cambiar si estás en otro nodo master si hace falta

echo "🧠 Buscando pod etcd..."
ETCD_POD=$(oc get pods -n "$NAMESPACE" -l "$LABEL" -o name | grep "$NODE")

if [[ -z "$ETCD_POD" ]]; then
  echo "❌ No se encontró el pod etcd del nodo $NODE"
  exit 1
fi

echo "✅ Pod etcd encontrado: $ETCD_POD"
echo "-----------------------------------------"

# Rutas de certificados
CERT="/etc/kubernetes/static-pod-resources/secrets/etcd-all-certs/etcd-peer-$NODE.crt"
KEY="/etc/kubernetes/static-pod-resources/secrets/etcd-all-certs/etcd-peer-$NODE.key"
CA="/etc/kubernetes/static-pod-resources/configmaps/etcd-all-bundles/server-ca-bundle.crt"

# ✅ Extraer solo CLIENT ADDRS y filtrar solo puerto 2379
ENDPOINTS=$(oc -n "$NAMESPACE" exec --stdin "$ETCD_POD" -- \
  env -i etcdctl \
    --cert="$CERT" \
    --key="$KEY" \
    --cacert="$CA" \
    --endpoints=https://127.0.0.1:2379 \
    member list | cut -d '|' -f6 | grep -o 'https://[^ ]*:2379' | sort -u | paste -sd "," -)

echo "🔗 Endpoints detectados: $ENDPOINTS"
echo "-----------------------------------------"

# 1. Chequeo de salud
echo "📡 Chequeando salud del clúster etcd..."
oc -n "$NAMESPACE" exec --stdin "$ETCD_POD" -- \
    env -i etcdctl \
    --cert="$CERT" \
    --key="$KEY" \
    --cacert="$CA" \
    --endpoints="$ENDPOINTS" \
    endpoint health -w table

echo "-----------------------------------------"

# 2. Lista de miembros
echo "👥 Chequeando miembros del clúster etcd..."
oc -n "$NAMESPACE" exec --stdin "$ETCD_POD" -- \
    env -i etcdctl \
    --cert="$CERT" \
    --key="$KEY" \
    --cacert="$CA" \
    --endpoints=https://127.0.0.1:2379 \
    member list -w table

echo "-----------------------------------------"

# 3. Mostrar el líder
echo "👑 Identificando líder del clúster etcd..."
oc -n "$NAMESPACE" exec --stdin "$ETCD_POD" -- \
   env -i etcdctl \
    --cert="$CERT" \
    --key="$KEY" \
    --cacert="$CA" \
    --endpoints="$ENDPOINTS" \
    endpoint status -w table | awk '$4 == "true"'

echo "✅ Chequeo completado."

