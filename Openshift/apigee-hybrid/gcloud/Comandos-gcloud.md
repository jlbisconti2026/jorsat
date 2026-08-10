#  gcloud CLI & Apigee Hybrid

Guía rápida de comandos de `gcloud` para la administración de proyectos, API Proxies, Buckets de Storage y exportación de configuraciones mediante la API de Apigee.

---

## 1. Autenticación e Inicialización

### Login de gcloud a GCP
> **Nota:** La validación se realiza mediante la cuenta de Active Directory (AD) de Claro con Google.

```bash
gcloud auth login
```

## 2.Habilitar APIs de Google requeridas
```bash
gcloud services enable pubsub.googleapis.com --project="project-id"
gcloud services enable cloudresourcemanager.googleapis.com --project="project-id"
gcloud services enable apigee.googleapis.com --project="project-id"
gcloud services enable apigeeconnect.googleapis.com --project="project-id"
gcloud services enable container.googleapis.com --project="project-id"
```
## 3. Gestión de Proyectos en GCP
### Crear proyecto
```bash
gcloud projects create [PROJECT_ID_O_NOMBRE]
```

### Borrar proyecto
```bash
gcloud projects delete [PROJECT_ID_O_NOMBRE]
```

### Recuperar proyecto borrado

```bash
gcloud projects undelete [PROJECT_ID_O_NOMBRE]
```

### Renombrar / Actualizar proyecto

```bash
gcloud projects update [PROJECT_ID_O_NOMBRE]
```

### Listar proyectos GCP
```bash
gcloud projects list
```

### Filtrar proyectos de Apigee:
```bash
gcloud projects list | grep apigee
```



Ejemplo de salida:

 
claup-apigee-hybrid-desa    claup-apigee-hybrid-desa    1010788170711
claup-apigee-hybrid-prod    claup-apigee-hybrid-prod    300430456458
 

### Cambiar de proyecto activo

```bash
gcloud config set project nombre-del-projecto
```

### Cambiar la región o zona por defecto

```bash
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

## 4. Administración de Apigee

Listar organizaciones disponibles:
```bash
gcloud apigee organizations list
```

Ejemplo de salida:

NAME                      PROJECT
claup-apigee-hybrid-desa  claup-apigee-hybrid-desa
claup-apigee-hybrid-prod  claup-apigee-hybrid-prod

## Listar Entornos (Environments) creados

```bash
gcloud apigee environments list
```

Salida:

desa-ar

desa-py

desa-uy

test-ar

test-py

test-uy

### Listar API Proxies

```bash
gcloud apigee apis list
```

Salida:

AUP_Proxy_Prueba_DD

myproxy-ar

myproxy-py

myproxy-uy

## Listar Deployments de los Proxies

```bash
gcloud apigee deployments list
```
Ejemplo de salida:

Plaintext
ENVIRONMENT  API_PROXY   REVISION
test-ar      myproxy-ar  1
test-py      myproxy-py  1
test-uy      myproxy-uy  1
desa-ar      myproxy-ar  1
desa-py      myproxy-py  1
desa-uy      myproxy-uy  1

### Desplegar / Importar API Proxies
A partir de un archivo .zip (exportado de otro Apigee):

```bash
gcloud apigee apis deploy \
  --organization=claup-apigee-hybrid-prod \
  --environment=prod-ar \
  --api=mi-api-exportada \
  --file=.\mi-api-v1.zip \
  --override
```

### A partir de una carpeta local:

```bash
gcloud apigee apis deploy \
  --organization=claup-apigee-hybrid-desa \
  --environment=desa-ar \
  --api=mi-api \
  --file=.\ruta\a\mi-carpeta-proxy \
  --override
```

### Quitar / Desactivar (Undeploy) un Proxy de un entorno

```bash
  gcloud apigee apis undeploy \
  --organization=claup-apigee-hybrid-desa \
  --environment=desa-ar \
  --api=nombre-del-proxy
```

### Obtener detalles e información de un Proxy
```bash
gcloud apigee apis describe myproxy-ar
```

Ejemplo de salida:

apiProxyType: PROGRAMMABLE
latestRevisionId: '1'
metaData:
  createdAt: '1783542114388'
  lastModifiedAt: '1783542114388'
  subType: Proxy
name: myproxy-ar
revision:
- '1'

  ## 5. Gestión de Google Cloud Storage (gcloud storage)

### Crear un Bucket

```bash
gcloud storage buckets create gs://nombre-bucket \
  --project=Projetct-id \
  --default-storage-class=STANDARD \
  --location=us-central1 \
  --uniform-bucket-level-access \
  --soft-delete-duration=30d
  ```

### Borrar un Bucket

```bash
gcloud storage rm --recursive gs://nombre-bucket
```

### Copiar archivos a un Bucket
```bash
gcloud storage cp gs://gcp-external-http-lb-with-bucket/three-cats.jpg gs://nombre-bucket/never-fetch/
```

## 6. Exportación de Entornos y Grupos vía API (PowerShell)
### Exportar Environment Groups

```bash
$TOKEN = (gcloud auth print-access-token)$ORG = "apigee-org"

Invoke-RestMethod -Uri "[https://apigee.googleapis.com/v1/organizations/$ORG/envgroups](https://apigee.googleapis.com/v1/organizations/$ORG/envgroups)" `
  -Headers @{ Authorization = "Bearer $TOKEN" } | `
  ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 environment_groups.json
```

### Exportar Attachments de un Environment Group

```bash
$TOKEN = (gcloud auth print-access-token)$ORG = "apigee-org"
$GROUP = "apigee-group"

Invoke-RestMethod -Uri "[https://apigee.googleapis.com/v1/organizations/$ORG/envgroups/$GROUP/attachments](https://apigee.googleapis.com/v1/organizations/$ORG/envgroups/$GROUP/attachments)" `
  -Headers @{ Authorization = "Bearer $TOKEN" } | `
  ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 envgroup_attachments.json
```

## 7. Gestión de IAM y Cuentas de Servicio (Service Accounts)

Apigee Hybrid requiere múltiples Service Accounts y roles específicos para funcionar.

Listar Service Accounts del proyecto

```bash
gcloud iam service-accounts list --project=project-name 
```

### Crear una Service Account
```bash
gcloud iam service-accounts create apigee-telemetry-sa \
  --display-name="Service Account para Apigee Telemetry" \
  --project=project-name 
```

### Asignar un rol de IAM a una Service Account

```bash
gcloud projects add-iam-policy-binding claup-apigee-hybrid-desa \
  --member="serviceAccount:apigee-telemetry-sa@claup-apigee-hybrid-desa.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"
```

### Exportar proyectos y permisos a formato de terraform

gcloud beta resource-config bulk-export --path=.\backup_terraform-desa --project=claup-apigee-hybrid-desa --resource-format=terraform

gcloud beta resource-config bulk-export --path=.\backup_terraform-prod --project=claup-apigee-hybrid-prod --resource-format=terraform

#### Pasos importar proyecto y permisos en nueva cuenta GCP

login en la cuenta nueva:
gcloud auth login (Para poder usar comandos gcloud)

gcloud auth application-default login (Clave para Terraform)

cd .\backup_terraform_desa

terraform init

terraform apply

#### Entorno Prod

cd .\backup_terraform_prod

terraform init

terraform apply

