# Laboratorio do Desenvolvedor (programa separado)

Aplicativo Windows independente do jogo **Clareira dos Goblins**.
Abre diretamente em um mundo plano (160 x 160 m), sem arvores, mato,
rios, criaturas nem construcao inicial.

## Ferramentas

- **F6 / Esc**: abrir e fechar painel de desenvolvedor.
- **Inventario criativo**: pesquisar no catalogo todos os itens reais do
  jogo, adicionar 1 ou 64 unidades e colocar na hotbar. Tambem e possivel
  abastecer todos os materiais com 64 unidades.
- **Crafting de verdade**: abrir a grade 2x2, bancada nivel 1 ou 2 (3x3)
  e marcenaria (5x5), mantendo as receitas e a interacao do jogo original.
  A bancada e criada automaticamente ao lado do jogador ao iniciar o teste.
- **Criaturas sob demanda**: lobo predador, coelho, goblin guardiao e NPCs
  Bruma e Talo. Aparecem somente quando solicitados e podem ser removidos.
- **Construcoes**: colocar paredes, pisos, escadas, portas, baus e outros
  itens usando o mesmo sistema do jogo; limpar estruturas quando desejar.
- **Testes**: invulnerabilidade opcional, alternancia de dia/noite,
  teleporte ao centro e grade de referencia a cada 10 m.

## Separacao real

Os arquivos do laboratorio ficam em `Laboratorio-Desenvolvedor/`, fora
do projeto Godot do jogo. A compilacao copia **temporariamente** o conteudo
de `Projeto-Godot/`, adiciona somente a cena e script de desenvolvimento
e muda a cena inicial e o nome do aplicativo **na copia temporaria**.

O executavel e nomeado `Clareira-Laboratorio-Dev.exe` e publicado numa
Release diferente da Release do jogo (`laboratorio-dev-windows`).
O laboratorio sobrescreve `save_game()` para nao gravar os arquivos dos
mundos e nao chama `load_game()` na inicializacao. O Godot tambem utiliza
o nome de projeto `Laboratorio Dev da Clareira` para separar os dados
de usuario do aplicativo.

## Desenvolver localmente

No PowerShell, em uma copia do repositorio:

```powershell
$stage = Join-Path $env:TEMP 'clareira-lab-local'
Copy-Item -Recurse -Force Projeto-Godot $stage
Copy-Item Laboratorio-Desenvolvedor/laboratorio_dev.gd $stage
Copy-Item Laboratorio-Desenvolvedor/laboratorio_dev.tscn $stage
$project = Join-Path $stage 'project.godot'
$txt = [System.IO.File]::ReadAllText($project)
$txt = $txt.Replace('config/name="Clareira dos Goblins"','config/name="Laboratorio Dev da Clareira"').Replace('run/main_scene="res://main.tscn"','run/main_scene="res://laboratorio_dev.tscn"')
[System.IO.File]::WriteAllText($project,$txt,(New-Object System.Text.UTF8Encoding($false)))
# Abra $stage/project.godot no Godot, ou execute:
# Godot --path $stage
```

A rotina `.github/workflows/publicar-laboratorio-dev.yml` efetua isso
automaticamente no runner Windows e prepara o ZIP.
