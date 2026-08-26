
# Indice

1. [Guía: Fail‑Open (bypass) con Suricata + NFQUEUE + nftables + Squid](#guía-failopen-bypass-con-suricata--nfqueue--nftables--squid)
2. [0) Snapshot del entorno](#0-snapshot-del-entorno)
3. [1) Kernel: activar `nf_queue_bypass`](#1-kernel-activar-nf_queue_bypass)
4. [2) Base `nftables` **sin** reglas `queue` fijas](#2-base-nftables-sin-reglas-queue-fijas)
5. [3) Scripts ON/OFF para **q0** (web: pre‑proxy + 4555/4556)](#3-scripts-onoff-para-q0-web-preproxy--45554556)
6. [4) Scripts ON/OFF para **q1** (DNS/ICMP)](#4-scripts-onoff-para-q1-dnsicmp)
7. [5) Drop‑ins de systemd (ON al iniciar, OFF al parar)](#5-dropins-de-systemd-on-al-iniciar-off-al-parar)
8. [6) YAMLs clave (q0 como ejemplo)](#6-yamls-clave-q0-como-ejemplo)
9. [7) Pruebas y validación](#7-pruebas-y-validación)
10. [8) Troubleshooting rápido](#8-troubleshooting-rápido)
11. [9) Anexos útiles](#9-anexos-útiles)
12. [10) Resultado](#10-resultado)

## Guía: Fail‑Open (bypass) con Suricata + NFQUEUE + nftables + Squid

> **Objetivo:** Encolar *todo* (pre‑proxy y puertos de Squid 4555/4556) cuando Suricata está arriba **sin** que se corte el tráfico si alguna instancia cae.  
> **Estrategia:** No dejar reglas `queue` fijas. En su lugar, añadirlas **dinámicamente** al iniciar cada servicio (`suricata-q0`/`suricata-q1`) y **quitarlas** al detenerlo. Además, habilitar `nf_queue_bypass` en el kernel y usar `queue flags bypass`.

---

## 0) Snapshot del entorno

- Host **Guemes** (router/proxy) con:
  - **Squid** escuchando en `10.10.10.5:4555` (HTTP) y `10.10.10.5:4556` (HTTPS).
  - **Suricata** 7.x instalado en `/opt/suricata/`.
  - Instancias:
    - `suricata-q0` → **cola NFQUEUE 0** (navegación: pre‑proxy y 4555/4556)
    - `suricata-q1` → **cola NFQUEUE 1** (DNS/ICMP)
  - **nftables** tabla `inet jlb`.
- Clientes LAN usando **proxy explícito** (por eso `prerouting_nat` con redirect 80/443→4555/4556 no incrementa counters; esto es normal).

---

## 1) Kernel: activar `nf_queue_bypass`

Asegura que, **si no hay listener en la cola**, el kernel **acepte** (bypass) en lugar de dropear.

```bash
echo 'net.netfilter.nf_queue_bypass=1' | sudo tee /etc/sysctl.d/99-nfqueue-bypass.conf
sudo sysctl --system
# Verificar
sysctl net.netfilter.nf_queue_bypass   # → 1
```

> Esto **no** fuerza el bypass si hay un proceso enganchado a la cola; solo aplica cuando **no** hay listener.

---

## 2) Base `nftables` **sin** reglas `queue` fijas

La idea es que tu `/etc/nftables.conf` mantenga **NAT/FILTERS** como los necesites, pero la *chain* `prerouting_mangle` **sin** `queue`. Las colas se inyectan en caliente con scripts.

Ejemplo mínimo de `prerouting_mangle` base:

```nft
table inet jlb {
  chain prerouting_mangle {
    type filter hook prerouting priority mangle; policy accept;
    ct state established,related counter return
    # << SIN 'queue' aquí >>
  }

  # Mantén tus chains de NAT (prerouting_nat/postrouting_nat) y FILTER (input/forward/output)
  # tal como ya las tenías funcionando.
}
```

Aplicar:

```bash
sudo nft -c -f /etc/nftables.conf && sudo nft -f /etc/nftables.conf
```

---

## 3) Scripts ON/OFF para **q0** (web: pre‑proxy + 4555/4556)

Estos scripts **añaden** o **eliminan** reglas `queue` con `flags bypass`, marcadas con comments (`q0-pre`, `q0-post`). Son **idempotentes** y **no fallan** si ya existen/no existen.

```bash
/usr/local/sbin/nft-q0-on.sh**
```

```bash
#!/usr/bin/env bash
set -u
add_rule() {
  local tag="$1" rule="$2"
  nft -a list chain inet jlb prerouting_mangle 2>/dev/null | grep -q "comment \"$tag\"" && return 0
  nft add rule inet jlb prerouting_mangle $rule comment "$tag" 2>/dev/null || true
}
# Pre-proxy: LAN → {80,443,8080,8000} (solo flujos nuevos) a cola 0 con bypass
add_rule "q0-pre"  'iifname "lan" tcp dport {80,443,8080,8000} ct state new counter queue flags bypass to 0'
# Post-proxy: tráfico a Squid (4555/4556) a cola 0 con bypass
add_rule "q0-post" 'iifname "lan" tcp dport {4555,4556} counter queue flags bypass to 0'
exit 0
```

```bash
/usr/local/sbin/nft-q0-off.sh
```

```bash
#!/usr/bin/env bash
set -u
del_by_tag() {
  local tag="$1"
  local h
  h=$(nft -a list chain inet jlb prerouting_mangle 2>/dev/null | awk '/comment "'$tag'"/{print $NF}' | tail -n1)
  [ -n "${h:-}" ] && nft delete rule inet jlb prerouting_mangle handle "$h" 2>/dev/null || true
}
del_by_tag "q0-pre"
del_by_tag "q0-post"
exit 0
```

Instalar y dar permisos:

```bash
sudo tee /usr/local/sbin/nft-q0-on.sh >/dev/null <<'SH'
#!/usr/bin/env bash
set -u
add_rule() {
  local tag="$1" rule="$2"
  nft -a list chain inet jlb prerouting_mangle 2>/dev/null | grep -q "comment \"$tag\"" && return 0
  nft add rule inet jlb prerouting_mangle $rule comment "$tag" 2>/dev/null || true
}
add_rule "q0-pre"  'iifname "lan" tcp dport {80,443,8080,8000} ct state new counter queue flags bypass to 0'
add_rule "q0-post" 'iifname "lan" tcp dport {4555,4556} counter queue flags bypass to 0'
exit 0
SH
sudo chmod +x /usr/local/sbin/nft-q0-on.sh

sudo tee /usr/local/sbin/nft-q0-off.sh >/dev/null <<'SH'
#!/usr/bin/env bash
set -u
del_by_tag() {
  local tag="$1"
  local h
  h=$(nft -a list chain inet jlb prerouting_mangle 2>/dev/null | awk '/comment "'$tag'"/{print $NF}' | tail -n1)
  [ -n "${h:-}" ] && nft delete rule inet jlb prerouting_mangle handle "$h" 2>/dev/null || true
}
del_by_tag "q0-pre"
del_by_tag "q0-post"
exit 0
SH
sudo chmod +x /usr/local/sbin/nft-q0-off.sh
```

## 4) Scripts ON/OFF para **q1** (DNS/ICMP)

```bash
/usr/local/sbin/nft-q1-on.sh
```

```bash
#!/usr/bin/env bash
set -u
add_rule() {
  local tag="$1" rule="$2"
  nft -a list chain inet jlb prerouting_mangle 2>/dev/null | grep -q "comment \"$tag\"" && return 0
  nft add rule inet jlb prerouting_mangle $rule comment "$tag" 2>/dev/null || true
}
add_rule "q1-dns"  'iifname "lan" udp dport 53 counter queue flags bypass to 1'
add_rule "q1-icmp" 'iifname "lan" ip protocol icmp counter queue flags bypass to 1'
exit 0
```

```bash
/usr/local/sbin/nft-q1-off.sh
```

```bash
#!/usr/bin/env bash
set -u
del_by_tag() {
  local tag="$1"
  local h
  h=$(nft -a list chain inet jlb prerouting_mangle 2>/dev/null | awk '/comment "'$tag'"/{print $NF}' | tail -n1)
  [ -n "${h:-}" ] && nft delete rule inet jlb prerouting_mangle handle "$h" 2>/dev/null || true
}
del_by_tag "q1-dns"
del_by_tag "q1-icmp"
exit 0
```

Instalar y dar permisos:

```bash
sudo tee /usr/local/sbin/nft-q1-on.sh >/dev/null <<'SH'
#!/usr/bin/env bash
set -u
add_rule() {
  local tag="$1" rule="$2"
  nft -a list chain inet jlb prerouting_mangle 2>/dev/null | grep -q "comment \"$tag\"" && return 0
  nft add rule inet jlb prerouting_mangle $rule comment "$tag" 2>/dev/null || true
}
add_rule "q1-dns"  'iifname "lan" udp dport 53 counter queue flags bypass to 1'
add_rule "q1-icmp" 'iifname "lan" ip protocol icmp counter queue flags bypass to 1'
exit 0
SH
sudo chmod +x /usr/local/sbin/nft-q1-on.sh

sudo tee /usr/local/sbin/nft-q1-off.sh >/dev/null <<'SH'
#!/usr/bin/env bash
set -u
del_by_tag() {
  local tag="$1"
  local h
  h=$(nft -a list chain inet jlb prerouting_mangle 2>/dev/null | awk '/comment "'$tag'"/{print $NF}' | tail -n1)
  [ -n "${h:-}" ] && nft delete rule inet jlb prerouting_mangle handle "$h" 2>/dev/null || true
}
del_by_tag "q1-dns"
del_by_tag "q1-icmp"
exit 0
SH
sudo chmod +x /usr/local/sbin/nft-q1-off.sh
```

---

## 5) Drop‑ins de systemd (ON al iniciar, OFF al parar)

Permiten ejecutar los scripts como **root** y **no** tumbar el servicio si el script falla (gracias al `-` al inicio).

```bash
/etc/systemd/system/suricata-q0.service.d/10-nft-toggle.conf
```

```ini
[Service]
PermissionsStartOnly=true
ExecStartPost=-/usr/local/sbin/nft-q0-on.sh
ExecStopPost=-/usr/local/sbin/nft-q0-off.sh
```

```bash
**/etc/systemd/system/suricata-q1.service.d/10-nft-toggle.conf**
```

```ini
[Service]
PermissionsStartOnly=true
ExecStartPost=-/usr/local/sbin/nft-q1-on.sh
ExecStopPost=-/usr/local/sbin/nft-q1-off.sh
```

Aplicar:

```bash
sudo systemctl daemon-reload
sudo systemctl restart suricata-q0 suricata-q1
```

---

## 6) YAMLs clave (q0 como ejemplo)

```bash
/opt/suricata/etc/suricata-q0.yaml
```

```yaml
%YAML 1.1
---
default-log-dir: /opt/suricata/var/log/suricata
vars:
  address-groups:
    HOME_NET: "[10.10.10.0/24]"

nfq:
  mode: inline
  queues: [0]

default-rule-path: /opt/suricata/etc/rules
rule-files:
  - suricata.rules
  - jlb-core-whitelist.rules
  - jlb-http-hardening.rules
  - jlb-http-whitelist.rules

outputs:
  - eve-log:
      enabled: yes
      filetype: regular
      filename: /opt/suricata/var/log/suricata/eve-q0.json
      community-id: true
      types: [alert, drop, http, dns, flow, tls, ssh]
  - fast:
      enabled: yes
      filename: /opt/suricata/var/log/suricata/fast-log-q0.log
```

*(q1 igual, cambiando `queues: [1]` y `filename` → `eve-q1.json`/`fast-log-q1.log` si corresponde.)*

---

## 7) Pruebas y validación

- **Ver reglas dinámicas** (con Suricata arriba):

  ```bash
  sudo nft -a list chain inet jlb prerouting_mangle | egrep 'q0-pre|q0-post|q1-dns|q1-icmp'
  sudo cat /proc/net/netfilter/nfnetlink_queue   # Deben aparecer líneas con 0 y 1
  ```

- **Fail‑open de q0** (proxy explícito):

  ```bash
  sudo systemctl stop suricata-q0
  sudo nft -a list chain inet jlb prerouting_mangle | egrep 'q0-pre|q0-post' || echo "OK: sin reglas q0"
  sudo cat /proc/net/netfilter/nfnetlink_queue   # No debe aparecer línea que empiece con "0"
  curl -x http://10.10.10.5:4555 -I http://example.com
  curl -x http://10.10.10.5:4555 -I https://example.com -k
  ```

- **Fail‑open de q1** (si aplicaste toggle q1):

  ```bash
  sudo systemctl stop suricata-q1
  sudo nft -a list chain inet jlb prerouting_mangle | egrep 'q1-dns|q1-icmp' || echo "OK: sin reglas q1"
  sudo cat /proc/net/netfilter/nfnetlink_queue   # No debe aparecer línea que empiece con "1"
  dig +short example.com @8.8.8.8   # DNS debe responder (bypass real)
  ping -c1 8.8.8.8                  # ICMP debe pasar
  ```

---

## 8) Troubleshooting rápido

- **Se corta al parar q0/q1:** asegurar que sus reglas `queue` desaparecieron.

  ```bash
  sudo nft -a list chain inet jlb prerouting_mangle | egrep 'q0-|q1-'
  sudo /usr/local/sbin/nft-q0-off.sh
  sudo /usr/local/sbin/nft-q1-off.sh
  ```

- **Bypass no aplica:** revisar listeners:

  ```bash
  sudo cat /proc/net/netfilter/nfnetlink_queue   # Debe desaparecer la línea de la cola detenida
  sysctl net.netfilter.nf_queue_bypass           # → 1
  ```

- **El servicio cae por post‑script:** usar drop‑in con:

  ```ini
  PermissionsStartOnly=true
  ExecStartPost=-/usr/local/sbin/nft-q0-on.sh
  ExecStopPost=-/usr/local/sbin/nft-q0-off.sh
  ```

- **Counters NAT 80/443→4555/4556 en 0:** los clientes están usando **proxy explícito** (normal). Para “transparente”, desactivar proxy explícito en clientes y usar `redirect` en `prerouting_nat`.

---

## 9) Anexos útiles

- **Ver tráfico/decisiones en vivo**:

  ```bash
  sudo nft monitor trace | egrep 'prerouting|jlb' -A2
  ```

- **Logs Suricata**:

  ```bash
  sudo tail -f /opt/suricata/var/log/suricata/eve-q0.json
  sudo tail -f /opt/suricata/var/log/suricata/eve-q1.json
  ```

- **EVEBox Agent** (opcional, si usás EVEBox):

  ```yaml
  # /etc/evebox/agent.yaml
  server:
    url: https://10.10.10.20:5636
    disable-certificate-check: true
  input:
    paths:
      - "/opt/suricata/var/log/suricata/eve-q0.json"
      - "/opt/suricata/var/log/suricata/eve-q1.json"
  additional-fields:
    sensor-name: "guemes"
  ```

## 10) Resultado

Con este esquema:

- **Encogés TODO** (pre‑proxy y 4555/4556) cuando Suricata está **arriba**.
- **No** se corta la navegación ni DNS/ICMP cuando **cualquier instancia cae** (las reglas `queue` se retiran y el kernel bypasséa).

¡Listo! 🎯
