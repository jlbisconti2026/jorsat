
# Índice de Contenidos

1. [Consideraciones Críticas Antes de Empezar](#1-consideraciones-críticas-antes-de-empezar)
   - [La Ruta de Upgrade Obligatoria (Secuencial)](#la-ruta-de-upgrade-obligatoria-secuencial)
   - [¿Por qué se hace así?](#por-qué-se-hace-así)
2. [Plan de Respaldo (Backup Obligatorio)](#2-plan-de-respaldo-backup-obligatorio)
3. [Orden Estricto de Actualización por Nodo (Por Cada Fase)](#3-orden-estricto-de-actualización-por-nodo-por-cada-fase)
4. [Procedimiento Técnico Paso a Paso (Ejemplo por Nodo)](#4-procedimiento-técnico-paso-a-paso-ejemplo-por-nodo)
   - [Paso 4.1: Actualizar el Utilitario Bootstrap de Apigee](#paso-41-actualizar-el-utilitario-bootstrap-de-apigee)
   - [Paso 4.2: Actualizar el Comando de Configuración Central](#paso-42-actualizar-el-comando-de-configuración-central)
   - [Paso 4.3: Actualizar los Componentes Específicos del Nodo](#paso-43-actualizar-los-componentes-específicos-del-nodo)
5. [Recomendaciones de Operación](#5-recomendaciones-de-operación)

## GUÍA DE MIGRACIÓN Y UPGRADE: APIGEE PRIVATE CLOUD (ON-PREMISE)

> **De la versión 4.51.00 a la versión 4.53.01**

---

## 1. CONSIDERACIONES CRÍTICAS ANTES DE EMPEZAR

> **REGLA DE ORO DE GOOGLE APIGEE:** No existe el salto directo (upgrade directo) de la versión 4.51.00 a la 4.53.01. Intentar forzar la instalación romperá los esquemas de bases de datos (Cassandra/Postgres) y corromperá el clúster.

### La Ruta de Upgrade Obligatoria (Secuencial)

`4.51.00` ➔ `4.52.02` *(o última de la rama 4.52)* ➔ `4.53.01`

### ¿Por qué se hace así?

La versión 4.53 introduce cambios drásticos en la infraestructura subyacente de Apigee On-Premise, tales como:

- Soporte nativo para Cassandra 4.0.
- Actualizaciones estructurales en OpenLDAP y ZooKeeper.
- Migración interna de scripts hacia Python 3.

La versión intermedia (4.52.x) prepara, limpia y adapta los esquemas de datos existentes para que la transición final a la 4.53 no cause pérdida de información.

---

## 2. PLAN DE RESPALDO (BACKUP OBLIGATORIO)

Antes de ejecutar cualquier comando de actualización, se debe realizar un respaldo total de todos los entornos:

1. **Snapshots de Máquinas Virtuales:** Tomar capturas de estado de todas las VMs que componen la topología de Apigee.
2. **Backup Nativo de Cassandra:** En cada nodo de base de datos, ejecutar:

   ```bash
   /opt/apigee/apigee-cassandra/bin/nodetool snapshot
   ```

Backup de Analíticas (Postgres): En los nodos de base de datos de analíticas, ejecutar:

 ```bash
pg_dumpall -U apigee > apigee_analytics_backup.sql
 ```

## 3. ORDEN ESTRICTO DE ACTUALIZACIÓN POR NODO (POR CADA FASE)

Tanto para la Fase 1 (4.51 a 4.52) como para la Fase 2 (4.52 a 4.53), se debe seguir un orden estricto de componentes para mantener la disponibilidad del tráfico y la consistencia del clúster:

Edge UI: Interfaz gráfica de usuario.

Management Server: Cerebro de la API de administración de Apigee.

OpenLDAP: Gestión de usuarios, autenticación y RBAC.

ZooKeeper: Gestión de la configuración y estado del clúster.

Cassandra: Base de datos principal de configuración y datastore.

Qpid: Sistema de cola de mensajes analíticos.

Postgres Server: Base de datos de reportes y analíticas.

Router: Componente crítico que recibe el tráfico externo.

Message Processor: Procesador de la lógica y políticas de los proxies.

## 4. PROCEDIMIENTO TÉCNICO PASO A PASO (EJEMPLO POR NODO)

El siguiente procedimiento se debe repetir en cada servidor, respetando el orden de la lista anterior. Primero para la versión 4.52 y, una vez finalizado todo el clúster, repetir el proceso para la versión 4.53.

### Paso 4.1: Actualizar el Utilitario Bootstrap de Apigee

Descargar y ejecutar el script de bootstrap correspondiente a la versión destino (ejemplo para la fase intermedia):

```bash
sudo yum clean all
sudo bash /tmp/bootstrap_4.52.xx.sh apigeeuser=TuUsuario apigeepassword=TuPassword
source /etc/profile.d/apig
ee-service.sh
```

### Paso 4.2: Actualizar el Comando de Configuración Central

```bash
/opt/apigee/apigee-service/bin/apigee-service apigee-setup update
```

#### Paso 4.3: Actualizar los Componentes Específicos del Nodo

Dependiendo del rol de la máquina virtual (ejemplo: un nodo combinado de tráfico con Router y Message Processor), ejecutar el script update.sh apuntando al archivo de configuración silenciosa (silent.txt) original:

```bash
/opt/apigee/apigee-setup/bin/update.sh -c edge-router,edge-message-processor -f /ruta/al/archivo/config_silent.txt
```

## 5. RECOMENDACIONES DE OPERACIÓN

Monitoreo de Procesos: Después de actualizar cada componente, verificar que el servicio esté arriba con el comando:

```bash
/opt/apigee/apigee-service/bin/apigee-service status

```

Archivo Silent (Configuración): Mantener el mismo archivo de configuración que se utilizó para instalar la versión 4.51.00 original, asegurando que los permisos de red, contraseñas y puertos sigan siendo idénticos.

Ventana de Mantenimiento: Aunque los Routers y Message Processors en alta disponibilidad soportan actualizaciones individuales sin caída total del servicio, se recomienda realizar todo este proceso en horarios de bajo tráfico corporativo.
