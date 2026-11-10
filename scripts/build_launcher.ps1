param(
    [switch]$SkipWebBuild
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

if (-not $SkipWebBuild) {
    Push-Location "$root\flutter_app"
    & "$root\scripts\flutter.cmd" build web --release
    Pop-Location
    if ($LASTEXITCODE -ne 0) {
        throw "La compilacion web fallo."
    }
}

if (-not (Test-Path "$root\.venv\Scripts\python.exe")) {
    throw "No se encontro el entorno virtual en $root\.venv."
}

& "$root\.venv\Scripts\python.exe" -m PyInstaller `
    --onefile `
    --windowed `
    --name MarcanoControl `
    --distpath "$root" `
    --workpath "$root\.tools\pyinstaller" `
    --specpath "$root\.tools\pyinstaller" `
    "$root\launcher\control.py"

if ($LASTEXITCODE -ne 0) {
    throw "La compilacion del panel de control fallo."
}

Write-Host "Ejecutable creado en $root\MarcanoControl.exe"
