# Índice de Contenidos

## Índice de Contenidos

1. [Construcción de un Execution Environment (EE) para AWX](#construcción-de-un-execution-environment-ee-para-awx)
2. [Flujo completo](#flujo-completo)
3. [Pasos de Construcción y Despliegue](#pasos-de-construcción-y-despliegue)
   - [1. Clonar el repositorio](#1-clonar-el-repositorio)
   - [2. Instalar Ansible Builder](#2-instalar-ansible-builder)
   - [3. Instalar Docker (o Podman)](#3-instalar-docker-o-podman)
   - [4. Construir la imagen](#4-construir-la-imagen)
   - [5. Verificar la imagen creada](#5-verificar-la-imagen-creada)
   - [6. Publicar la imagen en el Registry Local](#6-publicar-la-imagen-en-el-registry-local)
   - [7. Registrar el Execution Environment en AWX](#7-registrar-el-execution-environment-en-awx)
   - [8. Consideracion Importante](#8-consideracion-importante)
   - [9. Próximos pasos recomendados](#9-próximos-pasos-recomendados)
   - [10. Resultado esperado](#10-resultado-esperado)

---

# Construcción de un Execution Environment (EE) para AWX

El repositorio **Git no se usa directamente para que AWX ejecute el Execution Environment (EE)**.

Se utiliza únicamente como **fuente del código** para construir una **imagen Docker/OCI**, que luego será utilizada por AWX para ejecutar los Jobs.

# Flujo completo

```text
GitHub
│
└── Automation/
    └── EE/
        ├── execution-environment.yml
        ├── requirements.yml
        ├── requirements.txt
        └── bindep.txt
                │
                │ git clone
                ▼
        Ubuntu 24.04
                │
                │ ansible-builder build
                ▼
      awx-ee-jorsat:v1 (Imagen Docker)
                │
                │ docker push
                ▼
        Registry Local (10.10.100.35:5000)
                │
                ▼
          AWX utiliza esa imagen
```

---

# Pasos de Construcción y Despliegue

## 1. Clonar el repositorio

Supongamos que el repositorio se encuentra en GitHub:

```bash
git clone https://github.com/jorsat2025/jorsat.git
```

Ingresar al directorio donde se encuentran los archivos del Execution Environment:

```bash
cd jorsat/Automation/EE
```

En esa carpeta deberán existir los siguientes archivos:

```text
execution-environment.yml
requirements.yml
requirements.txt
bindep.txt
```

Editar el archivo  execution-environment.yaml con el siguinte contenido

---

```bash
version: 3

images:
  base_image:
    name: rockylinux:9

dependencies:
  ansible_core:
    package_pip: ansible-core
  ansible_runner:
    package_pip: ansible-runner
  galaxy: requirements.yml
  system: bindep.txt

options:
  package_manager_path: /usr/bin/dnf

additional_build_steps:
  prepend_base:
    - RUN dnf install -y epel-release
    - RUN echo "exclude=curl" >> /etc/dnf/dnf.conf
  prepend_builder:
    - RUN dnf install -y epel-release
    - RUN echo "exclude=curl" >> /etc/dnf/dnf.conf

```

## 2. Instalar Ansible Builder

Actualizar el sistema:

```bash
sudo apt update
```

Instalar Python:

```bash
sudo apt install -y python3-pip
```

Instalar Ansible Builder:

```bash
pip install ansible-builder
```

---

## 3. Instalar Docker (o Podman)

Por ejemplo:

```bash
sudo apt install docker.io -y
```

Opcionalmente agregar el usuario al grupo Docker para evitar utilizar `sudo`:

```bash
sudo usermod -aG docker $USER
```

Cerrar sesión y volver a ingresar para aplicar el cambio.

---

## 4. Construir la imagen

Ejecutar:

```bash
ansible-builder build -t awx-ee-jorsat:v1
```

Durante la construcción ocurre el siguiente proceso:

```text
Lee execution-environment.yml
            │
            ▼
Lee requirements.yml
            │
            ▼
Descarga Collections desde Ansible Galaxy
            │
            ▼
Lee requirements.txt
            │
            ▼
Instala librerías Python
            │
            ▼
Lee bindep.txt
            │
            ▼
Instala paquetes del Sistema Operativo
            │
            ▼
Genera la Imagen Docker
```

---

## 5 Verificar la imagen creada

Ejecutar:

```bash
docker images
```

Resultado esperado:

```text
REPOSITORY      TAG
awx-ee-jorsat   v1
```

---

## 6. Publicar la imagen en el Registry Local

Si ya existe un Registry local funcionando en:

```text
10.10.100.35:5000
```

publicar la imagen:

```bash
docker tag awx-ee-jorsat:v1 10.10.100.35:5000/awx-ee-jorsat:v1

docker push 10.10.100.35:5000/awx-ee-jorsat:v1
```

---

## 7. Registrar el Execution Environment en AWX

Crear un nuevo **Execution Environment** apuntando a:

```text
10.10.100.35:5000/awx-ee-jorsat:v1
```

A partir de ese momento, cualquier **Job Template** podrá utilizar esa imagen.

---

## 8. Consideracion Importante

Verificar que el archivo se llame exactamente:

```text
execution-environment.yml
```

No debe llamarse:

```text
execution-envoironment.yml
```

Si el nombre es incorrecto, **Ansible Builder no lo detectará automáticamente**.

---

## 9. Próximos pasos recomendados

1. Clonar el repositorio `jorsat`.
2. Instalar `ansible-builder`.
3. Construir `awx-ee-jorsat:v1`.
4. Publicar la imagen en `10.10.100.35:5000`.
5. Registrar el Execution Environment en AWX.
6. Crear un Job Template utilizando ese EE.
7. Ejecutar el primer Job con el nuevo Execution Environment.

---

## 10. Resultado esperado

En menos de una hora es posible disponer de un **Execution Environment personalizado**, versionado en Git, publicado en un Registry privado y reutilizable por todos los Jobs de AWX.

[def]: #introducción
