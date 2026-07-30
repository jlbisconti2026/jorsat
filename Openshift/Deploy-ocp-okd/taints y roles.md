# Taints y Tolerations en Kubernetes

## Tabla de contenido
- [Taints y tolerations](#taints-y-tolerations)
- [Ejemplo de Pod con tolerations](#ejemplo-de-pod-con-tolerations)
- [Casos especiales](#casos-especiales)
  - [Key vacía](#key-vacía)
  - [Effect vacío](#effect-vacío)
- [Tipos de effect](#tipos-de-effect)
  - [NoExecute](#noexecute)
  - [NoSchedule](#noschedule)
  - [PreferNoSchedule](#prefernoschedule)
  - [Múltiples taints y tolerations](#múltiples-taints-y-tolerations)
  - [tolerationSeconds](#tolerationseconds)
  - [Operadores numéricos](#operadores-numéricos)
- [Casos de uso](#casos-de-uso)
  - [Nodos dedicados](#nodos-dedicados)
  - [Hardware especial (GPU)](#hardware-especial-gpu)
- [Evictions basadas en taints](#evictions-basadas-en-taints)

---

## Taints y tolerations

Las **Node affinity** son una propiedad de los Pods que los atrae hacia un conjunto de nodos (ya sea como preferencia o como requisito obligatorio). Los **taints** son lo opuesto: permiten que un nodo rechace un conjunto de pods.

Las **tolerations** se aplican a los pods. Las tolerations permiten que el scheduler programe pods en nodos con taints coincidentes. Las tolerations permiten el scheduling, pero no lo garantizan: el scheduler también evalúa otros parámetros como parte de su funcionamiento.

Los taints y las tolerations trabajan juntos para asegurar que los pods no sean programados en nodos inapropiados. Uno o más taints se aplican a un nodo; esto marca que el nodo no debería aceptar pods que no toleren esos taints.

### Conceptos

Podés agregar un taint a un nodo usando:

```bash
oc taint nodes node1 key1=value1:NoSchedule
```

Esto coloca un taint en el nodo node1. El taint tiene:

key: key1

value: value1

effect: NoSchedule

Esto significa que ningún pod podrá programarse sobre node1 a menos que tenga una toleration coincidente.

Para remover el taint:
```bash
kubectl taint nodes node1 key1=value1:NoSchedule-
```
Podés especificar una toleration para un pod dentro del PodSpec. Las siguientes tolerations coinciden con el taint anterior:

```yaml
tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoSchedule"
```
O también:

```yaml
tolerations:
- key: "key1"
  operator: "Exists"
  effect: "NoSchedule"
```

Nota: El scheduler por defecto de Kubernetes tiene en cuenta taints y tolerations cuando selecciona un nodo para ejecutar un Pod. Sin embargo, si especificás manualmente .spec.nodeName para un Pod, esa acción bypasséa el scheduler; el Pod queda asociado directamente al nodo indicado, incluso si existen taints NoSchedule en ese nodo. Si además el nodo tiene un taint NoExecute, el kubelet expulsará el Pod a menos que exista una toleration adecuada.

# Ejemplo de Pod con tolerations

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  tolerations:
  - key: "example-key"
    operator: "Exists"
    effect: "NoSchedule"
```

El valor por defecto de operator es Equal.

Una toleration coincide con un taint si:

Las keys son iguales.

Los effects son iguales.

Y además:

El operator es Exists (sin especificar value), o

El operator es Equal y los values coinciden.

Casos especiales
Key vacía
Si la key está vacía:

```yaml
operator: Exists
```

ebe utilizarse obligatoriamente y coincidirá con todas las keys y values.

Effect vacío
Un effect vacío coincide con todos los effects para esa key.

Tipos de effect
NoExecute
Afecta pods que ya están corriendo:

Pods que no toleran el taint son expulsados inmediatamente.

Pods que toleran el taint sin tolerationSeconds permanecen indefinidamente.

Pods con tolerationSeconds permanecen sólo el tiempo indicado y luego son expulsados.

NoSchedule
No se programarán nuevos pods en el nodo salvo que tengan una toleration coincidente.

Los pods ya existentes NO son expulsados.

PreferNoSchedule
Es una versión “soft” o preferencial de NoSchedule. El control plane intentará evitar programar pods sin toleration en el nodo, pero no es obligatorio.

Múltiples taints y tolerations
Un nodo puede tener múltiples taints y un pod múltiples tolerations. Kubernetes procesa esto como un filtro:

Toma todos los taints del nodo.

Ignora aquellos que el pod tolera.

Los taints restantes aplican sus effects al pod.

En particular:

Si existe al menos un taint no tolerado con effect NoSchedule, Kubernetes NO programará el pod en ese nodo.

Si no hay NoSchedule pero sí PreferNoSchedule, Kubernetes intentará evitar el nodo.

Si existe un NoExecute no tolerado, el pod será expulsado o no programado.

Ejemplo:

```bash
kubectl taint nodes node1 key1=value1:NoSchedule
kubectl taint nodes node1 key1=value1:NoExecute
kubectl taint nodes node1 key2=value2:NoSchedule
```

Y el pod configurado con:

```yaml
tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoSchedule"
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoExecute"
```

Resultado:

El pod NO podrá programarse en el nodo porque no tolera el tercer taint (key2=value2:NoSchedule).

Pero si ya estaba ejecutándose cuando se agregó el taint, continuará funcionando.

```yaml
tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoExecute"
  tolerationSeconds: 3600
```

Esto significa que el pod permanecerá asociado al nodo durante 3600 segundos después de que se agregue el taint. Luego será expulsado.

Operadores numéricos
Además de Equal y Exists, Kubernetes soporta Gt (Greater than) y Lt (Less than) para comparar valores enteros en taints.

Ejemplo:
Aplicación del taint en el nodo:
```bash
kubectl taint nodes node1 servicelevel.organization.example/agreed-service-level=950:NoSchedule
```

Y luego agregar las tolerations correspondientes a los pods.

Suele agregarse también una label dedicated=groupName junto con node affinity para asegurar que esos pods sólo corran en esos nodos dedicados.

### Hardware especial (GPU)
Los nodos con GPUs pueden tener taints para evitar que workloads normales usen esos recursos. Los pods que sí necesitan GPU agregan las tolerations adecuadas.

### Evictions basadas en taints
El node controller agrega automáticamente taints cuando detecta problemas en un nodo.

Ejemplos:
node.kubernetes.io/not-ready

node.kubernetes.io/unreachable

node.kubernetes.io/memory-pressure

node.kubernetes.io/disk-pressure

tolerationSeconds para nodos caídos
Podés definir cuánto tiempo un pod permanece asociado a un nodo inaccesible:

```yaml
tolerations:
- key: "node.kubernetes.io/unreachable"
  operator: "Exists"
  effect: "NoExecute"
  tolerationSeconds: 6000
```

DaemonSets
Los DaemonSets automáticamente incluyen tolerations para evitar ser expulsados por problemas comunes del nodo como:

memory-pressure

disk-pressure

unreachable

not-ready
