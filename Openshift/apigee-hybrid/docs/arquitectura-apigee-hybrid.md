
## Índice de Contenidos

1. [Diagrama de Arquitectura (Visual mental)](#1-diagrama-de-arquitectura-visual-mental)
2. [Componentes Clave](#2-componentes-clave)
3. [Diagrama de flujo de componentes](#3-diagrama-de-flujo-de-componentes)





# Arquitectura y Componentes de Apigee Hybrid

## 1. Diagrama de Arquitectura (Visual mental)

```ascii
             Google Cloud (Plano de control central)
             ┌────────────────────────────────────┐
             │  Apigee Control Plane (Cloud)      │
             │  - Dev Portal                      │
             │  - Apigee UI / API                 │
             │  - Analytics backend               │
             └────────────▲──────────────▲────────┘
                          │              │
                          │              │
            (sync, auth, metrics)     (API management)
                          │              │
                    ┌─────┴─────┐  ┌─────┴─────┐
                    │ MART      │  │ UDCA      │
                    │ (Mgmt API)│  │ (Telemetry│
                    └─────▲─────┘  └─────▲─────┘
                          │              │
                          │              │
                 ┌────────┴────────┐     │
                 │ Synchronizer    │◄────┘
                 │ (config sync)   │
                 └────────▲────────┘
                          │
               ┌──────────┴─────────────┐
               │  Apigee Runtime Plane  │ (en tu clúster K8s/OKD)
               │                        │
               │ - Runtime pods         │
               │ - Ingress Gateway      │
               │ - Istio (opcional)     │
               └────────────────────────┘
```
## 2. Componentes Clave

| Componente | Rol Principal |
| :--- | :--- |
| **MART** | Exponer las APIs de administración de Apigee desde el clúster. |
| **Synchronizer** | Sincroniza la configuración del runtime con el control plane de GCP. |
| **UDCA** | Envía métricas y logs (analytics) hacia Google Cloud. |
| **Runtime Pods** | Ejecutan las llamadas de tus APIs (el data plane). |
| **Ingress Gateway** | Maneja el ingreso HTTP/HTTPS de tráfico de clientes externos. |
| **Istio (opcional)** | Puede integrarse con Apigee para manejar tráfico. |

## 3. Diagrama de flujo de componentes

```mermaid
flowchart TD
    %% Estilos de colores
    classDef verde fill:#d4e7c5,stroke:#4b6043,color:#000000;
    classDef rosa fill:#f4c2c2,stroke:#a85a6e,color:#000000;
    classDef azul fill:#b3d8e8,stroke:#4a7a96,color:#000000;
    classDef amarillo fill:#fce8a6,stroke:#8c7b3e,color:#000000;

    %% Nodos principales
    GCP["Google Cloud (Control Plane)"]:::verde
    CLIENT["Cliente / App"]:::amarillo
    SYNC["Synchronizer"]:::rosa
    MART["MART<br>(Management API Runtime)"]:::rosa
    INGRESS(["Ingress Gateway<br>(Istio/Apigee)"]):::azul
    RUNTIME(["Runtime<br>(API Execution)"]):::azul
    UDCA["UDCA<br>(Data Collection Agent)"]:::rosa

    %% Conexiones desde Google Cloud
    GCP -->|"Descarga config y proxies"| SYNC
    GCP -->|"Control APIs"| MART
    GCP -->|"Métricas, logs"| UDCA

    %% Conexiones del Cliente
    CLIENT -->|"Solicitudes API"| INGRESS

    %% Conexiones hacia el Runtime
    SYNC -->|"Aplica config"| RUNTIME
    MART -->|"Administra y cachea APIs"| RUNTIME
    INGRESS -->|"Redirecciona tráfico"| RUNTIME

    %% Conexión del Runtime a UDCA
    RUNTIME -->|"Exporta datos de tráfico"| UDCA
```

