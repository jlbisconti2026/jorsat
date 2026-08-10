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
```

## Paso 2: Configuración del Dominio en FortiGate

Para acceder usando el FQDN argo-workflows.gsve.locals en lugar de la IP cruda, se parametrizó el servidor DNS interno en el Fortinet.

Crear Entrada DNS (Address A):

Hostname: argo-workflows

FQDN: argo-workflows.gsve.locals (Atención con el tipeo exacto del sufijo)

IP Address: 10.10.100.54

Habilitar Servicio DNS en la Interfaz:

Ir a Network > DNS Servers.

En DNS Service on Interface, añadir la interfaz local (LAN / VLAN).

Configurar el modo en Recursive para resolver registros internos y redirigir el resto a Internet.

Tip de diagnóstico en la terminal cliente:

```bash
ipconfig /flushdns
nslookup argo-workflows.gsve.locals
```

## Paso 3: Configuración Definitiva del Despliegue (Bypass de Login y HTTPS)

El comportamiento nativo de Argo bloquea los Readiness Probes si se usa el modo --auth-mode=server solitario bajo HTTPS. La solución óptima y definitiva es activar un modo híbrido (server y client) para que el clúster valide la salud del pod por HTTPS de forma anónima mientras deshabilita el login externo.

1. Edición del Deployment
Ejecutar el comando de edición en vivo:

```bash
kubectl edit deployment argo-server -n argo
```

2. Modificación de Argumentos (args)
Localizar la sección de contenedores y estructurar los argumentos exactamente de la siguiente manera:

```yaml
args:
        - server
        - --auth-mode=server
        - --auth-mode=client
```


3. Ajuste de las Pruebas de Salud (Probes)
Asegurarse de mantener el esquema en HTTPS para que coincida con el transporte cifrado nativo del servidor:

```yaml
livenessProbe:
           httpGet:
             path: /
             port: 2746
             scheme: HTTPS
         readinessProbe:
           httpGet:
             path: /
             port: 2746
             scheme: HTTPS
```

## Paso 4: Verificación del Estado del Clúster

Una vez guardado el archivo, Kubernetes realizará un Rolling Update eliminando progresivamente el nodo anterior y validando el nuevo pod una vez supere el tiempo de delay inicial.

Monitorear que el nuevo pod llegue exitosamente al estado 1/1 Running:

```bash
kubectl get pod -n argo -o wide -w
```

## Paso 5: Acceso al Portal

Para evitar arrastrar certificados antiguos o cookies corruptas de los rebotados previos, abrir una ventana de incógnito en el navegador e ingresar a:

👉 https://argo-workflows.gsve.locals:2746

Nota: Al utilizar certificados TLS autofirmados de fábrica, se debe aceptar la advertencia del navegador ("Aceptar el riesgo y continuar"). El portal cargará el Dashboard administrativo de forma directa.

