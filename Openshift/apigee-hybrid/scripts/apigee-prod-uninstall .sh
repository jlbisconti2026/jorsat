#!/bin/bash

# ==============================================================================
# SCRIPT DE DESINSTALACIÓN COMPLETA DE APIGEE HYBRID (HELM + OPENSHIFT)
# Entorno: claro-apigee-hybrid-desa
# ==============================================================================

NAMESPACE="claro-apigee-hybrid-prod"

echo "=== 1. ELIMINANDO COMPONENTES DEL RUNTIME (PLANO DE DATOS) ==="
helm delete apigee-ingressgateway -n $NAMESPACE
helm delete apigee-runtime        -n $NAMESPACE
helm delete apigee-synchronizer   -n $NAMESPACE
helm delete apigee-mart           -n $NAMESPACE
helm delete apigee-telemetry      -n $NAMESPACE

echo "=== 2. ELIMINANDO COMPONENTES DE ALMACENAMIENTO (DATABASES) ==="
helm delete apigee-redis          -n $NAMESPACE
helm delete apigee-datastore      -n $NAMESPACE

echo "=== 3. ELIMINANDO CONTROLADORES Y OPERADORES ==="
helm delete apigee-operator       -n $NAMESPACE
helm delete apigee-infra          -n $NAMESPACE

echo "=== 4. LIMPIEZA CRÍTICA DE RECURSOS PERSISTENTES EN EL NAMESPACE ==="
# Eliminar secretos residuales de credenciales
oc delete secret apigee-datastore-default-creds -n $NAMESPACE --ignore-not-found

# Eliminar todos los volúmenes físicos (PVCs) para evitar reutilizar la DB corrupta
oc delete pvc --all -n $NAMESPACE

echo "=== 5. ELIMINANDO CUSTOM RESOURCE DEFINITIONS (CRDs) DEL CLÚSTER ==="
# Este paso remueve las definiciones globales de Apigee del API Server de OpenShift
oc get crd | grep apigee.cloud.google.com | awk '{print $1}' | xargs -r oc delete crd

echo "=== PROCESO DE DESINSTALACIÓN COMPLETADO ==="
echo "El namespace $NAMESPACE quedó limpio y listo para una nueva instalación."
