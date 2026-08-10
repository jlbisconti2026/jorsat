# Índice de Contenidos

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Diagrama de la Secuencia de Recuperación](#2-diagrama-de-la-secuencia-de-recuperacion)
3. [Detalle Paso a Paso de las Soluciones Aplicadas](#3-detalle-paso-a-paso-de-las-soluciones-aplicadas)
   - [Paso 1: Reinstalación de Custom Resource Definitions (CRDs)](#paso-1)
   - [Paso 2: Eliminación de Webhooks Interceptores Bloqueantes](#paso-2)
   - [Paso 3: Limpieza de Recursos Atascados (Finalizers)](#paso-3)
   - [Paso 4: Re-despliegue de Componentes Base e Infraestructura](#paso-4)
   - [Paso 5: Despliegue de Entornos (Environments) y Virtual Hosts](#paso-5)

---

# Recuperación de Entorno Apigee Hybrid

## 1. Resumen Ejecutivo

Tras la pérdida o eliminación de las definiciones de recursos personalizados (CRDs) y releases de Helm en el namespace `gsve-apigee-hybrid-desa`, se procedió a la reconstrucción ordenada de la arquitectura del cluster de Apigee Hybrid. El proceso involucró la reinstalación manual de CRDs evitando límites de anotaciones de Kubernetes, el desbloqueo de webhooks y finalizers trabados, la inicialización del clúster de almacenamiento Cassandra y el re-despliegue de los planos de control y ejecución por país (AR, PY, UY). El entorno se restableció al 100% de operatividad.

## 2. Diagrama de la Secuencia de Recuperación

Restauración de CRDs → 2. Desbloqueo de Webhooks → 3. Despliegue de Org & Redis → 4. Recuperación de Cassandra → 5. Despliegue de Runtimes y VirtualHosts

## 3. Detalle Paso a Paso de las Soluciones Aplicadas

### Paso 1: Reinstalación de Custom Resource Definitions (CRDs)

Problema: Al intentar aplicar los CRDs mediante `oc apply`, la API Server de OpenShift rechazaba la petición por superar el límite de bytes en anotaciones (`metadata.annotations: Too long: may not be more than 262144 bytes`).

Solución: Se aplicaron los manifiestos omitiendo la anotación de última configuración mediante `oc create`:

```bash
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeeorganizations.yaml
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeeenvironments.yaml
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeeroutes.yaml
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeeredis.yaml
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeedeployments.yaml
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeeissues.yaml
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeerouteconfigs.yaml
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeedatastores.yaml
```

Validación: Se confirmó la existencia de los 11 CRDs con oc get crd | grep apigee:

```bash
oc get crd | grep apigee
```

apigeedatastores.apigee.cloud.google.com
apigeedeployments.apigee.cloud.google.com
apigeeenvironments.apigee.cloud.google.com
apigeeissues.apigee.cloud.google.com
apigeeorganizations.apigee.cloud.google.com
apigeeredis.apigee.cloud.google.com
apigeerouteconfigs.apigee.cloud.google.com
apigeetelemetries.apigee.cloud.google.com
apigeeroutes.apigee.cloud.google.com
cassandradatareplications.apigee.cloud.google.com
secretrotations.apigee.cloud.google.com

### Paso 2: Eliminación de Webhooks Interceptores Bloqueantes

Problema: Los comandos de Helm rebotaban con el error failed calling webhook: no endpoints available for service "apigee-webhook-service".

Solución: Se removieron temporalmente las reglas de validación y mutación para permitir que Helm registre las nuevas entregas mientras el operador se estabilizaba:

```bash
oc delete mutatingwebhookconfiguration apigee-mutating-webhook-configuration-claro-apigee-hybrid-desa
oc delete validatingwebhookconfiguration apigee-validating-webhook-configuration-claro-apigee-hybrid-desa
oc rollout restart deployment/apigee-controller-manager -n claro-apigee-hybrid-desa
```

### Paso 3: Limpieza de Recursos Atascados (Finalizers)

Problema: El recurso apigeedatastore.apigee.cloud.google.com/default se mantenía en estado deleting, bloqueando la creación del StatefulSet de Cassandra y sus PVCs.

Solución: Se forzó la remoción del finalizer para liberar la API de Kubernetes:

```bash
oc patch apigeedatastore default -n claro-apigee-hybrid-desa -p '{"metadata":{"finalizers":null}}' --type=merge
```

### Paso 4: Re-despliegue de Componentes Base e Infraestructura

Con los webhooks y CRDs en orden, se ejecutó el despliegue con Helm de la Organización, Datastore (Cassandra), Redis e Ingress:

```bash
helm upgrade --install org apigee-org/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml
helm upgrade --install apigee-datastore apigee-datastore/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml
helm upgrade --install redis apigee-redis/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml
helm upgrade --install apigee-telemetry apigee-telemetry/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml
helm upgrade --install ingress-manager apigee-ingress-manager/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml
```

Resultado: Se provisionaron los nodos apigee-cassandra-default-0, 1, 2 en estado 2/2 Running.

Acción Correctiva Menor: Se reiniciaron los pods de schema-setup para forzar la conexión inmediata contra Cassandra recién creada, logrando el estado Completed y liberando la inicialización del pod MART.

### Paso 5: Despliegue de Entornos (Environments) y Virtual Hosts

Finalmente, se re-instalaron los entornos de ejecución para Argentina, Paraguay y Uruguay.

Entornos (Environments):

```bash
helm upgrade --install env-desa-ar apigee-env/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=desa-ar
helm upgrade --install env-desa-py apigee-env/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=desa-py
helm upgrade --install env-desa-uy apigee-env/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=desa-uy
helm upgrade --install env-test-ar apigee-env/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=test-ar
helm upgrade --install env-test-py apigee-env/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=test-py
helm upgrade --install env-test-uy apigee-env/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=test-uy
```

Virtual Hosts:
```bash
helm upgrade --install vh-desa-test-ar apigee-virtualhost/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=desa-ar
helm upgrade --install vh-desa-test-py apigee-virtualhost/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=desa-py
```

