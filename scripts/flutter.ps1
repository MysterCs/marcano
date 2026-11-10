param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root ".tools"
$flutterBin = Join-Path $tools "flutter\bin"
$gitCmd = Join-Path $tools "git\cmd"

if (-not (Test-Path (Join-Path $flutterBin "flutter.bat"))) {
    throw "Flutter no esta instalado en $tools\flutter."
}
if (-not (Test-Path (Join-Path $gitCmd "git.exe"))) {
    throw "Git portatil no esta instalado en $tools\git."
}

$env:PATH = "$flutterBin;$gitCmd;$env:PATH"
$env:PUB_CACHE = Join-Path $tools "pub-cache"
$env:HOME = Join-Path $tools "home"
$env:GIT_CONFIG_GLOBAL = Join-Path $env:HOME ".gitconfig"
$env:FLUTTER_SUPPRESS_ANALYTICS = "true"

& (Join-Path $flutterBin "flutter.bat") @FlutterArgs
exit $LASTEXITCODE
