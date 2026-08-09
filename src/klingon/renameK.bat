@echo off
setlocal
cd /d "%~dp0"

set "ROM_DIR=..\..\roms"
set "SRC_ZIP=%ROM_DIR%\wowk.zip"
set "DST_ZIP=%ROM_DIR%\wowg.zip"

if not exist "%SRC_ZIP%" (
    echo ERROR: %SRC_ZIP% not found.
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$src = [System.IO.Path]::GetFullPath('%SRC_ZIP%');" ^
    "$dst = [System.IO.Path]::GetFullPath('%DST_ZIP%');" ^
    "$work = Join-Path ([System.IO.Path]::GetTempPath()) ('wowk-' + [Guid]::NewGuid().ToString('N'));" ^
    "try {" ^
    "    New-Item -ItemType Directory -Path $work | Out-Null;" ^
    "    Expand-Archive -LiteralPath $src -DestinationPath $work -Force;" ^
    "    $klingon = Join-Path $work 'klingon.x11';" ^
    "    if (-not (Test-Path $klingon)) { throw 'klingon.x11 was not found in wowk.zip.' };" ^
    "    Rename-Item -LiteralPath $klingon -NewName 'german.x11';" ^
    "    if (Test-Path $dst) { Remove-Item -LiteralPath $dst -Force };" ^
    "    Compress-Archive -Path (Join-Path $work '*') -DestinationPath $dst -Force;" ^
    "} finally {" ^
    "    if (Test-Path $work) { Remove-Item -LiteralPath $work -Recurse -Force };" ^
    "}"

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to create %DST_ZIP%.
    exit /b %ERRORLEVEL%
)

echo Created %DST_ZIP% with klingon.x11 renamed to german.x11.
exit /b 0
