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

## Setear key fernet 

La clave Fernet es una clave criptográfica maestra utilizada por el motor de seguridad de Langflow (basado en la librería simétrica Fernet de Python) para cifrar y descifrar de forma segura toda la información sensible que se almacena en la base de datos de PostgreSQL.

### Funciones principales
Protección de Credenciales y API Keys: Cifra los tokens de acceso, contraseñas y claves privadas de proveedores de modelos de lenguaje externos (como Google Gemini, OpenAI, Anthropic, etc.) antes de guardarlas en las tablas de la base de datos, evitando que queden expuestas en texto plano.

Firma de Tokens de Sesión (JWT): Valida la integridad de las sesiones de los usuarios y los tokens de autenticación web para garantizar que las peticiones hacia el backend provengan de sesiones legítimas y no hayan sido alteradas.

Integridad Criptográfica Estricta: Exige obligatoriamente una cadena exacta de 32 bytes codificada en base64 segura para URL (url-safe base64). Si la clave no cumple con este formato exacto o cambia de forma imprevista entre reinicios sin mantener un historial de respaldo, el sistema arroja errores de firma (InvalidSignatureError o Fernet key must be 32 bytes) y se bloquea el acceso a las credenciales cifradas previas.

Creamos la clave de Fernet necesaria para Langflow utilizando el siguiente comando:

```bash
python3 -c "from cryptography.fernet import Fernet; rint(Fernet.generate_key().decode())"
```
Inyección de la Clave y Credenciales en el Backend y Frontend: Dado que los servicios principales corrían bajo el StatefulSet y Deployments en OpenShift, se aplicó la inyección directa de las variables de entorno mediante comandos oc set env para forzar su actualización en memoria:


```bash
oc set env statefulset/langflow-service LANGFLOW_SECRET_KEY="zoadUmyBN47sTL-JGJ22WRceEJL6obsS5q1wBwNR_6U=" -n langflow
```

```bash
oc set env deployment/langflow-service-frontend LANGFLOW_SECRET_KEY="zoadUmyBN47sTL-JGJ22WRceEJL6obsS5q1wBwNR_6U=" -n langflow
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

```bash
oc apply -f deployment-postgresql.yaml 
```

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

![Listado de tablas](..x    /screenshots/query-tablas.png)


#### <mark>Nota:</mark> 

<mark>En caso de que las tablas no estén creadas forzar la inicialización con el comando:</mark> 

oc <mark>exec -it pod/langf</mark> l <mark>ow-service</mark> -0 <mark>-n langfow</mark> l - <mark>- langf</mark> l <mark>ow migration upgrade</mark> 

<mark>Este comando  al proceso dentro del pod del backend (langfow-service-0) a conectarse a</mark> l <mark>la base de datos externa especif</mark> i <mark>cada en LANGFLOW_DATABASE_URL y aplicar todas las revisiones pendientes.</mark> 


**<mark>Crea las tablas faltantes</mark>** <mark>: Genera de golpe todo el esquema relacional y el soporte para pgvector en la base de datos sin depender de que el arranque automático lo dispare.</mark> 

### Corroborar escritura de Langflow en la db 

A continuacion vamos a crear un flujo de prueba en Langflow llamado test1 para poder verificar que la aplicación escribe en la db. 

Para realizar esta prueba ingresamos en la gui de Langflow : 


![Gui langflow1](../screenshots/gui1.png)

Una vez dentro  presionamos el botón New Flow y  creamos test1: 

![Gui langflow1](../screenshots/gui-screen2.png)


![Gui langflow1](../screenshots/gui-model-providers.png)

![Gui langflow1](../screenshots/gui-api-key.png)


Colocamos la Apikey generada en la pagina de Gemini 

Le damos el nombre test1 al Flow: 

![Gui langflow1](../screenshots/gui-flow-details.png)

![Gui langflow1](../screenshots/flow-creado.png)

#### Volvemos a ingresar a la db con el comando: 

```bash
oc exec -it deployment/postgres -n langflow -- psql -U langflow_user -d langflow_db 
```

#### Ejecutamos la query: 

```bash
SELECT id, name, updated_at FROM "flow"; 
```

#### Y obtenemos el siguiente resultado: 


![Gui langflow1](../screenshots/query-flows-db.png)
