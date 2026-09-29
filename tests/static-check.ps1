$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$sh = 'C:\Program Files\Git\bin\sh.exe'
if (-not (Test-Path $sh)) { throw 'Git Bash sh.exe no está disponible' }
& $sh (Join-Path $PSScriptRoot 'static-check.sh')
if ($LASTEXITCODE -ne 0) { throw 'static-check.sh falló' }
& $sh (Join-Path $PSScriptRoot 'profile-parser-test.sh')
if ($LASTEXITCODE -ne 0) { throw 'profile-parser-test.sh falló' }
Write-Output 'STATIC_CHECK_WINDOWS=PASS'
