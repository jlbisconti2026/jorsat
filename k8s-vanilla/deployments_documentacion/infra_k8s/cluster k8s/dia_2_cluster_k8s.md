
# Indice

1. [🧱 Día 2 - Continuación del despliegue del clúster Kubernetes](#-día-2---continuación-del-despliegue-del-clúster-kubernetes)

2. [✅ Verificación de nodos](#-verificación-de-nodos)

3. [🖥️ Despliegue de Kubernetes Dashboard](#️-despliegue-de-kubernetes-dashboard)
4. [📌 Notas adicionales](#-notas-adicionales)

## 🧱 Día 2 - Continuación del despliegue del clúster Kubernetes

[🔗 Unión de nodos al clúster](#-unión-de-nodos-al-clúster)
[Seteo de rol de los nodos worker](#seteo-de-rol-de-los-nodos-worker
)
[✅ Verificación de nodos](#-verificación-de-nodos)
[🖥️ Despliegue de Kubernetes Dashboard](#️-despliegue-de-kubernetes-dashboard)
[📌 Notas adicionales](#-notas-adicionales)


## 🔗 Unión de nodos al clúster

Después de inicializar correctamente el nodo `master-01` como nodo de control del clúster con `kubeadm init`, se procedió a unir los demás nodos:

- Control planes:
  - `master-02`
  - `master-03`
- Nodos worker:
  - `worker-01`
  - `worker-02`
  - `worker-03`

Todos los nodos se unieron usando el comando `kubeadm join` con su respectivo token y hash de descubrimiento. Los nodos `master` utilizaron además el flag `--control-plane` y la clave de certificados para integrarse como nodos de control con etcd stacked.

## Seteo de rol de los nodos worker

```bash
kubectl label node worker-01 node-role.kubernetes.io/worker=worker
kubectl label node worker-02 node-role.kubernetes.io/worker=worker
kubectl label node worker-03 node-role.kubernetes.io/worker=worker
```

## ✅ Verificación de nodos

En el nodo con `kubectl` configurado (en este caso, `haproxy`), se verificó el estado de todos los nodos:

```bash
kubectl get nodes
```

Resultado:

NAME        STATUS   ROLES           AGE   VERSION
master-01   Ready    control-plane   130m  v1.29.15
master-02   Ready    control-plane   128m  v1.29.15
master-03   Ready    control-plane   75m   v1.29.15
worker-01   Ready    worker          72m   v1.29.15
worker-02   Ready    worker          72m   v1.29.15
worker-03   Ready    worker          72m   v1.29.15


## 🖥️ Despliegue de Kubernetes Dashboard

El panel de control web `Kubernetes Dashboard` fue desplegado con:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

Se recomendó crear un ServiceAccount con permisos administrativos para acceder al Dashboard.

## 📌 Notas adicionales

- El archivo `/etc/hosts` en todas las VMs incluye los nombres de cada nodo y su IP correspondiente.
- El load balancer HAProxy está configurado en `10.10.100.24:6443` como entrada al control-plane.
- Todos los nodos tienen `swap` desactivado como requisito de `kubeadm`.

---

🎯 El clúster está funcional con alta disponibilidad en los nodos master y con 3 workers listos para ejecutar workloads.
