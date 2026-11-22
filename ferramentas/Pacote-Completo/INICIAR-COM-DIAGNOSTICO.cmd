@echo off
setlocal
cd /d "%~dp0"
if not exist "%~dp0DIAGNOSTICAR-INICIO.ps1" (echo Falta DIAGNOSTICAR-INICIO.ps1 & pause & exit /b 1)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0DIAGNOSTICAR-INICIO.ps1"
if errorlevel 1 echo Falha no diagnostico. Veja Logs-Inicio.
pause
