@echo off
setlocal
cd /d "%~dp0"

:: -----------------------------------------------------------------------------
:: Argument Parsing
:: -----------------------------------------------------------------------------
set "BUILD_GERMAN=false"
set "BUILD_KLINGON=false"

:parse_args
if "%~1"=="" goto args_done
if "%~1"=="--german" (
    set "BUILD_GERMAN=true"
    shift
    goto parse_args
)
if "%~1"=="-g" (
    set "BUILD_GERMAN=true"
    shift
    goto parse_args
)
if "%~1"=="--klingon" (
    set "BUILD_KLINGON=true"
    shift
    goto parse_args
)
if "%~1"=="-klingon" (
    set "BUILD_KLINGON=true"
    shift
    goto parse_args
)
if "%~1"=="-k" (
    set "BUILD_KLINGON=true"
    shift
    goto parse_args
)
if "%~1"=="--help" (
    echo Usage: build.bat [options]
    echo Options:
    echo   -g, --german              Assemble German language expansion and include it in wow.zip
    echo   -k, -klingon, --klingon   Assemble Klingon language expansion and include it in wowk.zip
    echo   --help                     Display this help message
    exit /b 0
)
echo ERROR: Unknown argument %1
exit /b 1
:args_done

if "%BUILD_GERMAN%"=="true" if "%BUILD_KLINGON%"=="true" (
    echo ERROR: Select either German or Klingon, not both.
    exit /b 1
)

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
echo source: src\wow_disassembly.asm
echo output: roms
if "%BUILD_GERMAN%"=="true" (
    echo options: +German Translation
)
if "%BUILD_KLINGON%"=="true" (
    echo options: +Klingon Translation
)
echo.

echo [1/4] Preparing clean build environment...
if exist "src\zout" rmdir /s /q "src\zout"
mkdir "src\zout"
if not exist "roms" mkdir "roms"
if exist "roms\german.x11" del /f /q "roms\german.x11"
if "%BUILD_KLINGON%"=="true" (
    if exist "roms\klingon.x11" del /f /q "roms\klingon.x11"
    if exist "roms\wowk.zip" del /f /q "roms\wowk.zip"
)

echo [2/4] Assembling wow_disassembly.asm
echo zmac: %ZMAC_BIN%
"%ZMAC_BIN%" -h -o src\zout\wow_disassembly.hex -x src\zout\wow_disassembly.lst src\wow_disassembly.asm
if %ERRORLEVEL% neq 0 (
    echo ERROR: zmac failed. Review the assembler output above.
    pause
    exit /b %ERRORLEVEL%
)

:: Conditional German Assembly Step
if "%BUILD_GERMAN%"=="true" (
    echo [2.5/4] Assembling German Language Expansion: GERMAN_X11.asm
    "%ZMAC_BIN%" -h -o src\zout\GERMAN_X11.hex -x src\zout\GERMAN_X11.lst src\german\GERMAN_X11.asm
    if %ERRORLEVEL% neq 0 (
        echo ERROR: zmac failed on German translation file.
        pause
        exit /b %ERRORLEVEL%
    )
    
    :: Convert German HEX output directly to its fixed binary destination file via PowerShell
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$inputFile = 'src\zout\GERMAN_X11.hex';" ^
        "if (-not (Test-Path $inputFile)) { Write-Error 'German HEX file missing.'; exit 1 };" ^
        "$lines = Get-Content $inputFile;" ^
        "$bytes = [System.Collections.Generic.List[byte]]::new();" ^
        "foreach ($line in $lines) {" ^
        "    if (-not $line.StartsWith(':')) { continue };" ^
        "    $byteCount = [Convert]::ToByte($line.Substring(1, 2), 16);" ^
        "    $recordType = [Convert]::ToByte($line.Substring(7, 2), 16);" ^
        "    if ($recordType -eq 0) {" ^
        "        for ($i = 0; $i -lt $byteCount; $i++) {" ^
        "            $bytes.Add([Convert]::ToByte($line.Substring(9 + ($i * 2), 2), 16));" ^
        "        }" ^
        "    }" ^
        "};" ^
        "[System.IO.File]::WriteAllBytes('roms\german.x11', $bytes.ToArray());" ^
        "Write-Host '  -> Created roms\german.x11 (' $bytes.Count 'bytes)';"
        
    if %ERRORLEVEL% neq 0 (
        echo ERROR: German translation conversion failed.
        pause
        exit /b %ERRORLEVEL%
    )
)


:: Conditional Klingon Assembly Step
if "%BUILD_KLINGON%"=="true" (
    echo [2.5/4] Assembling Klingon Language Expansion: KLINGON_X11.asm
    "%ZMAC_BIN%" -h -o src\zout\KLINGON_X11.hex -x src\zout\KLINGON_X11.lst src\klingon\KLINGON_X11.asm
    if %ERRORLEVEL% neq 0 (
        echo ERROR: zmac failed on Klingon translation file.
        pause
        exit /b %ERRORLEVEL%
    )

    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$inputFile = 'src\zout\KLINGON_X11.hex';" ^
        "if (-not (Test-Path $inputFile)) { Write-Error 'Klingon HEX file missing.'; exit 1 };" ^
        "$lines = Get-Content $inputFile;" ^
        "$bytes = [System.Collections.Generic.List[byte]]::new();" ^
        "foreach ($line in $lines) {" ^
        "    if (-not $line.StartsWith(':')) { continue };" ^
        "    $byteCount = [Convert]::ToByte($line.Substring(1, 2), 16);" ^
        "    $recordType = [Convert]::ToByte($line.Substring(7, 2), 16);" ^
        "    if ($recordType -eq 0) {" ^
        "        for ($i = 0; $i -lt $byteCount; $i++) {" ^
        "            $bytes.Add([Convert]::ToByte($line.Substring(9 + ($i * 2), 2), 16));" ^
        "        }" ^
        "    }" ^
        "};" ^
        "[System.IO.File]::WriteAllBytes('roms\klingon.x11', $bytes.ToArray());" ^
        "Write-Host '  -> Created roms\klingon.x11 (' $bytes.Count 'bytes)';"

    if %ERRORLEVEL% neq 0 (
        echo ERROR: Klingon translation conversion failed.
        pause
        exit /b %ERRORLEVEL%
    )
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
    "    $address = [Convert]::ToUInt16($line.Substring(3, 4), 16);" ^
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
    "    };" ^
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

if "%BUILD_KLINGON%"=="true" (
    set "TARGET_ZIP=roms\wowk.zip"
    echo [4/4] Packaging roms\wowk.zip...
) else (
    set "TARGET_ZIP=roms\wow.zip"
    echo [4/4] Packaging roms\wow.zip...
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$filesToZip = [System.Collections.Generic.List[string]]::new();" ^
    "(Get-ChildItem -Path 'roms\wow.x?').FullName | ForEach-Object { $filesToZip.Add($_) };" ^
    "$speechRom = 'roms\sc01a.bin';" ^
    "if (Test-Path $speechRom) { $filesToZip.Add((Get-Item $speechRom).FullName); Write-Host '  -> Including Votrax speech ROM (sc01a.bin)' };" ^
    "if ('%BUILD_GERMAN%' -eq 'true') {" ^
    "    $germanRom = 'roms\german.x11';" ^
    "    if (Test-Path $germanRom) { $filesToZip.Add((Get-Item $germanRom).FullName); Write-Host '  -> Including German language ROM (german.x11)' } else { throw 'German ROM file was missing before zip phase.' }" ^
    "};" ^
    "if ('%BUILD_KLINGON%' -eq 'true') {" ^
    "    $klingonRom = 'roms\klingon.x11';" ^
    "    if (Test-Path $klingonRom) { $filesToZip.Add((Get-Item $klingonRom).FullName); Write-Host '  -> Including Klingon language ROM (klingon.x11)' } else { throw 'Klingon ROM file was missing before zip phase.' }" ^
    "};" ^
    "Compress-Archive -Path $filesToZip -DestinationPath '%TARGET_ZIP%' -Force"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Packaging failed.
    pause
    exit /b %ERRORLEVEL%
)

if "%BUILD_KLINGON%"=="true" (
    echo [4.5/4] Creating MAME-compatible Klingon archive...
    call "src\klingon\renameK.bat"
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Could not create MAME-compatible Klingon archive.
        pause
        exit /b %ERRORLEVEL%
    )
    echo   -^> Created roms\wowg.zip with Klingon X11 stored as german.x11
)

echo.
echo =======================================================================
echo BUILD SUCCESSFUL!
if "%BUILD_KLINGON%"=="true" (
    echo Klingon project archive: roms\wowk.zip
    echo MAME runtime archive:    roms\wowg.zip
)
echo =======================================================================
pause
