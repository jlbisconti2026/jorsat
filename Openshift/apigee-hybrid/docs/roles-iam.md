# Roles por Cuenta de Servicio

Si usas el modelo recomendado de cuentas separadas, estos son los roles exactos para cada componente. Si usas una sola SA unificada en No-Prod, esa única cuenta debe llevar la suma de todos estos roles:

| Componente de Apigee | Nombre Técnico del Rol de GCP | ¿Para qué sirve? |
| :--- | :--- | :--- |
| **Synchronizer** | `roles/apigee.synchronizerManager` | Permite al pod descargar los bundles de los proxies desde GCS (el que habilitamos hoy). |
| **Watcher** | `roles/apigee.runtimeAgent` | Permite al pod enviar datos de configuración al plano de control de GCP. |
| **Runtime** | `roles/apigee.analyticsAgent` | Permite a las APIs enviar los datos de telemetría y analítica de tráfico a GCP. |
| **MART** | `roles/apigee.entriesProcessor` | Permite la comunicación de gestión de datos de las APIs del runtime. |
| **UDCA** | `roles/apigee.analyticsAgent` | Recolecta y sube los datos analíticos de las llamadas (comparte rol con Runtime). |
| **Connect Agent** | `roles/apigee.runtimeAgent` | Mantiene el túnel de conexión activo (comparte rol con Watcher). |


Entorno actual de DESA / TEST:
Como unificaste las funciones en apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com, asegúrate de que esa única cuenta tenga asignados en IAM estos 4 roles en paralelo:
1.	Administrador de Apigee Synchronizer (roles/apigee.synchronizerManager)
2.	Agente de tiempo de ejecución de Apigee (roles/apigee.runtimeAgent)
3.	Agente de analítica de Apigee (roles/apigee.analyticsAgent)
4.	Procesador de entradas de Apigee (roles/apigee.entriesProcessor)
En tu futuro entorno de PROD:
Por políticas de seguridad corporativa y auditoría en producción, la recomendación estricta es crear cuatro Service Accounts distintas en el proyecto de producción:
•	apigee-synchronizer@claro-apigee-hybrid-prod... ➔ Con el rol synchronizerManager
•	apigee-watcher@claro-apigee-hybrid-prod... ➔ Con el rol runtimeAgent
•	apigee-runtime@claro-apigee-hybrid-prod... ➔ Con el rol analyticsAgent
•	apigee-mart@claro-apigee-hybrid-prod... ➔ Con el rol entriesProcessor
💡 Recordatorio de Oro: No importa si usas una sola cuenta o cuentas separadas, cada vez que crees la SA del Synchronizer en cualquier ambiente, el paso final e indispensable será ejecutar el comando setSyncAuthorization que descubrimos hoy para darle luz verde en la nube.
Component Service Accounts and IAM Roles
Component / Service Account Name	Predefined IAM Role	IAM Role Reference String	Purpose & Permissions
apigee-synchronizer	Apigee Synchronizer Manager	roles/apigee.synchronizerManager	Downloads proxy bundles and environment configuration data from the management plane.
apigee-udca	Apigee Analytics Agent	roles/apigee.analyticsAgent	Universal Data Collection Agent; uploads API metrics, analytics, trace, and status records.
apigee-mart / apigee-connect	Apigee Connect Agent	roles/apigeeconnect.Agent	Manages the secure bidirectional connection between the runtime and Google management plane.
apigee-watcher	Apigee Runtime Agent	roles/apigee.runtimeAgent	Watches and monitors controller routing changes and deployments.
apigee-logger	Logs Writer	roles/logging.logWriter	Streams system and application logs to Cloud Logging.
apigee-metrics	Monitoring Metric Writer	roles/monitoring.metricWriter	Writes health metrics directly into Cloud Monitoring.
apigee-cassandra	Storage Object Admin	roles/storage.objectAdmin	Used optionally for backing up and restoring database cluster snapshots into Cloud Storage.
apigee-runtime	Optional Roles Only	roles/cloudtrace.agent (Optional)	Requires no default role, but requires Cloud Trace Agent if using Google Distributed Tracing.

