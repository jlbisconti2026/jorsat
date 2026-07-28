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
