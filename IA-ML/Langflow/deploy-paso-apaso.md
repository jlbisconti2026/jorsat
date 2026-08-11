# Guía de Instalación de Langflow en Red Hat OpenShift 4.21

Esta guía proporciona las instrucciones paso a paso para desplegar **Langflow** en un clúster de **Red Hat OpenShift 4.21** utilizando manifiestos nativos de Kubernetes/OpenShift y la CLI (`oc`).

---x|

## Índice

1. [Prerrequisitos](#1-prerrequisitos)
2. [Paso 1: Crear el Proyecto en OpenShift](#paso-1-crear-el-proyecto-en-openshift)
3. [Paso 2: Crear el Almacenamiento Persistente (PVC)](#paso-2-crear-el-almacenamiento-persistente-pvc)
4. [Paso 3: Definir el Despliegue (Deployment)](#paso-3-definir-el-despliegue-deployment)
5. [Paso 4: Crear el Servicio (Service)](#paso-4-crear-el-servicio-service)
6. [Paso 5: Exponer la Aplicación (Route)](#paso-5-exponer-la-aplicación-route)
7. [Paso 6: Aplicar Configuración y Verificación](#paso-6-aplicar-configuración-y-verificación)

---

## 1. Prerrequisitos

* Acceso a un clúster de **OpenShift 4.21** con permisos para crear recursos (`Project`, `Deployment`, `PVC`, `Route`).
* La herramienta de línea de comandos **`oc`** instalada y configurada (`oc login`).
* `StorageClass` por defecto configurada en el clúster.

---

## Paso 1: Crear el Proyecto en OpenShift

Primero, crea un namespace/proyecto dedicado para aislar los recursos de Langflow.

```bash
oc new-project langflow --display-name="Langflow AI Engine"
```

## Paso 2: Crear el Almacenamiento Persistente (PVC)

Langflow utiliza una base de datos local (por defecto SQLite) y un directorio para guardar flujos y componentes. Guardaremos esto en un PersistentVolumeClaim.

Crea un archivo llamado 01-pvc.yaml:

```yaml
    apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: langflow-pvc
  namespace: langflow
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
      
```

## Paso 3: Definir el Despliegue (Deployment)

OpenShift asigna UIDs aleatorios por temas de seguridad (SecurityContextConstraints / SCC restricted-v2). La imagen oficial de Langflow soporta ejecutarse como usuario no-root.

Crea un archivo llamado 02-deployment.yaml:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: langflow
  namespace: langflow
  labels:
    app: langflow
spec:
  replicas: 1
  selector:
    matchLabels:
      app: langflow
  template:
    metadata:
      labels:
        app: langflow
    spec:
      containers:
        - name: langflow
          image: langflowai/langflow:latest
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 7860
              name: http
          env:
            - name: LANGFLOW_HOST
              value: "0.0.0.0"
            - name: LANGFLOW_PORT
              value: "7860"
            - name: LANGFLOW_DATABASE_URL
              value: "sqlite:////app/langflow/langflow.db"
          volumeMounts:
            - name: langflow-data
              mountPath: /app/langflow
          resources:
            limits:
              cpu: "2"
              memory: 4Gi
            requests:
              cpu: "500m"
              memory: 1Gi
      volumes:
        - name: langflow-data
          persistentVolumeClaim:
            claimName: langflow-pvc
 ```

## Paso 4: Crear el Servicio (Service)

El servicio permite la comunicación interna entre pods en el clúster.

Crea un archivo llamado 03-service.yaml:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: langflow-service
  namespace: langflow
  labels:
    app: langflow
spec:
  type: ClusterIP
  ports:
    - port: 7860
      targetPort: 7860
      protocol: TCP
      name: http
  selector:
    app: langflow
```

## Paso 5: Exponer la Aplicación (Route)

En OpenShift, para exponer el servicio al exterior se utiliza un objeto nativo llamado Route.

Crea un archivo llamado 04-route.yaml:

 ```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: langflow-route
  namespace: langflow
  labels:
    app: langflow
spec:
  to:
    kind: Service
    name: langflow-service
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
 ```

## Paso 6: Aplicar Configuración y Verificación

1. Aplicar todos los manifiestos YAML:

```bash
oc apply -f 01-pvc.yaml
oc apply -f 02-deployment.yaml
oc apply -f 03-service.yaml
oc apply -f 04-route.yaml
```

1. Verificar que el Pod esté en estado Running:

```bash
oc get pods -n langflow -w
```

1. Obtener la URL pública de la aplicación:

```bash
oc get route langflow-route -n langflow -o jsonpath='{.spec.host}'
```

1. Abre la URL generada en tu navegador web para ingresar a la interfaz visual de Langflow.
