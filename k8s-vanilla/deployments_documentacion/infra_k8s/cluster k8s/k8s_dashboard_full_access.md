# ✅ Solución: Permitir que Kubernetes Dashboard vea todos los namespaces con un ServiceAccount personalizado


[🔍 Problema](#-problema)
[🛠️ Solución completa paso a paso](#️-solución-completa-paso-a-paso)(
[Acceder al Dashboard](#acceder-al-dashboard))

## 🔍 Problema

Después de instalar el Kubernetes Dashboard y acceder con el método **Token**, el panel solo mostraba el namespace `default`. Además, al remover el flag `--namespace=kubernetes-dashboard` para liberar la vista global, el Dashboard crasheaba con errores relacionados a la falta de acceso a secrets:


panic: secrets "kubernetes-dashboard-csrf" not found

## 🛠️ Solución completa paso a paso

### 1. Crear un ServiceAccount con permisos de `cluster-admin`

```bash
kubectl create serviceaccount admin -n kubernetes-dashboard

kubectl create clusterrolebinding admin-binding   --clusterrole=cluster-admin   --serviceaccount=kubernetes-dashboard:admin
```

---

### 2. Editar el Deployment del Dashboard para que use ese SA

```bash
kubectl -n kubernetes-dashboard edit deployment kubernetes-dashboard
```

Cambiar esta línea:

```yaml
serviceAccountName: kubernetes-dashboard
```

Por:

```yaml
serviceAccountName: admin
```

---

### 3. Volver a agregar el flag `--namespace=kubernetes-dashboard` para evitar el crash

Dentro del mismo deployment, asegurarse de que los args del contenedor incluyan:

```yaml
args:
  - --auto-generate-certificates
  - --namespace=kubernetes-dashboard
```

Este flag **no restringe la vista del Dashboard** si se usa un token con permisos `cluster-admin`. Solo indica en qué namespace buscar la secret `kubernetes-dashboard-csrf`.

---

### 4. Crear la secret de tipo `service-account-token` manualmente

Crear un archivo `admin-sa-token.yaml` con el siguiente contenido:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: admin-token
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: admin
type: kubernetes.io/service-account-token
```

Aplicar:

```bash
kubectl apply -f admin-sa-token.yaml
```

---

### 5. Obtener el token de acceso

```bash
kubectl -n kubernetes-dashboard get secret admin-token -o go-template="{{.data.token | base64decode}}"
```

Copiar el token resultante.

---

## Acceder al Dashboard

- Ingresar a `https://<IP o DNS>:<NodePort o LoadBalancer>`
- Seleccionar método **"Token"**
- Pegar el token del paso anterior
- ✅ Listo: ahora se pueden ver **todos los namespaces** y recursos

---

## 📆 Extras recomendados

- Guardar este token en un password manager si se usará frecuentemente
- Agregar un cron que notifique si expira el token o rota el SA
- Se puede revocar o rotar el token simplemente borrando la secret
