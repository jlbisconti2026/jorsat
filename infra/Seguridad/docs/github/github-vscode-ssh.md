# 🚀 Indice

[Indice](#-indice)
[🔐 Paso 1: Verificá tu clave SSH](#-paso-1-verificá-tu-clave-ssh)
[🌐 Paso 2: Agregar la clave a GitHub](#-paso-2-agregar-la-clave-a-github)
[🧪 Paso 3: Probar la conexión](#-paso-3-probar-la-conexión)
[🧠 Paso 4: Clonar tu repositorio desde VSCode](#-paso-4-clonar-tu-repositorio-desde-vscode)
[Paso 5: Usar Git desde VSCode](#-paso-5-usar-git-desde-vscode)
[🖥️ Terminal integrada](#️-terminal-integrada)

## 🔐 Paso 1: Verificá tu clave SSH

En PowerShell:

```powershell
ls ~/.ssh/id_rsa.pub
```

### 👉 Si no existe

```powershell
ssh-keygen -t rsa -b 4096 -C "tu-email@ejemplo.com"
```

---

## 🌐 Paso 2: Agregar la clave a GitHub

1. Copiá la clave pública:

```powershell
Get-Content ~/.ssh/id_rsa.pub
```

1. En GitHub:

   - Perfil → **Settings** → **SSH and GPG Keys** → **New SSH Key**
   - Pegá la clave, poné un nombre, y guardá.

## 🧪 Paso 3: Probar la conexión

```powershell
ssh -T git@github.com
```

Esperás algo como:

```
Hi tu_usuario! You've successfully authenticated...
```

## 🧠 Paso 4: Clonar tu repositorio desde VSCode

1. `Ctrl + Shift + P` → `Git: Clone`

2. Pegá el link SSH del repo:

```
git@github.com:tu_usuario/tu_repo.git
```

## 💾 Paso 5: Usar Git desde VSCode

1. Modificá y guardá tus archivos (`Ctrl + S`)
2. Panel izquierdo → ícono de ramas (`Ctrl + Shift + G`)
3. Escribí un mensaje de commit y presioná ✔️ o `Ctrl + Enter`
4. Luego hacé `Git: Push` desde:
   - `Ctrl + Shift + P`
   - o menú de tres puntos `...` arriba a la derecha

---

## 🖥️ Terminal integrada

Abrila con:

- `Ctrl + Ñ`
- o `Ver → Terminal`
- o `Ctrl + Shift + \``

Usala para comandos `git` o correr scripts:

```bash
git add .
git commit -m "mensaje"
git push
```

---

## 📌 ¡Listo! Tus cambios ahora se suben a GitHub desde VSCode con seguridad SSH 🎉
