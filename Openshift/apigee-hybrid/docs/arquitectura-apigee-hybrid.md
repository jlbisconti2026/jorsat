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
