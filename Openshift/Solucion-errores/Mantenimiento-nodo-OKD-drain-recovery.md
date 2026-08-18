# Indice 

[Mantenimiento y recuperación de nodo en OKD](#mantenimiento-y-recuperación-de-nodo-en-okd)
[ Retirar el nodo del clúster (Drain)](#retirar-el-nodo-del-clúster-drain)
[Ingresar al nodo en falla](#ingresar-al-nodo-en-falla)
[Detener servicios de Kubernetes](#detener-servicios-de-kubernetes)
[Detener pods y contenedores](#detener-pods-y-contenedores)
[Eliminar pods detenidos](#eliminar-pods-detenidos)
[ Reinicializar CRI-O y limpiar contenedores](#reinicializar-cri-o-y-limpiar-contenedores)
[Levantar servicios](#levantar-servicios)
[Resultado esperado](#resultado-esperado)



## Mantenimiento y recuperación de nodo en OKD

 1. Marcar el nodo como *Unschedulable*

Se evita que el scheduler asigne nuevos pods al nodo.

```bash
oc adm cordon master2.gsve.locals
```

---

## Retirar el nodo del clúster (Drain)

Se drenan los workloads existentes del nodo.

```bash
oc adm drain master2.gsve.locals \
  --force=true --ignore-daemonsets --delete-emptydir-data --timeout=60s
```

---

## Ingresar al nodo en falla

```bash
ssh -l core master2.gsve.locals
```

Elevar privilegios:

```bash
sudo -i
```

---

## Detener servicios de Kubernetes

```bash
systemctl stop kubelet
```

---

## Detener pods y contenedores

### Detener todos los pods

```bash
crictl stopp `crictl pods -q`
```

### Detener todos los contenedores

```bash
crictl stop `crictl ps -aq`
```

---

## Eliminar pods detenidos

```bash
crictl rmp `crictl pods -q`
crictl rmp --force `crictl pods -q`
```

---

## Reinicializar CRI-O y limpiar contenedores

```bash
systemctl stop crio
rm -rf /var/lib/containers/*
crio wipe -f
```

---

## Levantar servicios

```bash
systemctl start crio
systemctl start kubelet
```

---

## Resultado esperado

- El nodo queda limpio de pods y contenedores corruptos.
- kubelet y CRI-O inician correctamente.
- El nodo puede reincorporarse al clúster luego del *uncordon*.

---

## Nota

Este procedimiento es **destructivo a nivel de contenedores locales**.  
Usar únicamente en nodos con fallas graves.
