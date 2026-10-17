@echo off
REM Wazuh active-response wrapper (Windows).
REM Wazuh pipes the triggering alert (JSON) to this script on stdin.
REM It simply hands that stdin to the PowerShell script next to it.
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0block-attacker.ps1"
