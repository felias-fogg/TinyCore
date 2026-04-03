@echo off
setlocal enabledelayedexpansion

REM Argumente
set sizeprog=%1
set sketch=%2
set maxflash=%3
set maxram=%4
set avrdude=%5
set config=%6
set mcu=%7
set bootname=%8

REM Bootloader-Größe bestimmen
if "%bootname%"=="" (
    set boot=0
) else (
    for /f "tokens=2" %%a in ('%avrdude% -c dryrun -p %mcu% -C %config% %bootname% -qq 2^>nul') do (
        set boot=%%a
    )
    if not defined boot (
        set boot=256
    )
)
echo %boot%

REM maxflash berechnen
set /a maxflash=%maxflash% - %boot%

REM Flash berechnen
set flash=0
for /f "tokens=1,2" %%a in ('%sizeprog% -A %sketch% ^| findstr /r "^\.text ^\.data"') do (
    set /a flash+=%%b
)

REM RAM berechnen
set ram=0
for /f "tokens=1,2" %%a in ('%sizeprog% -A %sketch% ^| findstr /r "^\.data ^\.bss ^\.noinit"') do (
    set /a ram+=%%b
)

REM Prozent berechnen
set /a flashpercent=flash*100/maxflash

REM Ausgabe starten
<nul set /p="{
  "output": "Flash memory used: %flash% bytes of out of %maxflash% (%flashpercent%%%).
"

<nul set /p="RAM used for global variables: %ram% bytes out of %maxram%. %avrdude% %config% %mcu% %bootname%","

REM Severity
if %ram% GTR %maxram% (
    set severity=error
) else if %flash% GTR %maxflash% (
    set severity=error
) else (
    set severity=info
)

<nul set /p=""severity": "%severity%","

REM Sections
echo "sections": [
    { "name": "text", "size": %flash%, "max_size": %maxflash% },
    { "name": "data", "size": %ram%, "max_size": %maxram% }
  ]
}