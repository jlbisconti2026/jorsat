<#
.SYNOPSIS
    Script para importar la configuración de Entornos y Grupos de Entornos a Apigee desde archivos JSON.
.NOTES
    Requisitos: Tener instalado gcloud CLI y estar autenticado (gcloud auth login).
#>

[CmdletBinding()]
param(
    [string]$Organization = "claup-apigee-hybrid-desa",
    [string]$EnvGroupsFile = ".\environment_groups.json",
    [string]$EnvironmentsFile = ".\environments_list.json"
)

# 1. Obtener Token de Acceso desde gcloud
Write-Host "Obteniendo token de autenticación de GCP..." -ForegroundColor Cyan
try {
    $Token = (gcloud auth print-access-token)
    if ([string]::IsNullOrWhiteSpace($Token)) {
        throw "No se pudo obtener el token. Ejecutá 'gcloud auth login' primero."
    }
} catch {
    Write-Host "ERROR: Error al obtener el token de gcloud. $_" -ForegroundColor Red
    exit 1
}

$Headers = @{
    Authorization  = "Bearer $Token"
    "Content-Type" = "application/json"
}

# ---------------------------------------------------------------------------
# 2. IMPORTAR GRUPOS DE ENTORNOS (Environment Groups)
# ---------------------------------------------------------------------------
if (Test-Path $EnvGroupsFile) {
    Write-Host "`n--- Procesando Grupos de Entornos desde: $EnvGroupsFile ---" -ForegroundColor Yellow
    
    $RawJson = Get-Content -Raw -Encoding utf8 $EnvGroupsFile | ConvertFrom-Json
    
    # Maneja si el JSON es un Array directo o una propiedad 'environmentGroups' / 'envGroups'
    $Groups = if ($RawJson.environmentGroups) { $RawJson.environmentGroups } 
              elseif ($RawJson.envGroups) { $RawJson.envGroups } 
              else { $RawJson }

    foreach ($group in $Groups) {
        $GroupName = $group.name
        $Hostnames = $group.hostnames

        Write-Host "Subiendo grupo: '$GroupName'..." -NoNewline

        # Filtramos solo los campos necesarios que la API de Apigee acepta para POST
        $BodyPayload = @{
            name      = $GroupName
            hostnames = $Hostnames
        } | ConvertTo-Json -Depth 5 -Compress

        $Uri = "https://apigee.googleapis.com/v1/organizations/$Organization/envgroups"

        try {
            $response = Invoke-RestMethod -Uri $Uri -Method POST -Headers $Headers -Body $BodyPayload
            Write-Host " [OK]" -ForegroundColor Green
        } catch {
            # Si ya existe o hay un tema de formato, mostramos la advertencia sin cortar la ejecución
            Write-Host " [OMITIDO / ERROR]" -ForegroundColor Yellow
            Write-Host " -> Detalle: $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "ADVERTENCIA: No se encontró el archivo $EnvGroupsFile. Se saltea esta etapa." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# 3. IMPORTAR ENTORNOS (Environments)
# ---------------------------------------------------------------------------
if (Test-Path $EnvironmentsFile) {
    Write-Host "`n--- Procesando Entornos desde: $EnvironmentsFile ---" -ForegroundColor Yellow

    $RawJson = Get-Content -Raw -Encoding utf8 $EnvironmentsFile | ConvertFrom-Json
    
    $Envs = if ($RawJson.environments) { $RawJson.environments } else { $RawJson }

    foreach ($env in $Envs) {
        # Extrae el nombre si el objeto tiene 'name' o si es un string directo
        $EnvName = if ($env.name) { $env.name } else { $env }

        Write-Host "Creando entorno: '$EnvName' con gcloud..."
        
        # Usamos gcloud nativo para la creación del entorno
        gcloud apigee environments create $EnvName --organization=$Organization
    }
} else {
    Write-Host "ADVERTENCIA: No se encontró el archivo $EnvironmentsFile. Se saltea esta etapa." -ForegroundColor Yellow
}

Write-Host "`nProceso finalizado." -ForegroundColor Green