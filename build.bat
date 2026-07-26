@echo off
setlocal

cd /d "%~dp0"

:: -----------------------------------------------------------------------------
:: Pre-flight Checks & Dependency Resolution
:: -----------------------------------------------------------------------------

:: Resolve zmac executable path
if defined ZMAC (
    if exist "%ZMAC%" (
        set "ZMAC_BIN=%ZMAC%"
    ) else (
        where "%ZMAC%" >nul 2>&1 && set "ZMAC_BIN=%ZMAC%" || (echo ERROR: ZMAC not found & pause & exit /b 1)
    )
) else if exist "tools\zmac.exe" (
    set "ZMAC_BIN=tools\zmac.exe"
) else (
    where zmac >nul 2>&1 && set "ZMAC_BIN=zmac" || (echo ERROR: zmac not found & pause & exit /b 1)
)

:: -----------------------------------------------------------------------------
:: Build Execution
:: -----------------------------------------------------------------------------

echo Wizard of Wor ROM build
echo   source: src\wow_disassembly.asm
echo   output: roms
echo.

echo [1/4] Preparing clean build environment...
if exist "src\zout" rmdir /s /q "src\zout"
mkdir "src\zout"
if not exist "roms" mkdir "roms"

echo [2/4] Assembling wow_disassembly.asm
echo       zmac: %ZMAC_BIN%
"%ZMAC_BIN%" -h -o src\zout\wow_disassembly.hex -x src\zout\wow_disassembly.lst src\wow_disassembly.asm
if %ERRORLEVEL% neq 0 (
    echo ERROR: zmac failed. Review the assembler output above.
    pause
    exit /b %ERRORLEVEL%
)

echo [3/4] Splitting image into Wizard of Wor ROMs (8 Sockets: X1-X8)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$inputFile = 'src\zout\wow_disassembly.hex';" ^
    "$outputDir = 'roms';" ^
    "if (-not (Test-Path $inputFile)) { Write-Error 'Input HEX file missing.'; exit 1 };" ^
    "$memory = [byte[]]::new(0xC000);" ^
    "for ($i = 0; $i -lt 0xC000; $i++) { $memory[$i] = 0xFF };" ^
    "$hexLines = Get-Content $inputFile;" ^
    "foreach ($line in $hexLines) {" ^
    "    if (-not $line.StartsWith(':')) { continue };" ^
    "    $byteCount = [Convert]::ToByte($line.Substring(1, 2), 16);" ^
    "    $address   = [Convert]::ToUInt16($line.Substring(3, 4), 16);" ^
    "    $recordType= [Convert]::ToByte($line.Substring(7, 2), 16);" ^
    "    if ($recordType -eq 0) {" ^
    "        for ($i = 0; $i -lt $byteCount; $i++) {" ^
    "            $dataByte = [Convert]::ToByte($line.Substring(9 + ($i * 2), 2), 16);" ^
    "            $targetAddr = $address + $i;" ^
    "            if ($targetAddr -lt 0xC000) { $memory[$targetAddr] = $dataByte };" ^
    "        }" ^
    "    }" ^
    "};" ^
    "$romMap = [ordered]@{" ^
    "    'wow.x1' = 0x0000..0x0FFF; 'wow.x2' = 0x1000..0x1FFF;" ^
    "    'wow.x3' = 0x2000..0x2FFF; 'wow.x4' = 0x3000..0x3FFF;" ^
    "    'wow.x5' = 0x8000..0x8FFF; 'wow.x6' = 0x9000..0x9FFF;" ^
    "    'wow.x7' = 0xA000..0xAFFF; 'wow.x8' = 0xB000..0xBFFF;" ^
    "};" ^
    "foreach ($romName in $romMap.Keys) {" ^
    "    $slice = $memory[$romMap[$romName]];" ^
    "    [System.IO.File]::WriteAllBytes((Join-Path $outputDir $romName), $slice);" ^
    "    Write-Host ('  -> Wrote ' + $romName + ' (' + $slice.Length + ' bytes)');" ^
    "}"

if %ERRORLEVEL% neq 0 (
    echo ERROR: ROM slicing failed.
    pause
    exit /b %ERRORLEVEL%
)

echo [4/4] Packaging roms\wow.zip...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$romFiles = Get-ChildItem -Path 'roms\wow.x?';" ^
    "Compress-Archive -Path $romFiles.FullName -DestinationPath 'roms\wow.zip' -Force"

if %ERRORLEVEL% neq 0 (
    echo ERROR: Packaging failed.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo =======================================================================
echo  BUILD SUCCESSFUL!
echo =======================================================================
pause