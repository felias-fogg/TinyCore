@echo off
setlocal enabledelayedexpansion
REM Computes size of bootloader and returns JSON expression to be used by Arduino IDE 2 and arduino-cli

REM Arguments - strip surrounding quotes so paths with spaces work in sub-commands
set "sizeprog=%~1"
set "sketch=%~2"
set "maxflash=%~3"
set "maxram=%~4"
set "mcu=%~5"
set "boottype=%~6"

REM Determine bootloader size
if "%boottype%"=="nobootloader" (
    set boot=0
) 
if "%boottype%"=="original_micronucleus" (
    set boot=2180
)
if "%boottype%"=="new_micronucleus" (
    if "%mcu%"=="attiny45" (
        set boot=1540
    ) else (
        set boot=1412
    )
)
if "%boottype%"=="urboot" (
   set boot=256
)


REM Calculate maxflash
if defined boot (
   set /a maxflash=%maxflash% - %boot%
)

REM Calculate flash and RAM from avr-size output
set flash=0
set ram=0
for /f "tokens=1,2" %%a in ('%sizeprog% -A "%sketch%"') do (
    if "%%a"==".text"   set /a flash+=%%b
    if "%%a"==".data"   set /a flash+=%%b
    if "%%a"==".data"   set /a ram+=%%b
    if "%%a"==".bss"    set /a ram+=%%b
    if "%%a"==".noinit" set /a ram+=%%b
)

REM Calculate percentage
set /a flashpercent=flash*100/maxflash

REM Determine severity
set severity=info
if not defined boot (
   set severity=warning
   set errstr="warning": "Could not determine bootloader size",
   set info=Could not determine bootloader size.\n
   )
if %ram% GTR %maxram% (
   set severity=error
   set errstr="error": "Not enough RAM",
   )
if %flash% GTR %maxflash% (
   set severity=error
   set errstr="error": "Sketch is too big",
   )

REM Output JSON
echo {"output": "%info%Flash memory used: %flash% bytes out of %maxflash% (%flashpercent%%%).\nRAM used for global variables: %ram% bytes out of %maxram%.","severity": "%severity%",%errstr%"sections": [{"name": "text","size": %flash%,"max_size": %maxflash%},{"name": "data","size": %ram%,"max_size": %maxram%}]}

exit/b

:LoopLastToken
   set "bootbase=%~1"
   if not "%bootbase:*/=%"=="%~1" (
    call :LoopLastToken "%bootbase:*/=%")
exit/b