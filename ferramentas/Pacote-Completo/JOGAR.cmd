@echo off
setlocal
set "BASE=%~dp0"
if exist "%BASE%Jogo-Windows\Clareira-dos-Goblins.exe" (
  start "" "%BASE%Jogo-Windows\Clareira-dos-Goblins.exe"
  exit /b 0
)
if not exist "%BASE%Ferramentas\Godot.exe" (
  echo Nao foi encontrado Godot.exe na pasta Ferramentas.
  pause
  exit /b 1
)
start "" "%BASE%Ferramentas\Godot.exe" --path "%BASE%Codigo-Fonte\Projeto-Godot"
