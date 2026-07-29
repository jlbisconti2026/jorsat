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


