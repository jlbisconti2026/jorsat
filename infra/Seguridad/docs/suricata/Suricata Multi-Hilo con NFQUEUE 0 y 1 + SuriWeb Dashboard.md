
# Indice

1. [🛡️ Suricata Multi-Hilo con NFQUEUE 0 y 1 + SuriWeb Dashboard](#️-suricata-multi-hilo-con-nfqueue-0-y-1--suriweb-dashboard)
2. [🎯 Objetivo](#-objetivo)
3. [⚙️ Configuración de Suricata](#️-configuración-de-suricata)
4. [Systemd Units](#systemd-units)
5. [🔥 IPTABLES (rules.v4)](#-iptables-rulesv4)
6. [🧠 SuriWeb Integración](#-suriweb-integración)
7. [📦 Logrotate](#-logrotate)
8. [🚀 Resultado](#-resultado)
9. [✅ Recomendaciones Futuras](#-recomendaciones-futuras)

## 🛡️ Suricata Multi-Hilo con NFQUEUE 0 y 1 + SuriWeb Dashboard

Este proyecto implementa una arquitectura IPS/IDS de alto rendimiento usando **Suricata** con múltiples instancias concurrentes, cada una asociada a una cola NFQUEUE distinta. Se complementa con un sistema de visualización en tiempo real llamado **SuriWeb**, que recopila alertas y drops desde múltiples fuentes.

## 🎯 Objetivo

Optimizar el procesamiento de tráfico en sistemas con múltiples núcleos separando el análisis de paquetes en **dos colas NFQUEUE (q0 y q1)**. Esto permite balancear la carga y aumentar la capacidad de análisis concurrente.

## ⚙️ Configuración de Suricata

### Archivos de configuración

- `/opt/suricata/etc/suricata/suricata.yaml` → instancia para **cola 0** (`q0`)
- `/opt/suricata/etc/suricata/suricata-q1.yaml` → instancia para **cola 1** (`q1`)

Cada archivo define rutas separadas para logs (`eve.json`, `fast.log`, etc.)

## Systemd Units

`/etc/systemd/system/suricata-q0.service`

```ini
[Unit]
Description=Suricata IPS (NFQUEUE 0)
After=network.target

[Service]
ExecStart=/opt/suricata/bin/suricata -c /opt/suricata/etc/suricata/suricata.yaml -q 0 --pidfile /var/run/suricata-q0.pid

[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/suricata-q1.service`

```ini
[Unit]
Description=Suricata IPS (NFQUEUE 1)
After=network.target

[Service]
ExecStart=/opt/suricata/bin/suricata -c /opt/suricata/etc/suricata/suricata-q1.yaml -q 1 --pidfile /var/run/suricata-q1.pid

[Install]
WantedBy=multi-user.target
```

---

## 🔥 IPTABLES (rules.v4)

Las reglas están diseñadas para derivar tráfico WAN entrante hacia la cola `q1` y el resto a `q0`, por ejemplo:

```bash
-A FORWARD -i wan -j NFQUEUE --queue-num 1
-A FORWARD -i lan -j NFQUEUE --queue-num 0
```

---

## 🧠 SuriWeb Integración

`insert_logs.py` modificado para leer simultáneamente:

- `/opt/suricata/var/log/suricata/eve.json`
- `/opt/suricata/var/log/suricata/fast.log`
- `/opt/suricata/var/log/suricata/eve-q1.json`
- `/opt/suricata/var/log/suricata/fast-log-q1.log`

Esto permite que **SuriWeb** procese eventos de ambas colas y los refleje en mapas, dashboards, filtros, etc.

---

## 📦 Logrotate

Rota automáticamente logs de ambas instancias para evitar saturación del disco:

Archivo: `/etc/logrotate.d/suricata-multi`

```conf
/opt/suricata/var/log/suricata/eve*.json {
    rotate 7
    daily
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}

/opt/suricata/var/log/suricata/fast*.log {
    rotate 7
    daily
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

---

## 🚀 Resultado

- Dos hilos Suricata totalmente independientes
- Balanceo de carga entre colas NFQUEUE
- Visualización geográfica y estadística centralizada
- Optimización del uso de CPU y disco

---

## ✅ Recomendaciones Futuras

- Añadir métricas por cola en el frontend
- Usar `af-packet` o `workers` si no se usa NFQUEUE
- Desplegar en múltiples hosts con agente federado

---
