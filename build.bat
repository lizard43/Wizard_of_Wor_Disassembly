@echo off
setlocal enabledelayedexpansion

:: 1. ZMAC Location Resolution Hierarchy
if defined ZMAC (
    set "ZMAC_EXE=%ZMAC%"
) else if exist "tools\zmac.exe" (
    set "ZMAC_EXE=tools\zmac.exe"
) else (
    set "ZMAC_EXE=zmac"
)

:: 2. Assemble the Source
echo [BUILD] Assembling wow_disassembly.asm...
if not exist "src\zout" mkdir "src\zout"
"%ZMAC_EXE%" --zmac -o src/zout/wow.bin src/wow_disassembly.asm

if errorlevel 1 (
    echo [ERROR] Assembly failed!
    exit /b 1
)
echo [BUILD] Assembly successful.

:: 3. ROM Slicing (PowerShell 5.1 Compatible)
echo [BUILD] Slicing ROMs for Wizard of Wor memory map...
if not exist "roms" mkdir roms

:: Wizard of Wor standard main program maps to 16KB. 
:: We slice this into four 4KB ($1000 hex) chunks.
powershell -NoProfile -ExecutionPolicy Bypass -Command "^
    $inFile = 'src\zout\wow.bin'; ^
    if (-Not (Test-Path $inFile)) { Write-Error '[ERROR] Binary not found'; exit 1 }; ^
    $bytes = [System.IO.File]::ReadAllBytes($inFile); ^
    $expectedSize = 16384; ^
    if ($bytes.Length -lt $expectedSize) { ^
        Write-Warning ('Binary is smaller than expected 16KB. Found {0} bytes.' -f $bytes.Length); ^
    }; ^
    Write-Host '      -> Writing wow_prog_1.bin (0x0000 - 0x0FFF)'; ^
    [System.IO.File]::WriteAllBytes('roms\wow_prog_1.bin', $bytes[0..4095]); ^
    Write-Host '      -> Writing wow_prog_2.bin (0x1000 - 0x1FFF)'; ^
    [System.IO.File]::WriteAllBytes('roms\wow_prog_2.bin', $bytes[4096..8191]); ^
    Write-Host '      -> Writing wow_prog_3.bin (0x2000 - 0x2FFF)'; ^
    [System.IO.File]::WriteAllBytes('roms\wow_prog_3.bin', $bytes[8192..12287]); ^
    Write-Host '      -> Writing wow_prog_4.bin (0x3000 - 0x3FFF)'; ^
    [System.IO.File]::WriteAllBytes('roms\wow_prog_4.bin', $bytes[12288..16383]); ^
"

if errorlevel 1 (
    echo [ERROR] Slicing failed!
    exit /b 1
)

echo [SUCCESS] Build and slice complete.
endlocal