Contenido
1. Preparación del Proyecto (Namespace) y Permisos	1
2. Secretos y Configuración (Secret y ConfigMap)	1
3. Almacenamiento Persistente (PVC)	1
4. Deployment de n8n (Deployment)	1
5. Exposición de Servicios y Ruta de OpenShift (Service y Route)	1


# 1. Preparación del Proyecto (Namespace) y Permisos

Crea un proyecto dedicado y ajusta las políticas de contexto de seguridad (SCC) si es necesario:

## Crear el proyecto/namespace  en OpenShift

```bash
oc new-project n8n-prod
```

 Nota: n8n utiliza por defecto el usuario 1000 (node). 
 Si tu cluster usa políticas SCC 'restricted' muy estrictas que fuerzan UIDs aleatorios, 
 puedes otorgar acceso al serviceaccount (opcional según la versión de OpenShift):
 oc adm policy add-scc-to-user nonroot-v2 -z default -n n8n-prod

# 2. Secretos y Configuración (Secret y ConfigMap)

Secret (n8n-secrets.yaml)
Guarda la clave de encriptación de n8n y las credenciales de la base de datos PostgreSQL:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: n8n-secrets
  namespace: n8n-prod
type: Opaque
stringData:
  N8N_ENCRYPTION_KEY: "CAMBIA_ESTO_POR_UNA_CLAVE_ALEATORIA_MUY_LARGA"
  DB_POSTGRESDB_PASSWORD: "TuPasswordDePostgresAca"
ConfigMap (n8n-config.yaml)
Configura las variables de entorno principales para n8n:
YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: n8n-config
  namespace: n8n-prod
data:
  N8N_PORT: "5678"
  N8N_PROTOCOL: "https"
  N8N_HOST: "n8n.tu-dominio-empresa.com"  # Tu URL final
  WEBHOOK_URL: "https://n8n.tu-dominio-empresa.com/"
  DB_TYPE: "postgresdb"
  DB_POSTGRESDB_HOST: "postgres-service.n8n-prod.svc.cluster.local" # O el IP/host de tu Postgres externo
  DB_POSTGRESDB_PORT: "5432"
  DB_POSTGRESDB_DATABASE: "n8n"
  DB_POSTGRESDB_USER: "n8n_user"
  EXECUTIONS_DATA_PRUNE: "true"
  EXECUTIONS_DATA_MAX_AGE: "168" # Conservar ejecuciones por 7 días (168hs)
3. Almacenamiento Persistente (PVC)
Crea el PVC para los datos de n8n. Asegúrate de usar la storageClassName correspondiente a tu almacenamiento empresarial en OpenShift (ej. Ceph, VMware vSphere CS, PureStorage, etc.).
YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: n8n-pvc-data
  namespace: n8n-prod
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  # storageClassName: tu-storageclass-onpremise
4. Deployment de n8n (Deployment)
Manifest listo para OpenShift, respetando los límites de recursos y contextos de seguridad:
YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: n8n
  namespace: n8n-prod
  labels:
    app: n8n
spec:
  replicas: 1 # Para modo single-instance. Para escalar horizontalmente se requiere modo Queue (Redis).
  selector:
    matchLabels:
      app: n8n
  template:
    metadata:
      labels:
        app: n8n
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: n8n
        image: docker.n8n.io/n8nio/n8n:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5678
          name: http
        envFrom:
        - configMapRef:
            name: n8n-config
        - secretRef:
            name: n8n-secrets
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        volumeMounts:
        - name: n8n-data
          mountPath: /home/node/.n8n
        livenessProbe:
          httpGet:
            path: /healthz
            port: 5678
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /healthz
            port: 5678
          initialDelaySeconds: 15
          periodSeconds: 10
      volumes:
      - name: n8n-data
        persistentVolumeClaim:
          claimName: n8n-pvc-data
          ```

# 5. Exposición de Servicios y Ruta de OpenShift (Service y Route)
En OpenShift no se suele utilizar Ingress estándar de Kubernetes, sino el recurso nativo Route expuesto a través del Router de OpenShift (HAProxy).
Service (service.yaml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: n8n-service
  namespace: n8n-prod
  labels:
    app: n8n
spec:
  type: ClusterIP
  ports:
  - port: 5678
    targetPort: 5678
    name: http
  selector:
    app: n8n
Route (route.yaml)
YAML
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: n8n-route
  namespace: n8n-prod
  annotations:
    # Aumentar timeouts en HAProxy para webhooks o ejecuciones largas de n8n
    haproxy.router.openshift.io/timeout: 60s
spec:
  host: n8n.tu-dominio-empresa.com
  to:
    kind: Service
    name: n8n-service
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

 
Si prefieres usar Helm (que está integrado nativamente en la consola web de OpenShift 4.x), puedes usar el Helm Chart de la comunidad manteniendo estas configuraciones:

```bash
helm repo add n8n https://c8n.github.io/helm-charts/
helm repo update

helm install n8n n8n/n8n \
  --namespace n8n-prod \
  --set secret.n8nEncryptionKey="TU_CLAVE" \
  --set externalPostgresql.enabled=true \
  --set externalPostgresql.host="postgres-host" \
  --set externalPostgresql.database="n8n" \
  --set externalPostgresql.user="n8n_user" \
  --set externalPostgresql.password="TU_DB_PASSWORD"
```

Consideraciones Clave para Producción On-Premise en OpenShift:
1.	Websockets: Si usas la consola gráfica de n8n detrás del Router de OpenShift, la versión 4.x de OpenShift soporta WebSockets nativamente en las Routes sin configuración extra.
2.	Escalabilidad Futura (Queue Mode): Si vas a ejecutar un volumen masivo de flujos, la arquitectura arriba mostrada es "Single Instance". Para escalar a múltiples replicas necesitarás desplegar Redis y configurar los Pods de n8n en modo worker y main (usando EXECUTIONS_MODE=queue).

