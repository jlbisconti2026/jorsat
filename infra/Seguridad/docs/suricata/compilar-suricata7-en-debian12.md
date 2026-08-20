
# Indice
[📦 Paso 1: Instalar dependencias necesarias](#-paso-1-instalar-dependencias-necesarias)
[📥 Paso 2: Descargar y compilar libhtp 0.5.47](#-paso-2-descargar-y-compilar-libhtp-0547)
[📥 Paso 3: Descargar y compilar Suricata 7.x](#-paso-3-descargar-y-compilar-suricata-7x)
[Paso 4: Configurar Suricata con todas las opciones](#️-paso-4-configurar-suricata-con-todas-las-opciones)
[🛠️ Paso 5: Compilar e instalar](#️-paso-5-compilar-e-instalar)
[🔍 Paso 6: Verificar instalación](#-paso-6-verificar-instalación)
[🧪 Paso 7: Ejecutar Suricata](#-paso-7-ejecutar-suricata)
[🧹 Paso 8: Variables útiles (opcional)](#-paso-8-variables-útiles-opcional)

Este documento detalla cómo compilar e instalar **Suricata 7.x** desde código fuente en **Debian 12**, incluyendo soporte para NFQUEUE, eBPF, y más, con instalación final en `/opt`.


## 📦 Paso 1: Instalar dependencias necesarias

```bash
sudo apt update
sudo apt install -y   libpcap-dev libpcre3-dev libyaml-dev zlib1g-dev   libcap-ng-dev libmagic-dev libjansson-dev libnss3-dev   libgeoip-dev liblua5.3-dev libhiredis-dev libevent-dev   libjansson-dev libnetfilter-queue-dev libnetfilter-log-dev   rustc cargo python3-pip jq libtool autoconf automake   pkg-config liblz4-dev libmaxminddb-dev libcurl4-openssl-dev   libnet1-dev libnghttp2-dev
```


## 📥 Paso 2: Descargar y compilar libhtp 0.5.47

```bash
cd /usr/src
git clone https://github.com/OISF/libhtp.git
cd libhtp
git checkout 0.5.47
./autogen.sh
./configure --prefix=/opt/libhtp
make -j$(nproc)
sudo make install
```s

## 📥 Paso 3: Descargar y compilar Suricata 7.x

```bash
cd /usr/src
wget https://www.openinfosecfoundation.org/download/suricata-7.x.tar.gz
tar -xvzf suricata-7.x.tar.gz
cd suricata-7.x
```

> 🔁 Reemplazá `7.x` por la versión exacta que descargaste.

---

## ⚙️ Paso 4: Configurar Suricata con todas las opciones

```bash
./configure   --prefix=/opt/suricata   --with-libhtp-includes=/opt/libhtp/include   --with-libhtp-libraries=/opt/libhtp/lib   --enable-nfqueue   --enable-lua   --enable-pie   --enable-geoip   --enable-hiredis   --enable-ebpf   --enable-gccprotect
```

---

## 🛠️ Paso 5: Compilar e instalar

```bash
make -j$(nproc)
sudo make install-full
```

> El flag `install-full` copia los archivos de configuración, reglas y scripts auxiliares al directorio de instalación.

---

## 🔍 Paso 6: Verificar instalación

```bash
/opt/suricata/bin/suricata --build-info
```

Deberías ver un resumen con todos los módulos habilitados.

---

## 🧪 Paso 7: Ejecutar Suricata

Ejemplo de ejecución en modo IPS con NFQUEUE 0:

```bash
sudo /opt/suricata/bin/suricata -c /opt/suricata/etc/suricata/suricata.yaml -q 0 --af-packet
```

---

## 🧹 Paso 8: Variables útiles (opcional)

Podés agregar esto a tu `.bashrc`:

```bash
export PATH=/opt/suricata/bin:$PATH
```

Y para ver la interfaz de configuración del build:

```bash
cd /usr/src/suricata-7.x
./configure --help
```

---

## 🧼 Limpieza opcional

```bash
make clean
```

---

## 📌 Notas finales

- Esta instalación en `/opt` permite tener múltiples versiones de Suricata sin interferir con APT.
- Si tenés reglas personalizadas, copiá tus `.rules` a `/opt/suricata/etc/suricata/rules/`.

---

🎉 ¡Listo! Ya tenés Suricata 7.x compilado con todos los módulos ninja activados, y listo para inspección de tráfico como un campeón.
