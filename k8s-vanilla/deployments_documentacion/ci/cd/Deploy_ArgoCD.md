
# Indice

1. [Despliegue de ArgoCD con MetalLB en Kubernetes (GitOps)](#despliegue-de-argocd-con-metallb-en-kubernetes-gitops)
2. [🚀 Paso 1: Creación del Namespace Dedicado](#-paso-1-creación-del-namespace-dedicado)
3. [Paso 2: Despliegue e Instalación de Manifiestos (Server-Side Apply)](#paso-2-despliegue-e-instalación-de-manifiestos-server-side-apply)
4. [🔄 Paso 3: Reinicio y Sincronización en Orden de los Componentes](#-paso-3-reinicio-y-sincronización-en-orden-de-los-componentes)
5. [🌐 Paso 4: Exposición del Servicio mediante MetalLB (LoadBalancer)](#-paso-4-exposición-del-servicio-mediante-metallb-loadbalancer)
6. [🔑 Paso 5: Recuperación de la Contraseña de Administrador](#-paso-5-recuperación-de-la-contraseña-de-administrador)
7. [🖥️ Paso 6: Acceso a la Interfaz Web y Bypass de Seguridad en Brave](#️-paso-6-acceso-a-la-interfaz-web-y-bypass-de-seguridad-en-brave)

## Despliegue de ArgoCD con MetalLB en Kubernetes (GitOps)

Guía completa paso a paso con los comandos exactos utilizados para solucionar los conflictos de instalación, aplicar Server-Side Apply y exponer la interfaz mediante MetalLB con asignación de IP estática/dinámica en tu red local.

---

## 🚀 Paso 1: Creación del Namespace Dedicado

Es una buena práctica de arquitectura aislar las herramientas de infraestructura crítica en sus propios espacios de nombres virtuales.

```bash
kubectl create namespace argocd
```

## Paso 2: Despliegue e Instalación de Manifiestos (Server-Side Apply)

Dueño al tamaño masivo de las Definiciones de Recursos Personalizados (CRDs) de ArgoCD (especialmente applicationsets.argoproj.io), el método tradicional client-side apply falla superando el límite de anotaciones de Kubernetes (262144 bytes).

Para solucionar esto, aplicamos utilizando Server-Side Apply junto con el flag de forzado para sobrescribir los metadatos de autoría previos creados por el cliente:

```bash
kubectl apply -n argocd --server-side --force-conflicts -f [https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml](https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml)
```

## 🔄 Paso 3: Reinicio y Sincronización en Orden de los Componentes

El servidor de ArgoCD (argocd-server) requiere conectarse de forma nativa a Redis. Como los Pods intentan levantar en simultáneo, a veces el servidor falla con un error CreateContainerConfigError porque el Secret argocd-redis aún no ha terminado de inicializarse.

Forzamos un reinicio controlado de todos los despliegues para asegurar que lean las configuraciones limpias:

```bash
kubectl rollout restart deployment -n argocd
```

Puedes verificar que todos los Pods pasen al estado Running utilizando:

```bash
kubectl get pods -n argocd
```

## 🌐 Paso 4: Exposición del Servicio mediante MetalLB (LoadBalancer)

Por defecto, la interfaz de ArgoCD se crea como tipo ClusterIP (aislada internamente). Modificamos el Service para mutarlo a tipo LoadBalancer. MetalLB detectará el cambio y le asignará una IP externa real de tu red local.

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

Nota: Siguiendo tu topología de red actual, MetalLB asignó la IP externa mapeada en los puertos estándares:

IP Externa: 10.10.100.53

Puertos expuestos: 80 (HTTP) y 443 (HTTPS)

## 🔑 Paso 5: Recuperación de la Contraseña de Administrador

ArgoCD genera una contraseña aleatoria y única durante la primera instalación y la almacena de manera segura encriptada en Base64. Para extraerla directamente decodificada en texto plano, corre el siguiente comando en tu terminal:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

Usuario por defecto: admin

Contraseña: (Guarda el chorizo de caracteres alfanuméricos devuelto por la terminal)

## 🖥️ Paso 6: Acceso a la Interfaz Web y Bypass de Seguridad en Brave

Abre tu navegador Brave e ingresa mediante una de las siguientes opciones utilizando tu IP configurada:

Opción Recomendada (HTTPS): <https://10.10.100.53>

Opción Directa (HTTP): <http://10.10.100.53>
