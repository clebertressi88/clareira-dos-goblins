@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Clareira dos Goblins - Gerar Windows Corrigido
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GERAR-EXE-WINDOWS-CORRIGIDO.ps1"
set RESULTADO=%ERRORLEVEL%
echo.
if not "%RESULTADO%"=="0" (
  echo Nao foi possivel gerar o EXE. Consulte a pasta logs-geracao.
) else (
  echo Build concluido. Abra a pasta Windows-Atualizado.
)
echo.
pause
exit /b %RESULTADO%
