|DEDPLOY DE LANGFLOW CON DB EXTERNA EN LABOKDIPI|
| Índice | Página |
| :--- | :---: |
| **[Introducción](#introducción)** | 2 |
| **[Deploy de Langflow](#deploy-de-langflow)** | 2 |
|   • [Paso 1](#paso-1) | 2 |
|   • [Paso 2](#paso-2) | 2 |
|   • [Paso 3](#paso-3) | 3 |
| **[Deploy de DB PostgreSQL](#deploy-de-db-postgresql)** | 3 |
| **[Aplicar capacidad vector a la DB PostgreSQL](#aplicar-capacidad-vectorial-a-la-db-postgresql)** | 4 |
| **[Verificaciones finales en la DB](#verificaciones-finales-en-la-db)** | 5 |
| **[Corroborar escritura de Langflow en la DB](#corroborar-escritura-de-langflow-en-la-db)** | 7 |s

1 

DEDPLOY DE LANGFLOW CON DB EXTERNA EN LABOKDIPI 

# Introducción 

Este documento tiene como objeto detallar el deploy de la plataforma Langflow  y de la db postgresql sobre OKD/Openshift recomendada por la doc oficial. 

## Deploy de Langflow 

### Paso 1 

Necesitamos crear el archivo values.yaml necesario para el deploy. Nuestro archivo va a tener el siguiente contenido: 

```yaml
langflow: 
  backend: 
    autoLogin: false
    
env: 
  - name: LANGFLOW_SUPERUSER_PASSWORD
    value: "claro123" 
  - name: LANGFLOW_DATABASE_URL 
    value: "postgresql://langflow_user:claro123@postgres:5432/langflow_db" 
  - name: PGVECTOR_CONNECTION_STRING 
    value: "postgresql://langflow_user:claro123@postgres:5432/langflow_db" 
```

### Paso 2 

Ahora  el deploy mediante Helm con los siguientes comandos: 

Agregamos el repositorio Helm de Langflow: 

```bash
helm repo add langflow https://langflow-ai.github.io/langflow-helm-charts --force-update 
```

Actualizamos la lista de repositorios: 

```bash
helm repo update 
```

Creamos el namespace Langflow y lo deployamos: 
```bash
helm install my-langflow-app-with-flow langflow/langflow-runtime   -n langflow   --create-namespace \ 
```

2 

DEDPLOY DE LANGFLOW CON DB EXTERNA EN LABOKDIPI 

Paso 3 

Verificamos   la creación de los charts de Helm: 

```bash
helm list 
```
```
NAME                            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
my-langflow                     langflow        1               2026-10-21 16:46:35.197814483 -0300 -03 deployed        langflow-ide-0.1.2      latest
my-langflow-app-with-flow       langflow        1               2026-10-21 16:03:38.726767224 -0300 -03 deployed        langflow-runtime-0.1.1  latest
```


También verificamos el status de los pods de Langflow: 

```bash
oc get pods -n langflow
```

```
NAME                                         READY   STATUS    RESTARTS   AGE
langflow-service-0                           1/1     Running   0          4h26m
langflow-service-frontend-86f58dbc84-b7wfv   1/1     Running   0          4h38m
```


## Deploy de db postgresql 

Comenzamos por la creación del archivo de deployment de el pod de postgresql con siguiente contenido: 


DEDPLOY DE LANGFLOW CON DB EXTERNA EN LABOKDIPI 

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: langflow
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: langflow
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: pgvector/pgvector:pg15
          env:
            - name: POSTGRES_DB
              value: langflow_db
            - name: POSTGRES_USER
              value: langflow_user
            - name: POSTGRES_PASSWORD
              value: claro123
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          ports:
            - containerPort: 5432
          volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: postgres-storage
      volumes:
        - name: postgres-storage
          persistentVolumeClaim:
            claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: langflow
spec:
  ports:
    - port: 5432
      targetPort: 5432
  selector:
    app: postgres
```

Aplicamos el yaml con el comando: 

oc apply -f deployment-postgresql.yaml 

Volvemos a chequear el status de los pods del namespace Langflow para ver el status del nuevo pod de postgresql: 

```bash
oc get po -n langflow
```

```
NAME                                         READY   STATUS    RESTARTS   AGE
langflow-service-0                           1/1     Running   0          4h31m
langflow-service-frontend-86f58dbc84-b7wfv   1/1     Running   0          4h43m
postgres-6f55d66645-9qjt4                    1/1     Running   0          5h1m
```

## Aplicar capacidad vector a la db postgresql 

A continuacion vamos a la capacidad vectorial en PostgreSQL que Langflow necesita con el comando: 


```bash
oc exec -it deployment/postgres -n langflow -- psql -U langflow_user -d langflow_db -c "CREATE EXTENSION IF NOT EXISTS vector;" 
```



## DEDPLOY DE LANGFLOW CON DB EXTERNA EN LABOKDIPI 

Verificaciones finales en la db 

Verificamos el status de la db, a saber tablas necesarias para Langflow y escritura en la db. 

Para verificar que tengamos las tablas necesarias ejecutamos el comando: 
```bash
oc exec -it deployment/postgres -n langflow -- psql -U langflow_user -d langflow_db 
```
Una vez dentro de la vm ejecutamos el comando: 

```bash
\dt 
```
A  continuacion la lista de tablas creadas en Langflow_db 

```mermaid
classDiagram
    direction LR
    namespace public {
        class a2a_checkpoints {
            table langflow_user
        }
        class a2a_tasks {
            table langflow_user
        }
        class alembic_version {
            table langflow_user
        }
        class apikey {
            table langflow_user
        }
        class authz_audit_log {
            table langflow_user
        }
        class authz_edit_lock {
            table langflow_user
        }
        class authz_role {
            table langflow_user
        }
        class authz_role_assignment {
            table langflow_user
        }
        class authz_role_assignment_grant {
            table langflow_user
        }
        class authz_share {
            table langflow_user
        }
        class authz_team {
            table langflow_user
        }
        class authz_team_member {
            table langflow_user
        }
        class casbin_rule {
            table langflow_user
        }
        class catalog_policy_rule {
            table langflow_user
        }
        class deployment {
            table langflow_user
        }
        class deployment_provider_account {
            table langflow_user
        }
        class execution_signals {
            table langflow_user
        }
        class file {
            table langflow_user
        }
        class flow {
            table langflow_user
        }
        class flow_version {
            table langflow_user
        }
        class flow_version_deployment_attachment {
            table langflow_user
        }
        class folder {
            table langflow_user
        }
        class ingestion_run {
            table langflow_user
        }
        class job {
            table langflow_user
        }
        class job_checkpoints {
            table langflow_user
        }
        class job_events {
            table langflow_user
        }
        class knowledge_base {
            table langflow_user
        }
        class mcp_server {
            table langflow_user
        }
        class memory_base {
            table langflow_user
        }
        class memory_base_preprocessing_output {
            table langflow_user
        }
        class memory_base_session {
            table langflow_user
        }
        class memory_base_workflow_run {
            table langflow_user
        }
        class message {
            table langflow_user
        }
        class message_ingestion_record {
            table langflow_user
        }
        class model_provider_policy {
            table langflow_user
        }
        class policy_bundle_active {
            table langflow_user
        }
        class policy_bundle_revision {
            table langflow_user
        }
        class span {
            table langflow_user
        }
    }
```
## DEDPLOY DE LANGFLOW CON DB EXTERNA EN LABOKDIPI 



<!-- Start of picture text -->
List of relations<br>Schema | Name | Type | Owner<br>ee<br>public | a2a_checkpoints | table | langflow_user<br>public | a2a_tasks | table | langflow_user<br>public | alembic_version | table | langflow_user<br>public | apikey | table | langflow_user<br>public | authz_audit_log | table | langflow_user<br>public | authz_edit_lock | table | Langflow_user<br>public | authz_role | table | langflow_user<br>public | authz_role_assignment | table | langflow_user<br>public | authz_role_assignment_grant | table | langflow_user<br>public | authz_share | table | langflow_user<br>public | authz_team | table | langflow_user<br>public | authz_team_member | table | langflow_user<br>public | casbin_rule | table | langflow_user<br>public | catalog policy rule | table | langflow_user<br>public | deployment | table | langflow_user<br>public | deployment_provider_account | table | Langflow_user<br>public | execution_signals | table | langflow_user<br>public | file | table | langflow_user<br>public | flow | table | langflow_user<br>public | flow_version | table | langflow_user<br>public | flow_version_deployment_attachment | table | langflow_user<br>public | folder | table | langflow_user<br>public | ingestion_run | table | langflow_user<br>public | job | table | langflow_user<br>public | job_checkpoints | table | langflow_user<br>public | job_events | table | Langflow_user<br>public | knowledge _base | table | langflow_us#r<br>public | mcp_server | table | langflow_user<br>public | memory base | table | langflow_user<br>public | memory_base_preprocessing_output | table | langflow_user<br>public | memory _base_session | table | Langflow_user<br>public | memory base _workflow_run | table | langflow_user<br>public | message | table | langflow_user<br>public | message_ingestion_record | table | langflow_user<br>public | model_provider_policy | table | langflow_user<br>public | policy_bundle_active | table | langflow_user<br>public | policy bundle_revision | table | langflow_user<br>public | span | table | langflow_user<br><!-- End of picture text -->

#### <mark>Nota:</mark> 

<mark>En caso de que las tablas no estén creadas forzar la inicialización con el comando:</mark> 

oc <mark>exec -it pod/langf</mark> l <mark>ow-service</mark> -0 <mark>-n langfow</mark> l - <mark>- langf</mark> l <mark>ow migration upgrade</mark> 

<mark>Este comando  al proceso dentro del pod del backend (langfow-service-0) a conectarse a</mark> l <mark>la base de datos externa especif</mark> i <mark>cada en LANGFLOW_DATABASE_URL y aplicar todas las revisiones pendientes.</mark> 


## DEDPLOY DE LANGFLOW CON DB EXTERNA EN LABOKDIPI 

**<mark>Crea las tablas faltantes</mark>** <mark>: Genera de golpe todo el esquema relacional y el soporte para pgvector en la base de datos sin depender de que el arranque automático lo dispare.</mark> 

### Corroborar escritura de Langflow en la db 

A continuacion vamos a crear un flujo de prueba en Langflow llamado test1 para poder verificar que la aplicación escribe en la db. 

Para realizar esta prueba ingresamos en la gui de Langflow : 



<!-- Start of picture text -->
«oe D)% lrafow lacfionapps labokdp dro aml a 4 ea Sune:<br>% ) o r)<br>=n<br><!-- End of picture text -->

Una vez dentro  presionamos el botón New Flow y  creamos test1: 



<!-- Start of picture text -->
Let us set things up first<br><!-- End of picture text -->

7 



<!-- Start of picture text -->
DEDPLOY DE LANGFLOW CON DB EXTERNA EN LABOKDIPI<br><!-- End of picture text -->



<!-- Start of picture text -->
Mode proviers x<br>Azure Al Foundry<br>JM Watson<br>Openal<br>DpenRouter<br>Dw<br><!-- End of picture text -->



<!-- Start of picture text -->
coe DD) < nation inom appslaolcipicro ama lon! 420961 7496-Aade Sb eSicdtl162/okde 405050bIOL Aa 85d. ao WA<br>BBC Aigce 2 Apigee Hybrid 5) Uris tecnicas general (] Piataformastest>p... [2] intra Claro [ kubetlow [2] OCP/OPKD-docs: DesinstataEdge | EC] MLODHetc Cis) NON<br>Mode! rovers ;<br>[ag | GoogieAPI Key<br>ogen<br><!-- End of picture text -->

Colocamos la Apikey generada en la pagina de Gemini 

8 



<!-- Start of picture text -->
DEDPLOY DE LANGFLOW CON DB EXTERNA EN LABOKDIPI<br><!-- End of picture text -->



<!-- Start of picture text -->
Model providers x<br>9 Google API Key<br>Language Model<br><!-- End of picture text -->

Le damos el nombre test1 al Flow: 



<!-- Start of picture text -->
Flow Details x<br>Name<br>| testi |<br>Description<br>Crafting Conversations, One Node at a Time.<br>I<br>Lock Flow ©<br>Coe<br><!-- End of picture text -->

9 



<!-- Start of picture text -->
DEDPLOY DE LANGFLOW CON DB EXTERNA EN LABOKDIPI<br><!-- End of picture text -->



<!-- Start of picture text -->
2 Onm = e<br>=a<br><!-- End of picture text -->

#### Volvemos a ingresar a la db con el comando: 

oc exec -it deployment/postgres -n langflow -- psql -U langflow_user -d langflow_db 

#### Ejecutamos la query: 

SELECT id, name, updated_at FROM "flow"; 

#### Y obtenemos el siguiente resultado: 



<!-- Start of picture text -->
langflow db=# SELECTid id, name, updatedI at FROM "flow"; name | updated_at<br>381828a4-cOd1-4b5f-afbf-dda71140cafc | Basic Prompting | 2026-10-27 14:48:58<br>800d195d-de12-4072-a8c2-cf20496a1e2b | Blog Writer | 2026-10-27 14:48:58<br>8b38593b-2a85-4cd7-af79-b4ba91da9631 | Content Aggregator | 2026-10-27 14:48:58<br>ceb246c7-bbf6-4704-925a-aa704cd92159 | Custom Component Generator | 2026-10-27 14:48:58<br>6a066f01-fc02-4c56-bf32-1c12ed5b9f93 | Deep Research Agent | 2026-10-27 14:48:58<br>dc¥35a2e-3b32-4cfe-a91b-122393cc9428 | Document Q&A | 2026-10-27 14:48:58<br>cd88299-8e59-4eb7-8812-1d9de70465bb | Financial Report Parser | 2026-10-27 14:48:58<br>3309831e-1c7f-4931-bea4-ca6c506b960e | Hybrid Search RAG | 2026-10-27 14:48:58<br>7a3065a6-2ba5-45a4-be8c-62bba3bac30d | Image Sentiment Analysis | 2026-10-27 14:48:58<br>cf2474c1-707-4d31-8dda-54bebd435fd3 | Instagram Copywriter | 2026-10-27 14:48:58<br>3b3#46a3-5051-4dd6-9902-ceeb92be15c0 | Knowledge Retrieval | 2026-10-27 14:48:58<br>0485cb5f-7a86-4427-a079-dbOaaa755be0 | Market Research | 2026-10-27 14:48:58<br>a9959c78-cf38-450e-a17e-9d6567421a43 | Meeting Summary | 2026-10-27 14:48:58<br>b681b22F-e529-44bd-8471-a9f9dafo923d | Memory Chatbot | 2026-10-27 14:48:58<br>7d152f13-0c67-478f-b620-aadeSddbfdf5 | Multi Agent Flow | 2026-10-27 14:48:58<br>ac86b796-f10d-4a61-811d-f400a6ecaa6a | Portfolio Website Code Generator | 2026-10-27 14:48:58<br>3785badc-643a-44a4-8117-b71cdeddd44a | Price Deal Finder | 2026-10-27 14:48:58<br>bdfe0750-3e64-4b89-89c2-87cbe57a381f | SEO Keyword Generator | 2026-10-27 14:48:59<br>acbf7812-28dd-418e-994c-a1222434f96e | SaaS Pricing | 2026-10-27 14:48:59<br>4bfc207c- fbb8-499c -bc9b-2e65ba36b39e | Sequential Tasks Agents | 2026-10-27 14:48:59<br>a2a5169e-c3a8-47bd-be53-afa8b3d24432 | Simple Agent | 2026-10-27 14:48:59<br>9f fe24e3-a25b-439d-974a-383f1e3fc006 | Social Media Agent | 2026-10-27 14:48:59<br>4456 fceb-e0d5-4e69-9208-d1823f266513 | Text Sentiment Analysis | 2026-10-27 14:48:59<br>cbadd803-ca12-465d-ba31-7ceeb4943315 | Travel Planning Agents | 2026-10-27 14:48:59<br>0f3c6448-a67c-4199-a2ec-4317295d777 | Twitter Thread Generator | 2026-10-27 14:48:59<br>343d65bc-22a8-4333-bdf2-fe49c951d9d6 | Vector Store RAG | 2026-10-27 14:48:59<br>d046ec5e-edd2-4b67-b1c6-e91c89F6F199si—-Ssupb0ef1a90-87c1-4749-878c-ae6255aicce) | testitS“AGENT || 2026-10-272026-10-27 17:38:22.19530614:51:52.819748<br>(28 rows)<br><!-- End of picture text -->

10 

