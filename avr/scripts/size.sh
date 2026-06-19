#!/bin/bash
# computes bootloader size and returns JSON expression to be used by Arduino IDE 2 and arduino-cli
# 1st arg: size program
# 2nd arg: sketch
# 3rd arg: max flash
# 4th arg: max ram
# 5th arg: avrdude path
# 6th arg: config path
# 7th arg: MCU
# 8th arg: bootload name (if any)
bootname="${8##*/}"
bootname="${bootname%:*}"
bootname="${bootname#upgrade_}"
firstpart="${bootname%%_*}"
urboot="${8%:*}"
if [[ -z "$8" ]]; then #if bootload name is empty, use entire flash memory
    boot=0
elif [[ "$urboot" == "-Uurboot" ]]; then #if urboot, make dryrun and extract urboot size
    if [[ $("$5" -c dryrun -p "$7" -C "$6" "$8" -qq 2>/dev/null) ]]; then
        boot=$("$5" -c dryrun -p "$7" -C "$6" "$8" -qq | awk '{print $2}')
    else
        boot=256
    fi
elif [[ "$firstpart" == "original" ]]; then #if original micronucleus, use size of original bootloader
    boot=2180
elif [[ "$firstpart" == "attiny45" ]]; then #if it is any ATtiny45, use sligthly larger size
    boot=1540
else #default: micronucleus new version
    boot=1412
fi
maxflash=$(($3-boot))
maxram=$4
flash=$($1 -A "$2" | grep -E '^(.text|.data)\s+([0-9]+).*' | awk '{s+=$2}END{print s}')
ram=$($1 -A "$2" | grep -E '^(.data|.bss|.noinit)\s+([0-9]+).*' | awk '{s+=$2}END{print s}')
flashpercent=$((flash*100/maxflash))
printf  '{  "output": "Flash memory used: %d bytes out of %d (%d%%).\\n' "$flash" "$maxflash" "$flashpercent"
printf  'RAM used for global variables: %d bytes out of %d.",' "$ram" "$maxram" 
if [[ $ram -gt $maxram ]]; then
    printf '"severity": "error", "error": "Not enough RAM", '
elif [[ $flash -gt $maxflash ]]; then
    printf '"severity": "error", "error": "Sketch is too big", '
else
    printf '"severity": "info", '
fi
printf '"sections": [    { "name": "text", "size": %d, "max_size": %d },' "$flash" $maxflash 
printf '{ "name": "data", "size": %d, "max_size": %d }  ]}' "$ram" "$maxram"
