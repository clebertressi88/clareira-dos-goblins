@echo off
setlocal
set "BASE=%~dp0"
if not exist "%BASE%Atualizador\ClareiraAtualizador.exe" (
 echo Atualizador nao encontrado.
 pause
 exit /b 1
)
start "" "%BASE%Atualizador\ClareiraAtualizador.exe"
