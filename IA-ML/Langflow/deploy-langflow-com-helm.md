# Guía de Instalación de Langflow en OpenShift 4.21 mediante Helm

Esta guía proporciona las instrucciones paso a paso para desplegar **Langflow** en un clúster de **Red Hat OpenShift 4.21** utilizando **Helm**, garantizando un despliegue versionado, auditable y alineado con las buenas prácticas de la plataforma.

---

## Índice

1. [Prerrequisitos](#1-prerrequisitos)
2. [Paso 1: Crear el Proyecto en OpenShift](#paso-1-crear-el-proyecto-en-openshift)
3. [Paso 2: Agregar el Repositorio de Helm](#paso-2-agregar-el-repositorio-de-helm)
4. [Paso 3: Crear el Archivo de Valores Corporativos (values.yaml)](#paso-3-crear-el-archivo-de-valores-corporativos-valuesyaml)
5. [Paso 4: Ejecutar la Instalación con Helm](#paso-4-ejecutar-la-instalación-con-helm)
6. [Paso 5: Verificación del Despliegue](#paso-5-verificación-del-despliegue)
7. [Paso 6: Gestión del Ciclo de Vida y Mantenimiento](#paso-6-gestión-del-ciclo-de-vida-y-mantenimiento)

---

<a id="1-prerrequisitos"></a>

## 1. Prerrequisitos

* Clúster de **Red Hat OpenShift 4.21** en funcionamiento.
* Herramientas CLI instaladas y autenticadas:
  * **`oc`** (OpenShift CLI).
  * **`helm`** (v3.x o superior).
* Permisos para crear proyectos, `Deployments`, `Services` y `PVCs` en el clúster.

---

<a id="paso-1-crear-el-proyecto-en-openshift"></a>

## Paso 1: Crear el Proyecto en OpenShift

Primero, crea un namespace/proyecto dedicado para aislar los recursos de Langflow en el clúster.

```bash
oc new-project langflow-prod --display-name="Langflow AI Engine - Production"
``` 
## Paso 2: Agregar el Repositorio de Helm

# Agregar el repositorio del Chart de Langflow

```bash
helm repo add langflow [https://langflow-ai.github.io/langflow-helm-chart](https://langflow-ai.github.io/langflow-helm-chart)
```

# Actualizar el repositorio para obtener las últimas versiones

```bash
helm repo update
```
## Paso 3: Crear el Archivo de Valores Corporativos (values.yaml)

Para asegurar que Langflow cumpla con los estándares de OpenShift 4.21 (como ejecutarse bajo el contexto de seguridad non-root / SCC restricted-v2), crea un archivo local llamado values-langflow.yaml:

```yaml
replicaCount: 1

image:
  repository: langflowai/langflow
  tag: latest
  pullPolicy: IfNotPresent
```
# Configuración de variables de entorno para Langflow

```yaml
env:
  - name: LANGFLOW_HOST
    value: "0.0.0.0"
  - name: LANGFLOW_PORT
    value: "7860"
  - name: LANGFLOW_DATABASE_URL
    value: "sqlite:////app/langflow/langflow.db"
```

# Persistencia de datos para la base de datos local y componentes

```yaml
persistence:
  enabled: true
  size: 5Gi
  accessMode: ReadWriteOnce
```

# Asignación de recursos de CPUT y Memoria


```yaml
resources:
  limits:
    cpu: "2"
    memory: 4Gi
  requests:
    cpu: "500m"
    memory: 1Gi
    
```

# Deshabilitamos la creación de Ingress/Route desde el Chart 
# para mantener la aplicación 100% privada dentro del clúster


```yaml
ingress:
  enabled: false}
```

## Paso 4: Ejecutar la Instalación con Helm

Despliega la aplicación en el namespace creado utilizando el archivo de valores personalizado:

```bash
helm install langflow langflow/langflow \
  --namespace langflow-prod \
  -f values-langflow.yaml
  ```

## Paso 5: Verificación del Despliegue

1. Verificar el estado de la release de Helm:

```bash
helm list -n langflow-prod
```

2. Verificar que los Pods y Servicios estén correctamente desplegados:

```bash
oc get all -n langflow-prod
```

3. Verificar los logs de la aplicación:

```bash
oc logs -f deployment/langflow -n langflow-prod
```

## Paso 6: Gestión del Ciclo de Vida y Mantenimiento

Helm facilita las auditorías y la gestión operativa en entornos corporativos:

Ver el historial de cambios y versiones (Auditoría):

```bash
helm history langflow -n langflow-prod
```

Actualizar la configuración o la versión de la imagen:
Modifica el archivo values-langflow.yaml y ejecuta:

```bash
helm upgrade langflow langflow/langflow \
  --namespace langflow-prod \
  -f values-langflow.yaml
  ```

  Rollback instantáneo en caso de fallos:
Si una actualización presenta problemas, puedes regresar a la revisión anterior (ej. revisión 1):

```bash
helm rollback langflow 1 -n langflow-prod
```