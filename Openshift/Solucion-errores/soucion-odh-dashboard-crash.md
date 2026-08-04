# Resolución de Inestabilidad y Recuperación de Servicios en OpenDataHub (OpenShift)

## 📌 Resumen del Problema

Tras la instalación/actualización de **OpenDataHub** en el cluster OpenShift, se presentaron inestabilidades generales en los componentes del namespace `opendatahub`:

* El pod `odh-dashboard` presentaba bucles de reinicio constantes (`CrashLoopBackOff` / estado `8/9`) debido a fallos en las pruebas de salud (*Liveness/Readiness Probes*) rechazando conexiones HTTP en el puerto local (`connection refused`).
* El pod `model-registry-operator` fallaba debido a restricciones de permisos RBAC para listar recursos `apiservers.config.openshift.io` a nivel de cluster.
* Existía un bucle de conciliación por parte del operador y pods huérfanos/relictos de componentes deshabilitados (como `maas-controller`).

---

## 🛠️ Pasos de la Solución Aplicada

### 1. Resolución de Permisos RBAC en `model-registry-operator`

Se asignó el rol de lectura sobre los recursos de configuración del API Server a la ServiceAccount correspondiente:

```bash
oc create clusterrolebinding model-registry-operator-apiserver-reader \
  --clusterrole=system:openshift:discovery \
  --serviceaccount=opendatahub:model-registry-operator-controller-manager
```

### 2. Corrección del Probe de Salud en odh-dashboard

Para evitar que kubelet fallara las validaciones por temas de interfaz de red (127.0.0.1 vs IP de Pod), se configuró el readinessProbe para realizar la verificación mediante ejecución interna (exec curl) directamente dentro del contenedor:

## Evitar sobreescritura temporal del operador

```bash
oc annotate deployment odh-dashboard -n opendatahub opendatahub.io/managed=false --overwrite
```

## Ajustar el probe a exec curl local

```bash
oc patch deployment odh-dashboard -n opendatahub --type='json' -p='[
  {"op": "remove", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet"},
  {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe/exec", "value": {"command": ["curl", "-f", "[http://127.0.0.1:8080/api/health](http://127.0.0.1:8080/api/health)"]}}
]'
```

### 3. Limpieza de Pods Redundantes y Sincronización del Operador

Se removieron recursos residuales del controlador MaaS (oc delete deployment maas-controller -n opendatahub).

Se ajustó el valor de réplicas a 1 y se re-escaló el deployment del dashboard para eliminar las instancias duplicadas causadas por la estrategia RollingUpdate.

```bash
oc scale deployment odh-dashboard -n opendatahub --replicas=0
oc scale deployment odh-dashboard -n opendatahub --replicas=1
```

Todos los pods del namespace opendatahub alcanzaron estado operativo estable (1/1 y 9/9 READY). La consola web del dashboard se encuentra completamente accesible y operativa.

### 4. Workarround adicional

En caso de que el pod correspondiente a odh-dashboard no quede estable y tenga restarts o incluso quede en estadoCrashLoopBackoff, realizar los siguientes pasos.

### 1. Pausa de Gestión sobre el Deployment

Se aplicó la anotación necesaria para indicarle al operador que ignore la gestión de este Deployment específico:

```bash
oc annotate deployment odh-dashboard -n opendatahub opendatahub.io/managed=false --overwrite
```

### 2. Reemplazo Completo del Bloque de Probes (Exec Curl)

Se reestructuraron por completo las definiciones de readinessProbe y livenessProbe para ejecutar la validación vía curl en 127.0.0.1:8080:

```bash
oc patch deployment odh-dashboard -n opendatahub --type='json' -p='[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/readinessProbe",
    "value": {
      "exec": {
        "command": ["curl", "-f", "[http://127.0.0.1:8080/api/health](http://127.0.0.1:8080/api/health)"]
      },
      "initialDelaySeconds": 30,
      "periodSeconds": 10,
      "timeoutSeconds": 5,
      "successThreshold": 1,
      "failureThreshold": 3
    }
  },
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/livenessProbe",
    "value": {
      "exec": {
        "command": ["curl", "-f", "[http://127.0.0.1:8080/api/health](http://127.0.0.1:8080/api/health)"]
      },
      "initialDelaySeconds": 60,
      "periodSeconds": 15,
      "timeoutSeconds": 5,
      "successThreshold": 1,
      "failureThreshold": 5
    }
  }
]'
```

### 3. Reinicio y Validación

Se reinició la instancia para forzar la recreación bajo los nuevos parámetros:

```bash
oc delete pod -l app=odh-dashboard -n opendatahub
```

### Estado Final de Validación

El pod se mantiene en ejecución continua alcanzando estado 9/9 READY, sin presentar reinicios ni cambios de hash por conciliación del operador.
