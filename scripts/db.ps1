param(
    [Parameter(Position = 0)]
    [ValidateSet("start", "stop", "status")]
    [string]$Action = "status"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$pgCtl = Join-Path $root ".tools\postgresql\bin\pg_ctl.exe"
$data = Join-Path $root "data\postgresql"
$log = Join-Path $root "data\postgresql.log"

if (-not (Test-Path $pgCtl)) {
    throw "PostgreSQL no esta instalado en $root\.tools\postgresql."
}

switch ($Action) {
    "start" {
        & $pgCtl -D $data -l $log -o "-p 5433" -w start
    }
    "stop" {
        & $pgCtl -D $data -m fast -w stop
    }
    "status" {
        & $pgCtl -D $data status
    }
}
exit $LASTEXITCODE
