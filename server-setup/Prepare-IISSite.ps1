<#
    Prepare-IISSite.ps1
    Ejecutar EN el Windows Server Core, con PowerShell como Administrador.
    Crea un sitio y app pool dedicados para HelloWorldApp en el puerto 8080,
    sin tocar "Default Web Site". Deja los permisos necesarios para que:
      - el App Pool pueda servir los archivos (IIS_IUSRS)
      - el runner de GitHub Actions (corre como NT AUTHORITY\NETWORK SERVICE)
        pueda escribir ahí durante el deploy (robocopy)
#>

param(
    [string]$SiteName = "HelloWorldApp",
    [int]$Port = 8080,
    [string]$PhysicalPath = "C:\inetpub\HelloWorldApp"
)

$ErrorActionPreference = "Stop"

Write-Host "== 1) Asegurar herramientas de administración de IIS (cmdlets WebAdministration) ==" -ForegroundColor Cyan
Install-WindowsFeature Web-Scripting-Tools -ErrorAction SilentlyContinue | Out-Null
Import-Module WebAdministration

Write-Host "== 2) Crear carpeta física del sitio ==" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $PhysicalPath -Force | Out-Null

Write-Host "== 3) Crear App Pool dedicado (.NET CLR v4.0, para 4.8.1) ==" -ForegroundColor Cyan
if (-not (Test-Path "IIS:\AppPools\$SiteName")) {
    New-WebAppPool -Name $SiteName | Out-Null
}
Set-ItemProperty "IIS:\AppPools\$SiteName" -Name managedRuntimeVersion -Value "v4.0"
Set-ItemProperty "IIS:\AppPools\$SiteName" -Name enable32BitAppOnWin64 -Value $false

Write-Host "== 4) Crear el sitio en el puerto $Port ==" -ForegroundColor Cyan
if (Get-Website -Name $SiteName -ErrorAction SilentlyContinue) {
    Write-Host "El sitio '$SiteName' ya existe, se reutiliza." -ForegroundColor Yellow
} else {
    New-Website -Name $SiteName -Port $Port -PhysicalPath $PhysicalPath -ApplicationPool $SiteName | Out-Null
}

Write-Host "== 5) Permisos: IIS_IUSRS (lectura) y NETWORK SERVICE (deploy) ==" -ForegroundColor Cyan
icacls $PhysicalPath /grant "IIS_IUSRS:(OI)(CI)RX" /T | Out-Null
icacls $PhysicalPath /grant "NT AUTHORITY\NETWORK SERVICE:(OI)(CI)F" /T | Out-Null

Write-Host ""
Write-Host "Listo." -ForegroundColor Green
Write-Host "  Sitio:          $SiteName"
Write-Host "  Puerto:         $Port"
Write-Host "  Path fisico:    $PhysicalPath"
Write-Host ""
Write-Host "Prueba local (no necesita ningun puerto abierto en el Security Group):" -ForegroundColor Yellow
Write-Host "  Invoke-WebRequest http://localhost:$Port -UseBasicParsing"
Write-Host ""
Write-Host "Si luego quieres verlo desde tu navegador (internet), ahi si necesitas" -ForegroundColor Yellow
Write-Host "abrir el puerto $Port en el Security Group de la instancia (TCP, tu IP o 0.0.0.0/0)." -ForegroundColor Yellow
