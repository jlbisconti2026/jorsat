# Índice de Contenidos

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Diagrama de la Secuencia de Recuperación](#2-diagrama-de-la-secuencia-de-recuperacion)
3. [Detalle Paso a Paso de las Soluciones Aplicadas](#3-detalle-paso-a-paso-de-las-soluciones-aplicadas)
   - [Paso 1: Reinstalación de Custom Resource Definitions (CRDs)](#paso-1-reinstalacion-de-custom-resource-definitions-crds)
   - [Paso 2: Eliminación de Webhooks Interceptores Bloqueantes](#paso-2-eliminacion-de-webhooks-interceptores-bloqueantes)
   - [Paso 3: Limpieza de Recursos Atascados (Finalizers)](#paso-3-limpieza-de-recursos-atascados-finalizers)
   - [Paso 4: Re-despliegue de Componentes Base e Infraestructura](#paso-4-re-despliegue-de-componentes-base-e-infraestructura)
   - [Paso 5: Despliegue de Entornos (Environments) y Virtual Hosts](#paso-5-despliegue-de-entornos-environments-y-virtual-hosts)

---

# Recuperación de Entorno Apigee Hybrid

## 1. Resumen Ejecutivo
Tras la pérdida o eliminación de las definiciones de recursos personalizados (CRDs) y releases de Helm en el namespace `gsve-apigee-hybrid-desa`, se procedió a la reconstrucción ordenada de la arquitectura del cluster de Apigee Hybrid.
El proceso involucró la reinstalación manual de CRDs evitando límites de anotaciones de Kubernetes, el desbloqueo de webhooks y finalizers trabados, la inicialización del clúster de almacenamiento Cassandra y el re-despliegue de los planos de control y ejecución por país (AR, PY, UY). El entorno se restableció al 100% de operatividad.

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
