## Índice de Contenidos

1. [Resumen del Escenario de Red](#1-resumen-del-escenario-de-red)
2. [Paso 1: Exponer el Servidor con MetalLB](#paso-1-exponer-el-servidor-con-metallb)
3. [Paso 2: Configuración del Dominio en FortiGate](#paso-2-configuración-del-dominio-en-fortigate)
4. [Paso 3: Configuración Definitiva del Despliegue (Bypass de Login y HTTPS)](#paso-3-configuración-definitiva-del-despliegue-bypass-de-login-y-https)
   - [1. Edición del Deployment](#1-edición-del-deployment)
   - [2. Modificación de Argumentos (args)](#2-modificación-de-argumentos-args)
   - [3. Ajuste de las Pruebas de Salud (Probes)](#3-ajuste-de-las-pruebas-de-salud-probes)
5. [Paso 4: Verificación del Estado del Clúster](#paso-4-verificación-del-estado-del-clúster)
6. [Paso 5: Acceso al Portal](#paso-5-acceso-al-portal)

---

# Guía de Instalación y Configuración de Argo Workflows en Kubernetes

Esta guía detalla paso a paso el proceso de despliegue, exposición de red mediante **MetalLB**, resolución DNS con **FortiGate**, y la configuración de autenticación sin contraseña para el dashboard de **Argo Workflows**.

---

## 1. Resumen del Escenario de Red

* **Servicio Expuesto:** `argo-server`
* **Balanceador de Carga:** MetalLB
* **IP Externa Asignada:** `10.10.100.54`
* **Dominio FQDN Local:** `argo-workflows.gsve.locals`
* **Puerto de Acceso:** `2746`

---

## Paso 1: Exponer el Servidor con MetalLB

Por defecto, la instalación de Argo Workflows configura el servicio `argo-server` en modo `ClusterIP`. Para asignarle una IP externa del pool de MetalLB de forma directa, modificamos el tipo de servicio a `LoadBalancer`:

```bash
kubectl patch svc argo-server -n argo -p '{"spec": {"type": "LoadBalancer"}}'
