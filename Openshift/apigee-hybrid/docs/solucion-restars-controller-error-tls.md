# Indice

 1. [Descripcion del Problema](#1-descripcion-del-problema)
 2. [Diagnóstico y Causa Raíz](#2-diagnostico-y-causa-raiz)
 3. [Pasos de la Solucion Aplicada](#3-pasos-de-la-solucion-aplicada)
 4. [Correccion de la estrategia de conversion en el crd](#correccion-de-la-estrategia-de-conversion-en-el-crd)
 5. [Inyeccion del certificado CA para TLS](#inyeccion-del-certificado-ca-para-tls)
 6. [Reinicio del Deployment](#reinicio-del-deployment)
 7. [Resultados y verificaccion](#resultados-y-verificacion)

## 1. Descripcion del Problema

El pod del controlador de Apigee Hybrid (apigee-controller-manager) en el namespace claro-apigee-hybrid-desa se encontraba en estado Ready: False (1/2 o 0/2), fallando repetidamente en su prueba de disponibilidad (readiness probe):

Warning  Unhealthy  Readiness probe failed: HTTP probe failed with statuscode: 500

## 2. Diagnostico y Causa Raiz

Al revisar los logs internos del contenedor manager, se identificaron dos fallas consecutivas:

Configuración del CRD incoherente:
El chequeo de salud CheckCABundleInjected del controlador arrojaba el siguiente error:

webhook config in conversion config not present in apigeedeployments.apigee.cloud.google.com

Al consultar la definición del Custom Resource Definition (CRD), se detectó que la estrategia de conversión estaba en None:

conversion:
  strategy: None

  Falla de Handshake TLS:

  Tras ajustar preliminarmente el CRD, surgieron errores continuos de TLS desde el API Server de OpenShift:

  http: TLS handshake error: remote error: tls: bad certificate

  Esto ocurría porque el CRD carecía del bloque caBundle necesario para validar las conexiones SSL/TLS hacia el endpoint de conversión.

## 3. Pasos de la Solucion Aplicada

## Correccion de la estrategia de conversion en el crd

Se cambió la estrategia de conversión del CRD de None a Webhook, asociándolo al servicio interno de Apigee.

## Inyeccion del Certificado CA para TLS

Se extrajo el certificado TLS desde el secreto webhook-server-cert y se aplicó un parche directo (oc patch) sobre el CRD para incluir explícitamente la CA y la configuración del webhook:

### 1. Extraer el certificado del secreto

EXPORTED_CA=$(oc get secret webhook-server-cert -n claro-apigee-hybrid-desa -o jsonpath='{.data.tls\.crt}')

### 2. Aplicar el parche al CRD

```yaml
oc patch crd apigeedeployments.apigee.cloud.google.com --type=merge -p "{
  \"spec\": {
    \"conversion\": {
      \"strategy\": \"Webhook\",
      \"webhook\": {
        \"clientConfig\": {
          \"caBundle\": \"$EXPORTED_CA\",
          \"service\": {
            \"name\": \"apigee-webhook-service\",
            \"namespace\": \"claro-apigee-hybrid-desa\",
            \"path\": \"/convert\",
            \"port\": 443
          }
        },
        \"conversionReviewVersions\": [\"v1\", \"v1alpha1\"]
      }
    }
  }
}"
```

## Reinicio del Deployment

Se forzó un reinicio controlado del controlador para que tome la nueva configuración del CRD y revalide los certificados:

```bash
oc rollout restart deployment/apigee-controller-manager -n claro-apigee-hybrid-desa
```

## Resultados y verificacion

Estado de los Pods: El pod del controlador pasó a estado READY: 2/2 y Running.

Estabilidad: Los errores de TLS Handshake desaparecieron por completo de los registros y las sondas /healthz y /readyz devolvieron respuestas exitosas 200 OK.

Persistencia: El pod se mantuvo estable de forma continua sin registrar nuevos reinicios por fallas de sistema.
