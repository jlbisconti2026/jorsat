
# Indice 

1. [Despliegue de gsventerprise.com.ar en Kubernetes Vanilla](#despliegue-de-gsventerprisecomar-en-kubernetes-vanilla)
2. [1. Estructura del Proyecto](#-1-estructura-del-proyecto)
3. [🐳 2. Dockerfile utilizado](#-2-dockerfile-utilizado)
4. [ 3. Build y Push de la imagen a DockerHub](#-3-build-y-push-de-la-imagen-a-dockerhub)
5. [🚀 5. Despliegue en el clúster](#-5-despliegue-en-el-clúster)

## Despliegue de gsventerprise.com.ar en Kubernetes Vanilla

Este documento describe los pasos que seguí para levantar el sitio web `gsventerprise.com.ar` en mi clúster Kubernetes Vanilla (sobre Ubuntu 22.04).

---

## 🧱 1. Estructura del Proyecto

```text
gsv-enterprise.com.ar/
├── index.html
├── about.html
├── styles.css
├── about.css
├── .gitignore
├── Dockerfile
├── [archivos estáticos: imágenes, fuentes]
```

---

## 🐳 2. Dockerfile utilizado

```Dockerfile
FROM nginx:alpine
COPY . /usr/share/nginx/html
```

---

## 📦 3. Build y Push de la imagen a DockerHub

### Login en DockerHub

```bash
docker login -u gsv2019
```

### Build de la imagen

```bash
sudo docker build -t gsv2019/gsv-enterprise:latest .
```

### Push de la imagen al registry

```bash
sudo docker push gsv2019/gsv-enterprise:latest
```

---

## ☸️ 4. Manifiestos Kubernetes

### Deployment `gsv-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gsv-enterprise
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gsv-enterprise
  template:
    metadata:
      labels:
        app: gsv-enterprise
    spec:
      containers:
      - name: web
        image: gsv2019/gsv-enterprise:latest
        ports:
        - containerPort: 80
```

### Service `gsv-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: gsv-service
spec:
  type: LoadBalancer
  selector:
    app: gsv-enterprise
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
```

---

## 🚀 5. Despliegue en el clúster

```bash
kubectl apply -f gsv-deployment.yaml
kubectl apply -f gsv-service.yaml
```

---

