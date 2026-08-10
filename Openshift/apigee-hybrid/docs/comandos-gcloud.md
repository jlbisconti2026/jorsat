
# Comandos gcloud
 
### Login de gcloud a GCP

gcloud auth login

Tiene validación con gcloud mediante la cuenta de AD de claro con google

#### Crear proyectos

gcloud projects create  [PROJECT_ID o nombre]

#### Borrar proYectos

gcloud projects delete  [PROJECT_ID o nombre]

#### Recuperar proyecto borrado

gcloud projects undelete  [PROJECT_ID o nombre]

### Renombrar proyectos

 gcloud projects update [PROJECT_ID o nombre]

### Listar lista de proyectos GCP

 gcloud projects list

gcloud projects list | grep apigee
claup-apigee-hybrid-desa    claup-apigee-hybrid-desa    1010788170711
claup-apigee-hybrid-prod    claup-apigee-hybrid-prod    300430456458

### Listar organizaciones dispnibles

gcloud apigee organizations list

Resultado:

PS C:\Users\CTI24114> gcloud apigee organizations list
NAME                      PROJECT
claup-apigee-hybrid-desa  claup-apigee-hybrid-desa
claup-apigee-hybrid-prod  claup-apigee-hybrid-prod

### Listar envs creados

  gcloud apigee environments list

 - desa-ar
 - desa-py
 - desa-uy
 - test-ar
 - test-py
 - test-uy

#### Listar api proxies

Comando:

 gcloud apigee apis list

 - AUP_Proxy_Prueba_DD
 - myproxy-ar
 - myproxy-py
 - myproxy-uy

### Listar deployments de los proxies

gcloud apigee deployments list
ENVIRONMENT  API_PROXY   REVISION
test-ar      myproxy-ar  1
test-py      myproxy-py  1
test-uy      myproxy-uy  1
desa-ar      myproxy-ar  1
desa-py      myproxy-py  1
desa-uy      myproxy-uy  1

### Crear api proxies a partir de archivo exportado de otro apigee

### Importa y despliega directamente el zip exportado

gcloud apigee apis deploy --organization=claup-apigee-hybrid-prod --environment=prod-ar --api=mi-api-exportada --file=.\mi-api-v1.zip --override

### Crear api proxies a partir de carpeta local

gcloud apigee apis deploy --organization=claup-apigee-hybrid-desa --environment=desa-ar --api=mi-api --file=.\ruta\a\mi-carpeta-proxy --override


### Quitar/desactivar proxy de un entorno  

gcloud apigee apis undeploy  --organization=claup-apigee-hybrid-desa   --environment=desa-ar   --api=nombre-del-proxy

### Obtener información de un proxy


 gcloud apigee apis describe myproxy-ar
apiProxyType: PROGRAMMABLE
latestRevisionId: '1'
metaData:
  createdAt: '1783542114388'
  lastModifiedAt: '1783542114388'
  subType: Proxy
name: myproxy-ar
revision:
- '1'


### Crear bucket en GCP

gcloud storage buckets create gs://claup-apigee-hybrid-desa --project=claup-apigee-hybrid-desa --default-storage-class=STANDARD --location=us-central1 --uniform-bucket-level-access
--soft-delete-duration=30d --encryption-enforcement-file=Estándar

### Borrar bucket GCP

gcloud storage rm --recursive gs://claup-apigee-hybrid-desa

### Copiar archivo local en un bucket de GCP

gcloud storage cp gs://gcp-external-http-lb-with-bucket/three-cats.jpg gs://claro-apigee-hybrid-desa/never-fetch/

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
