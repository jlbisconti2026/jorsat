
# Indice 

1. [Login de gcloud a GCP](#login-de-gcloud-a-gcp)
2. [Crear proyectos](#crear-proyectos)
3. [Borrar proyectos](#borrar-proyectos)
4. [Recuperar proyecto borrado](#recuperar-proyecto-borrado)
5. [Renombrar proyectos](#borrar-proyectos)
6. [Listar proyectos GCP](#listar-proyectos-gcp)
7. [Listar organizaciones disponibles](#listar-organizaciones-disponibles)
8. [ Listar envs creados](#listar-envs-creados)
9. [Listar api proxies](#listar-api-proxies)
10. [Listar deployments de los proxies](#listar-deployments-de-los-proxies)
11. [Crear api proxies a partir de archivo exportado de otro apigee](#crear-api-proxies-a-partir-de-archivo-exportado-de-otro-apigee)
12. [Crear api proxies a partir de carpeta local](#crear-api-proxies-a-partir-de-carpeta-local)
13. [Quitar/desactivar proxy de un entorno](#quitardesactivar-proxy-de-un-entorno)
14. [Obtener información de un proxy](#obtener-información-de-un-proxy)
15. [Crear bucket en GCP](#crear-bucket-en-gcp)
16. [Otras opciones de gcloud storage](#otras-opciones-de-gcloud-storage)
17. [Exportar envs y grupos de envs](#exportar-envs-y-grupos-de-envs)
18. [Asignar iam policy para error con pubsub.publisher (afecta analíticas)]19,(#asignar-iam-policy-para-error-con-pubsubpublisher-afecta-analíticas)


## Login de gcloud a GCP 

```bash
gcloud auth login
```

Tiene validación con gcloud mediante la cuenta de AD de claro con google

## Crear proyectos

```bash
gcloud projects create  [PROJECT_ID o nombre]
```
## Borrar proyectos

```bash
gcloud projects delete  [PROJECT_ID o nombre]
```

## Recuperar proyecto borrado 

```bash
gcloud projects undelete  [PROJECT_ID o nombre]
```

## Renombrar proyectos

```bash
 gcloud projects update [PROJECT_ID o nombre]
```

## Listar proyectos GCP

```bash
 gcloud projects list
 ```

```bash
gcloud projects list | grep apigee
```

claup-apigee-hybrid-desa    claup-apigee-hybrid-desa    1010788170711
claup-apigee-hybrid-prod    claup-apigee-hybrid-prod    300430456458

## Listar organizaciones disponibles

```bash
gcloud apigee organizations list
```

Resultado:

PS C:\Users\CTI24114> gcloud apigee organizations list
NAME                      PROJECT
claup-apigee-hybrid-desa  claup-apigee-hybrid-desa
claup-apigee-hybrid-prod  claup-apigee-hybrid-prod

## Listar envs creados

```bash
  gcloud apigee environments list
```
Resultado: 

- desa-ar
- desa-py
- desa-uy
- test-ar
- test-py
- test-uy

## Listar api proxies

Comando:

```bash
 gcloud apigee apis list
 ```
Resultado:

- AUP_Proxy_Prueba_DD
- myproxy-ar
- myproxy-py
- myproxy-uy

## Listar deployments de los proxies

```bash
gcloud apigee deployments list
```

Resultado:

ENVIRONMENT  API_PROXY   REVISION
test-ar      myproxy-ar  1
test-py      myproxy-py  1
test-uy      myproxy-uy  1
desa-ar      myproxy-ar  1
desa-py      myproxy-py  1
desa-uy      myproxy-uy  1

## Crear api proxies a partir de archivo exportado de otro apigee

### Importa y despliega directamente el zip exportado

```bash
gcloud apigee apis deploy --organization=claup-apigee-hybrid-prod --environment=prod-ar --api=mi-api-exportada --file=.\mi-api-v1.zip --override
```

## Crear api proxies a partir de carpeta local 


### Apuntando directamente a la carpeta local

```bash
gcloud apigee apis deploy --organization=claup-apigee-hybrid-desa --environment=desa-ar --api=mi-api --file=.\ruta\a\mi-carpeta-proxy --override
```

## Quitar/desactivar proxy de un entorno  

```bash
gcloud apigee apis undeploy  --organization=claup-apigee-hybrid-desa   --environment=desa-ar   --api=nombre-del-proxy
```

## Obtener información de un proxy 

```bash
 gcloud apigee apis describe myproxy-ar
 ```

 Resultado:

apiProxyType: PROGRAMMABLE
latestRevisionId: '1'
metaData:
  createdAt: '1783542114388'
  lastModifiedAt: '1783542114388'
  subType: Proxy
name: myproxy-ar
revision:
- '1'


## Crear bucket en GCP 

```bash
gcloud storage buckets create gs://claup-apigee-hybrid-desa --project=claup-apigee-hybrid-desa --default-storage-class=STANDARD --location=us-central1 --uniform-bucket-level-access
--soft-delete-duration=30d --encryption-enforcement-file=Estándar
```

## Borrar bucket GCP 

```bash
gcloud storage rm --recursive gs://claup-apigee-hybrid-desa
```

## Copiar archivo local en un bucket de GCP 

```bash
gcloud storage cp gs://gcp-external-http-lb-with-bucket/three-cats.jpg gs://claro-apigee-hybrid-desa/never-fetch/
```

## Otras opciones de gcloud storage 


Available groups for gcloud storage:

  batch-operations        Manage Cloud Storage batch operations.
  buckets                 Manage Cloud Storage buckets.
  folders                 Manage Cloud Storage folders.
  hmac                    Manage Cloud Storage service account HMAC keys.
  insights                Manage Cloud Storage inventory reports.
  intelligence-configs    Manage Cloud Storage Intelligence Configurations.
  intelligence-findings   Findings for Cloud Storage usage.
  managed-folders         Manage Cloud Storage managed folders.
  objects                 Manage Cloud Storage objects.
  operations              x|.

Available commands for gcloud storage:

   cat                     Outputs the contents of one or more URLs to
                             stdout.
   diagnose                Diagnose Google Cloud Storage.
   du                      Displays the amount of space in bytes used by
                              storage resources.
   hash                    Calculates hashes on local or cloud files.
   ls                      List Cloud Storage buckets and objects.
   mv                      Moves or renames objects.
   restore                 Restore one or more soft-deleted objects.
   rm                      Delete objects and buckets.
   rsync                   Synchronize content of two buckets/directories.
   service-agent           Manage a project's Cloud Storage service agent,
                              which is used to perform Cloud KMS operations.
   sign-url                Generate a URL with embedded authentication that
                              can be used by anyone.


## Exportar envs y grupos de envs

### Envs

En powershell:

```bash
$TOKEN = (gcloud auth print-access-token)
$ORG = "claup-apigee-hybrid-desa"

Invoke-RestMethod -Uri "https://apigee.googleapis.com/v1/organizations/$ORG/envgroups" `
  -Headers @{ Authorization = "Bearer $TOKEN" } | `
  ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 environment_groups.json
```

Resutado:

{
  "environmentGroups": [
    {
      "name": "claro-desa-test-ar-group",
      "hostnames": [
        "apigee-desa-test.claro.com.ar",
        "apigee-desa-test-ar.apps.oseinfrait01.claro.amx"
      ],
      "createdAt": "1783539002256",
      "lastModifiedAt": "1783974220167",
      "state": "ACTIVE"
    },
    {
      "name": "claro-desa-test-py-group",
      "hostnames": [
        "apigee-desa-test.claro.com.py",
        "apigee-desa-test-py.apps.oseinfrait01.claro.amx"
      ],
      "createdAt": "1783539115969",
      "lastModifiedAt": "1783539115969",
      "state": "ACTIVE"
    },
    {
      "name": "claro-desa-test-uy-group",
      "hostnames": [
        "apigee-desa-test.claro.com.uy",
        "apigee-desa-test-uy.apps.oseinfrait01.claro.amx"
      ],
      "createdAt": "1783539058759",
      "lastModifiedAt": "1783539058759",
      "state": "ACTIVE"
    }
  ]
}


## Asignar iam policy para error con pubsub.publisher (afecta analíticas)

```bash
gcloud projects add-iam-policy-binding claup-apigee-hybrid-desa \
    --member="serviceAccount:apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com" \
    --role="roles/pubsub.publisher"
```

Asigna el permiso a todos los roles de usuarios creados 

	resultado:

Updated IAM policy for project [claup-apigee-hybrid-desa].

bindings:

- members:

  - serviceAccount:apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com

  - user:ddiomede@claro.com.ar

  role: roles/apigee.analyticsAgent

- members:

  - serviceAccount:service-1010788170711@gcp-sa-apigee.iam.gserviceaccount.com

  role: roles/apigee.coreServiceAgent

- members:

  - serviceAccount:apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com

  - user:ddiomede@claro.com.ar

  role: roles/apigee.runtimeAgent

- members:

  - serviceAccount:apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com

  - serviceAccount:service-1010788170711@gcp-sa-apigee.iam.gserviceaccount.com

  - user:iam-admin-claro@claro.com.ar

  role: roles/apigee.spaceConsoleUser

- members:

  - serviceAccount:apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com

  role: roles/apigee.synchronizerManager

- members:

  - serviceAccount:apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com

  role: roles/apigeeconnect.Agent

- members:

  - serviceAccount:service-1010788170711@gcp-sa-cloudaicompanion.iam.gserviceaccount.com

  role: roles/cloudaicompanion.serviceAgent

- members:

  - serviceAccount:service-1010788170711@gcp-sa-cloudasset.iam.gserviceaccount.com

  role: roles/cloudasset.serviceAgent

- members:

  - serviceAccount:1010788170711@cloudservices.gserviceaccount.com

  role: roles/compute.instanceGroupManagerServiceAgent

- members:

  - serviceAccount:service-1010788170711@compute-system.iam.gserviceaccount.com

  role: roles/compute.serviceAgent

- members:

  - serviceAccount:service-1010788170711@container-engine-robot.iam.gserviceaccount.com

  role: roles/container.serviceAgent

- members:

  - serviceAccount:service-1010788170711@containerregistry.iam.gserviceaccount.com

  role: roles/containerregistry.ServiceAgent

- members:

  - serviceAccount:service-1010788170711@cloud-filer.iam.gserviceaccount.com

  role: roles/file.serviceAgent

- members:

  - serviceAccount:apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com

  role: roles/logging.logWriter

- members:

  - serviceAccount:apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com

  role: roles/monitoring.metricWriter

- members:

  - user:ddiomede@claro.com.ar

  - user:emmanuel.quiroga@claro.com.ar

  - user:ignacio.bellucci@claro.com.ar

  - user:jose.bisconti@claro.com.ar

  role: roles/owner

- members:

  - serviceAccount:apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com

  role: roles/pubsub.publisher

- members:

  - serviceAccount:service-1010788170711@gcp-sa-pubsub.iam.gserviceaccount.com

  role: roles/pubsub.serviceAgent

- members:

  - serviceAccount:apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com

  role: roles/pubsub.subscriber

- members:

  - user:ddiomede@claro.com.ar

  - user:emmanuel.quiroga@claro.com.ar

  - user:ignacio.bellucci@claro.com.ar

  - user:jose.bisconti@claro.com.ar

  role: roles/serviceusage.serviceUsageConsumer

- members:

  - serviceAccount:apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com

  role: roles/serviceusage.serviceUsageViewer

- members:

  - serviceAccount:apigee-non-prod@claup-apigee-hybrid-desa.iam.gserviceaccount.com

  role: roles/storage.objectAdmin

etag: BwZafwXbdxQ=

version: 1 



