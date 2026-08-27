<!-- markdownlint-disable MD046 -->

# Guía Paso a Paso -- Fix de Inicio de Sesión

1. [Microsoft Teams (Clásico y Nuevo) + Outlook](#microsoft-teams-clásico-y-nuevo--outlook)
2. [🔹 PASO 1 -- Guardar el Script](#-paso-1----guardar-el-script)
3. [🔹 PASO 2 -- Permitir ejecución (una sola vez)](#-paso-2----permitir-ejecución-una-sola-vez)
4. [🔹 PASO 3 -- Ejecutar FIX (modo normal)](#-paso-3----ejecutar-fix-modo-normal)
5. [🔹 PASO 4 -- Reiniciar Windows (Recomendado)](#-paso-4----reiniciar-windows-recomendado)
6. [🔹 PASO 5 -- Si sigue el problema (Modo AGRESIVO)](#-paso-5----si-sigue-el-problema-modo-agresivo)
7. [🔍 Verificación Técnica](#-verificación-técnica)
8. [Verificar que Teams nuevo esté instalado](#verificar-que-teams-nuevo-esté-instalado)
9. [Verificar Outlook instalado](#verificar-outlook-instalado)
10. [🧪 Diagnóstico adicional (si persiste)](#-diagnóstico-adicional-si-persiste)
11. [✅ Resultado Esperado](#-resultado-esperado)

## Microsoft Teams (Clásico y Nuevo) + Outlook

### Windows 11

🎯 Objetivo

Resolver problemas de inicio de sesión cuando: - Teams queda en "Signing
in..." - Outlook pide credenciales en loop - Aparece "Something went
wrong" - Pantalla en blanco - Las credenciales son correctas pero no
autentica

## 🔹 PASO 1 -- Guardar el Script

1. Crear archivo:

        Fix-TeamsOutlookSignIn-W11.ps1

2. Pegar el script corregido.

3. Guardarlo en una carpeta local (por ejemplo: `C:\Scripts`).

## 🔹 PASO 2 -- Permitir ejecución (una sola vez)

Abrir PowerShell como usuario normal:

```bash
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## 🔹 PASO 3 -- Ejecutar FIX (modo normal)

Desde la carpeta donde está el script:

``` powershell
.\Fix-TeamsOutlookSignIn-W11.ps1
```

El script hará:

- Cerrar Teams y Outlook
- Limpiar caché Teams clásico
- Limpiar caché Teams nuevo
- Limpiar tokens Office / OneAuth
- Resetear WAM (AAD Broker)
- Reiniciar servicios clave

## 🔹 PASO 4 -- Reiniciar Windows (Recomendado)

Después de ejecutar el script:

1. Reiniciar el equipo
2. Abrir primero Outlook
3. Luego abrir Teams

## 🔹 PASO 5 -- Si sigue el problema (Modo AGRESIVO)

Ejecutar:

```powershell
.\Fix-TeamsOutlookSignIn-W11.ps1 -Aggressive
```

Esto además: - Borra credenciales guardadas en Administrador de
Credenciales - Fuerza re-login completo

⚠️ Puede pedir autenticación nuevamente en apps Microsoft.

## 🔍 Verificación Técnica

## Verificar que WAM esté activo

``` powershell
Get-Service WebAccountManager
```

Debe estar en estado: `Running`

## Verificar que Teams nuevo esté instalado

``` powershell
Get-AppxPackage *MSTeams*
```

## Verificar Outlook instalado

```bash
Get-Item "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
```

## 🧪 Diagnóstico adicional (si persiste)

- Confirmar conexión a:
  - <https://login.microsoftonline.com>
  - <https://teams.microsoft.com>
- Verificar que no haya proxy interceptando TLS
- Confirmar que WebView2 esté instalado

------------------------------------------------------------------------

## ✅ Resultado Esperado

Después del fix:

- Outlook inicia sesión sin pedir contraseña repetidamente
- Teams abre normalmente
- No hay loops de autenticación
- No hay pantalla blanca

------------------------------------------------------------------------

## 📌 Notas Importantes

- Este procedimiento no elimina perfiles de Outlook.
- No elimina correos locales.
- Solo limpia tokens y caché de autenticación.
- Recomendado en entornos Microsoft 365.

------------------------------------------------------------------------

**Fin de la guía.**
