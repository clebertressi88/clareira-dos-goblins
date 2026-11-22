@echo off
setlocal
set "BASE=%~dp0"
if not exist "%BASE%Ferramentas\Godot.exe" (
 echo Nao encontrado Godot.exe
 pause
 exit /b 1
)
start "" "%BASE%Ferramentas\Godot.exe" --editor --path "%BASE%Codigo-Fonte\Projeto-Godot"
