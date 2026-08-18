# Indice

[DIAGNÓSTICO DEL BLOQUEO (TAINT)](#diagnóstico-del-bloqueo-taint)
[SOLUCIÓN PARA EL INGRESS CONTROLLER (ROUTER DEFAULT)](#solución-para-el-ingress-controller-router-default)
[SOLUCIÓN PARA EL INGRESS CONTROLLER (ROUTER DEFAULT)](#solución-para-el-ingress-controller-router-default)
[Editar configuración del Ingress Controller default](#editar-configuración-del-ingress-controller-default)
[Modificar las secciones 'nodeSelector' y 'tolerations' dentro del bloque 'spec'](#modificar-las-secciones-nodeselector-y-tolerations-dentro-del-bloque-spec)
[Verificá que las réplicas pasen a estado 'Running' (2/2)](#verificá-que-las-réplicas-pasen-a-estado-running-22)
[SOLUCIÓN PARA EL REGISTRO DE IMÁGENES (IMAGE REGISTRY)](#solución-para-el-registro-de-imágenes-image-registry)
[VERIFICACIÓN FINAL DEL CLÚSTER](#verificación-final-del-clúster)


## DIAGNÓSTICO DEL BLOQUEO (TAINT)

Los nodos de infraestructura dedicados (infra0, infra1, infra2) tienen activo el
siguiente bloqueo que impide que los componentes del sistema se programen allí:

- Nodo: infra0.labjorsat.gsve.locals
- Taint: infra=reserved:NoSchedule
Para verificar que esto es asi ejecutamos el comando

```bash
oc describe node infra0.labjorsat.gsve.locals | grep -i taints
```

Taints:             infra=reserved:NoSchedule

Para solucionar esto, se debe inyectar la tolerancia exacta (Key: infra, Value: reserved)
en las configuraciones maestras administradas por los operadores correspondientes.

## SOLUCIÓN PARA EL INGRESS CONTROLLER (ROUTER DEFAULT)

---
El router de OpenShift/OKD utiliza la red del host (hostNetwork) puertos 80/443.
Para fijarlo exclusivamente en tus 3 nodos infra y tolerar el bloqueo, seguí estos pasos:

## Editar configuración del Ingress Controller default

Ejecutar el comando:

```bash
   oc edit ingresscontroller default -n openshift-ingress-operator
   ```

## Modificar las secciones 'nodeSelector' y 'tolerations' dentro del bloque 'spec'

```yaml
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
```

Guardá y salí del editor (:wq). El operador recreará los pods en tus nodos infra

## Verificá que las réplicas pasen a estado 'Running' (2/2)

```bash
oc get po -n openshift-ingress | grep router-default
```
La salida debe ser similar a la siguiente:

router-default-5bc8685474-jtdql                                   2/2     Running   0
router-default-5bc8685474-knlk7                                   2/2     Running   0
router-default-5bc8685474-z6wc2                                   2/2     Running

## SOLUCIÓN PARA EL REGISTRO DE IMÁGENES (IMAGE REGISTRY)

El operador de Image Registry queda trabado en 'Progressing: True' porque el pod nuevo
no puede ingresar a los nodos de infraestructura para completar el despliegue.

1. Abrí la configuración global del registro de imágenes:

```bash
   oc edit configs.imageregistry.operator.openshift.io/cluster
```

2.  Buscá el bloque 'spec' y agregá la tolerancia exacta (si ya existen toleraciones,
   añadila como un elemento más de la lista):

```yaml
spec:
tolerations:

- effect: NoSchedule key: infra operator: Equal value: reserved
```

1. Guardá y salí del editor (:wq).
2. El operador le inyectará la regla al pod pendiente de forma inmediata. Verificá que el pod en 'Pending' pase a 'Running' (1/1):

```bash
oc get po -n openshift-image-registry | grep image-registry-
```

cluster-image-registry-operator-7dcf979d75-t7kws   1/1     Running     1 (92d ago)   103d
image-registry-6c54666fdd-6mjxv                    1/1     Running     0             88m
image-registry-6c54666fdd-hmmp4                    1/1     Running     0             88m
image-registry-6c54666fdd-v7swk                    1/1     Running     0             88m

## VERIFICACIÓN FINAL DEL CLÚSTER

Una vez aplicados ambos cambios, los operadores terminarán sus tareas de conciliación.
Comprobá que el estado de los ClusterOperators sea saludable (Available: True, Progressing: False, Degraded: False):

 ```bash
  oc get co ingress image-registry
```
