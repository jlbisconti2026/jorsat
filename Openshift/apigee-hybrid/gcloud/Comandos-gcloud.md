# Cheat Sheet: gcloud CLI & Apigee Hybrid

Guía rápida de comandos de `gcloud` para la administración de proyectos, API Proxies, Buckets de Storage y exportación de configuraciones mediante la API de Apigee.

---

## 1. Autenticación e Inicialización

### Login de gcloud a GCP
> **Nota:** La validación se realiza mediante la cuenta de Active Directory (AD) de Claro con Google.

```bash
gcloud auth login
```

## 2.Habilitar APIs de Google requeridas
```bash
gcloud services enable pubsub.googleapis.com --project="claup-apigee-hybrid-desa"
gcloud services enable cloudresourcemanager.googleapis.com --project="claup-apigee-hybrid-desa"
gcloud services enable apigee.googleapis.com --project="claup-apigee-hybrid-desa"
gcloud services enable apigeeconnect.googleapis.com --project="claup-apigee-hybrid-desa"
```
##3. Gestión de Proyectos en GCP
### Crear proyecto
```bash
gcloud projects create [PROJECT_ID_O_NOMBRE]
```

### Borrar proyecto
```bash
gcloud projects delete [PROJECT_ID_O_NOMBRE]
```

### Recuperar proyecto borrado

```bash
gcloud projects undelete [PROJECT_ID_O_NOMBRE]
```

### Renombrar / Actualizar proyecto

```bash
gcloud projects update [PROJECT_ID_O_NOMBRE]
```

### Listar proyectos GCP
```bash
gcloud projects list
```

### Filtrar proyectos de Apigee:
```bash
gcloud projects list | grep apigee
```

Ejemplo de salida:

```text
claup-apigee-hybrid-desa    claup-apigee-hybrid-desa    1010788170711
claup-apigee-hybrid-prod    claup-apigee-hybrid-prod    300430456458
```

