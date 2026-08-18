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
7. [Paso 6: Exponer la Aplicación (Route con TLS)](#paso-6-exponer-la-aplicación-route-con-tls)
8. [Paso 7: Verificación del Despliegue](#paso-7-verificación-del-despliegue)

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