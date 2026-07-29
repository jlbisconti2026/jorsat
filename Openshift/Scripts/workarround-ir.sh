#!/bin/bash

# ==============================================================================
# SCRIPT: Automatización del Workaround para Nodos Infra (Toleraciones)
# ==============================================================================

echo "=== 1. Aplicando parche al Ingress Controller (default) ==="

# Definimos el bloque JSON para nodePlacement (Selector + Tolerancia)
INGRESS_PATCH='{
  "spec": {
    "nodePlacement": {
      "nodeSelector": {
        "matchLabels": {
          "node-role.kubernetes.io/infra": ""
        }
      },
      "tolerations": [
        {
          "effect": "NoSchedule",
          "key": "infra",
          "operator": "Equal",
          "value": "reserved"
        }
      ]
    }
  }
}'

# Aplicamos el parche tipo 'merge'
oc patch ingresscontroller default -n openshift-ingress-operator --type=merge -p "$INGRESS_PATCH"

if [ $? -eq 0 ]; then
    echo "✔ Ingress Controller parchado correctamente."
else
    echo "❌ Error al parchar Ingress Controller."
fi


echo -e "\n=== 2. Aplicando parche al Image Registry (cluster) ==="

# Definimos el bloque JSON para las toleraciones del Registro
REGISTRY_PATCH='{
  "spec": {
    "tolerations": [
      {
        "effect": "NoSchedule",
        "key": "infra",
        "operator": "Equal",
        "value": "reserved"
      }
    ]
  }
}'

# Aplicamos el parche tipo 'merge'
oc patch configs.imageregistry.operator.openshift.io cluster --type=merge -p "$REGISTRY_PATCH"

if [ $? -eq 0 ]; then
    echo "✔ Image Registry parchado correctamente."
else
    echo "❌ Error al parchar Image Registry."
fi


echo -e "\n=== 3. Monitoreo del estado de los Pods ==="
echo "Esperando unos segundos a que los operadores procesen los cambios..."
sleep 5

echo -e "\n--> Pods en openshift-ingress:"
oc get po -n openshift-ingress | grep router-default

echo -e "\n--> Pods en openshift-image-registry:"
oc get po -n openshift-image-registry | grep image-registry-

echo -e "\n=== Proceso finalizado. Monitoreá 'oc get co' para confirmar la estabilidad ==="
