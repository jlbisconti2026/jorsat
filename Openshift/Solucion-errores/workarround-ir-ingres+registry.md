# DIAGNÓSTICO DEL BLOQUEO (TAINT)

---
Los nodos de infraestructura dedicados (infra0, infra1, infra2) tienen activo el
siguiente bloqueo que impide que los componentes del sistema se programen allí:
- Nodo: infra0.labokdipi.claro.amx
- Taint: infra=reserved:NoSchedule
Para solucionar esto, se debe inyectar la tolerancia exacta (Key: infra, Value: reserved)
en las configuraciones maestras administradas por los operadores correspondientes.
---
## 1. SOLUCIÓN PARA EL INGRESS CONTROLLER (ROUTER DEFAULT)
---
El router de OpenShift/OKD utiliza la red del host (hostNetwork) puertos 80/443.
Para fijarlo exclusivamente en tus 3 nodos infra y tolerar el bloqueo, seguí estos pasos:
### 1. Abrí la configuración del Ingress Controller default:
   $ oc edit ingresscontroller default -n openshift-ingress-operator
### 2. Modificá o agregá las secciones 'nodeSelector' y 'tolerations' dentro del bloque 'spec':

spec:
nodePlacement:
nodeSelector:
matchLabels:
node-role.kubernetes.io/infra: ""
tolerations:
- effect: NoSchedule
key: infra
operator: Equal
value: reserved
replicas: 3
### 3. Guardá y salí del editor (:wq). El operador recreará los pods en tus nodos infra.
### 4. Verificá que las réplicas pasen a estado 'Running' (2/2): 
```bash
oc get po -n openshift-ingress | grep router-default
```
---
### 2. SOLUCIÓN PARA EL REGISTRO DE IMÁGENES (IMAGE REGISTRY)
---
El operador de Image Registry queda trabado en 'Progressing: True' porque el pod nuevo
no puede ingresar a los nodos de infraestructura para completar el despliegue.
1. Abrí la configuración global del registro de imágenes:
   $ oc edit configs.imageregistry.operator.openshift.io/cluster
2. Buscá el bloque 'spec' y agregá la tolerancia exacta (si ya existen toleraciones,
   añadila como un elemento más de la lista):
spec:
tolerations:
- effect: NoSchedule key: infra operator: Equal value: reserved
3. Guardá y salí del editor (:wq).
4. El operador le inyectará la regla al pod pendiente de forma inmediata. Verificá que el pod en 'Pending' pase a 'Running' (1/1):
```bash
oc get po -n openshift-image-registry | grep image-registry-
```
---
3. VERIFICACIÓN FINAL DEL CLÚSTER
---
Una vez aplicados ambos cambios, los operadores terminarán sus tareas de conciliación.
Comprobá que el estado de los ClusterOperators sea saludable (Available: True, Progressing: False, Degraded: False):
 ```bash
  oc get co ingress image-registry
```
================================================================================
