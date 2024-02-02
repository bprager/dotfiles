#!/usr/bin/env bash
powershell.exe -Command "Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = TRUE' | ForEach-Object { if (\$_.Description -like '*Realtek USB GbE Family Controller*') { \$_.IPAddress[0] }}"
