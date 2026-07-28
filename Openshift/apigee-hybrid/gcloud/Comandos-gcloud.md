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
gcloud services enable pubsub.googleapis.com --project="claup-apigee-hybrid-desa"
gcloud services enable cloudresourcemanager.googleapis.com --project="claup-apigee-hybrid-desa"
gcloud services enable apigee.googleapis.com --project="claup-apigee-hybrid-desa"
gcloud services enable apigeeconnect.googleapis.com --project="claup-apigee-hybrid-desa"
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
 

## 4. Administración de Apigee

Listar organizaciones disponibles:
```bash
gcloud apigee organizations list
```

Ejemplo de salida:

Plaintext
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


