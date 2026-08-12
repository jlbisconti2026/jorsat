
# Indice

[Resumen Ejecutivo](#resumen-ejecutivo)

[Descripcion del Problema](#descripcion-del-problema)

[Analisis e ientificacion de la causa raiz](#analisis-e-identificacion-de-la-causa-raiz)

[Diagnostico de Infraestructura](#diagnostico-de-infraestructura)

[Pasos de la solucion aplicada](#pasos-de-la-solución-aplicada)

[Verificacion y Validacion](#verificacion-y-validacion)

[Consultas de Monitoreo Recomendadas](#consultas-de-monitoreo-recomendadas)

## Resumen Ejecutivo

El componente apigee-runtime desplegado en la infraestructura On-Premises presentaba intermitencias fatales al momento de despachar datos de analítica (AX) hacia Google Cloud Pub/Sub. Esto provocaba que los registros se acumularan en colas temporales en disco. Se identificó una falla en las políticas de IAM de GCP relacionada con la Service Account utilizada por Apigee. Tras otorgar el rol correspondiente (roles/pubsub.publisher), el servicio restableció la transmisión normal de telemetría.

## Descripcion del problema

Se detectaron excepciones recurrentes de severidad SEVERE / ERROR en los pods del runtime de Apigee:

com.google.api.gax.rpc.PermissionDeniedException: io.grpc.StatusRuntimeException: PERMISSION_DENIED: User not authorized to perform this action.
...
Caused by: io.grpc.StatusRuntimeException: PERMISSION_DENIED: User not authorized to perform this action.
...
message: "Failed to send record ... in dataset AX"
logger: "PubSubDispatcher"

Impacto
Métricas y Analytics: Imposibilidad de sincronizar las analíticas de tráfico con la consola de GCP Apigee.

Almacenamiento Local: Reintento e inyección de datos no despachados a archivos locales temporalmente (writeToFileTobeTriedLater).

## Analisis e identificacion de la causa raiz

Permisos de GCP IAM insuficientes: La cuenta de servicio de GCP <apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com> no contaba con el rol explícito de Publicador de Pub/Sub (roles/pubsub.publisher).

Excepción gRPC: La API de Pub/Sub rechazaba las peticiones provenientes del SDK Java de Apigee con un código HTTP/gRPC PERMISSION_DENIED (403).

## Diagnostico de Infraestructura

Durante la resolución se clarificó la arquitectura del entorno:

Entorno de Cómputo: Cluster On-Premises OpenShift (oseinfrait01.claro.amx), no Google Kubernetes Engine (GKE).

Mecanismo de Autenticación: Clave/Secret de Service Account directa (no aplica Workload Identity de GKE *.svc.id.goog).

Proyecto GCP Target: claup-apigee-hybrid-desa.

## Pasos de la Solución Aplicada

1. Asignación del Rol IAM en GCP
Se ejecutó la vinculación del rol de publicador sobre el proyecto GCP objetivo mediante gcloud:

```bash
gcloud projects add-iam-policy-binding claup-apigee-hybrid-desa \
    --member="serviceAccount:apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com" \
    --role="roles/pubsub.publisher"
 ```

## Confirmación de Políticas de IAM

Se validó la respuesta de la API de IAM garantizando que la vinculación quedara registrada correctamente:

```yaml
- members:
  - serviceAccount:apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com
  role: roles/pubsub.publisher
  ```

## Verificacion y validacion

```json
  {
  "thread": "AxDispatchContext-claup-apigee-hybrid-desa~test-ar",
  "logger": "SERVICES.COLLECTION",
  "message": "Sent AX data for scope claup-apigee-hybrid-desa~test-ar. Total number of message sent is 9. Queue size is 0",
  "severity": "INFO"
}
```

Estatus de Envío: Exitoso (Sent AX data).

Tamaño de Cola (Queue size): 0 (procesamiento en tiempo real restablecido sin acumulaciones).

Severidad: Cambió de SEVERE a INFO.

## Consultas de Monitoreo Recomendadas

Para dar seguimiento en Google Cloud Logging (Log Explorer):

Consulta de Éxito de Transmisión

resource.type="k8s_container"
resource.labels.project_id="claup-apigee-hybrid-desa"
jsonPayload.logger="SERVICES.COLLECTION"
jsonPayload.message:"Sent AX data"

Consulta para Alerta de Errores de Permiso

resource.type="k8s_container"
jsonPayload.logger="PubSubDispatcher"
jsonPayload.exceptionStackTrace:"PERMISSION_DENIED"
