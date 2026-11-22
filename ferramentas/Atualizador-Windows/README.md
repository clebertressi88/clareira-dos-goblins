# Atualizador Clareira dos Goblins para Windows

Aplicativo com interface grafica que clona ou atualiza o projeto Godot do repositorio privado clebertressi88/clareira-dos-goblins.

## Download do executavel
Acesse GitHub > Actions > Compilar Atualizador Windows > ultima execucao concluida > Artifacts > Clareira-Atualizador-Windows-x64. Extraia e abra ClareiraAtualizador.exe.

## Requisitos e primeiro uso
1. Windows 10/11 x64.
2. Instalar Git para Windows: https://git-scm.com/download/win
3. Instalar GitHub CLI: https://cli.github.com/
4. Abrir o aplicativo e clicar Conectar GitHub para autorizar o acesso ao repositorio privado.
5. Escolher uma pasta vazia para primeiro download OU uma pasta que ja seja um clone Git deste projeto.
6. Escolher main (estavel) ou feature/paisagem-montanhas-rios-regeneracao (experimental).
7. Clicar em Baixar / Atualizar agora. Para desenvolver, abrir Projeto-Godot/project.godot no Godot.

Se a pasta original foi criada sem .git, faca o primeiro download em outra pasta vazia. O app nao substitui arquivos existentes nem converte pastas nao versionadas.

## Atualizacao automatica
Com o programa ABERTO, consulta o GitHub a cada 10 minutos e baixa commits novos. Ele nao roda como servico do Windows.

## Protecao dos arquivos
- Confirma que o remote Git corresponde ao repositorio.
- Recusa pastas nao versionadas com arquivos, modificacoes locais e commits divergentes.
- Usa git fetch e git merge --ff-only, sem reset --hard, clean nem push.
- Nao armazena senhas ou tokens, autenticacao feita pelo GitHub CLI.
- Preferencias em %LOCALAPPDATA%/ClareiraDosGoblins/atualizador.json.
- Saves do Godot em user:// nao sao alterados.

## Compilacao manual
No Windows com SDK .NET 8: dotnet publish AtualizadorClareira.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o dist

O app atualiza o codigo-fonte, nao exporta o jogo em EXE. A branch da paisagem continua experimental.