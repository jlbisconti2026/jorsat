# Guía de Despliegue de n8n en Red Hat OpenShift 4

Esta guía detalla el procedimiento paso a paso para desplegar **n8n** (workflow automation) en un cluster de OpenShift 4.21+. 

Incluye la creación del namespace, la asignación de permisos de seguridad (**Security Context Constraints - SCC**), la persistencia de datos mediante **PVC** y la exposición del servicio a través de un **Route** con TLS/HTTPS.

---

## Índice

1. [Prerrequisitos](#prerrequisitos)
2. [Paso 1: Crear el Namespace / Proyecto](#paso-1-crear-el-namespace--proyecto)
3. [Paso 2: Configurar la Cuenta de Servicio y SCC](#paso-2-configurar-la-cuenta-de-servicio-y-scc)
4. [Paso 3: Crear el PersistentVolumeClaim (PVC)](#paso-3-crear-el-persistentvolumeclaim-pvc)
5. [Paso 4: Desplegar n8n (Deployment)](#paso-4-desplegar-n8n-deployment)
6. [Paso 5: Crear el Service](#paso-5-crear-el-service)
7. [Opcional: Creacion de route en openshift](#opcional:-creacion-de-route-en-openshift)
8. [Paso 6: Exponer la Aplicación (Route con TLS)](#paso-6-exponer-la-aplicación-route-con-tls)
9. [Paso 7: Verificación del Despliegue](#paso-7-verificación-del-despliegue)

---

## Prerrequisitos

* Acceso a la CLI de OpenShift (`oc`).
* Permisos de administración en el cluster o capacidad para crear proyectos y modificar SCC.
* StorageClass con soporte de lectura/escritura (`ReadWriteOnce` o `ReadWriteMany`) configurada en el cluster.

---

## Paso 1: Crear el Namespace / Proyecto

Creamos un proyecto dedicado para aislar los recursos de n8n:

```bash
oc new-project n8n-automation --display-name="n8n Workflow Au
```

## Paso 2: Configurar la Cuenta de Servicio y SCC

n8n ejecuta su contenedor utilizando un usuario sin privilegios root, pero requiere permisos de sistema de archivos para escribir en su directorio /home/node/.n8n.

OpenShift bloquea por defecto los IDs de usuario arbitrarios. Asignamos el SCC anyuid a la ServiceAccount por defecto del namespace:

```bash
oc adm policy add-scc-to-user anyuid -z default -n n8n-automation
```

## Paso 3: Crear el PersistentVolumeClaim (PVC)

Para mantener el historial de ejecuciones, credenciales y workflows guardados, creamos un almacenamiento persistente de 10 GB:

```yaml
# pvc-n8n.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: n8n-pvc
  namespace: n8n-automation
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```
Aplicar el manifesto:

```bash
oc apply -f pvc-n8n.yaml
```

## Paso 4: Desplegar n8n (Deployment)

Definimos el Deployment con la imagen oficial de n8n, las variables de entorno para configurar la URL pública y el montaje del volumen.

Nota: Reemplazá n8n.apps.tu-cluster.com por el dominio real de tu cluster.

```yaml
# deployment-n8n.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: n8n
  namespace: n8n-automation
  labels:
    app: n8n
spec:
  replicas: 1
  selector:
    matchLabels:
      app: n8n
  template:
    metadata:
      labels:
        app: n8n
    spec:
      containers:
      - name: n8n
        image: docker.io/n8nio/n8n:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5678
          name: http
        env:
        - name: N8N_PORT
          value: "5678"
        - name: N8N_PROTOCOL
          value: "https"
        - name: N8N_HOST
          value: "n8n.apps.tu-cluster.com" # Cambiar por el host real del Route
        - name: WEBHOOK_URL
          value: "[https://n8n.apps.tu-cluster.com/](https://n8n.apps.tu-cluster.com/)" # Cambiar por el host real del Route
        - name: N8N_DEFAULT_BINARY_DATA_MODE
          value: "filesystem"
        - name: GENERIC_TIMEZONE
          value: "America/Argentina/Buenos_Aires"
        resources:
          requests:
            cpu: "250m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "2Gi"
        volumeMounts:
        - mountPath: /home/node/.n8n
          name: n8n-storage
      volumes:
      - name: n8n-storage
        persistentVolumeClaim:
          claimName: n8n-pvc
```

Aplicar el manifesto:

```bash
oc apply -f deployment-n8n.yaml
```

## Paso 5: Crear el Service

Creamos un servicio interno para exponer el puerto 5678 del pod:

```yaml
# service-n8n.yaml
apiVersion: v1
kind: Service
metadata:
  name: n8n-service
  namespace: n8n-automation
  labels:
    app: n8n
spec:
  ports:
  - port: 5678
    targetPort: 5678
    name: http
  selector:
    app: n8n
```

Aplicar el manifesto:

```bash
oc apply -f service-n8n.yaml
```

## Paso 6: Exponer la Aplicación (Route con TLS)

Creamos un Route de OpenShift utilizando la terminación TLS edge (el certificado comodín del Ingress Router del cluster cifrará el tráfico externo):

# route-n8n.yaml

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: n8n
  namespace: n8n-automation
  labels:
    app: n8n
spec:
  to:
    kind: Service
    name: n8n-service
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

Aplicar el manifesto:

```bash
oc apply -f route-n8n.yaml
```

## Opcional: Creacion de route en openshift

Ejecutamos el comando:

```bash
oc create route edge n8n \
  --service=n8n-service \
  --port=http \
  --insecure-policy=Redirect \
  -n n8n-automation
```


## Paso 7: Verificación del Despliegue

Obtener la URL pública generada por OpenShift:

```bash
oc get route n8n -n n8n-automation -o jsonpath='{.spec.host}'
```

Verificar que el pod esté en estado Running:

```bash
oc get pods -n n8n-automation -l app=n8n
```

Revisar logs de inicio:

```bash
oc logs -f deployment/n8n -n n8n-automation
```

## Acceso: Navegá hacia https://<URL_DEL_ROUTE> en tu navegador para realizar la configuración inicial de la cuenta de usuario de n8n.
