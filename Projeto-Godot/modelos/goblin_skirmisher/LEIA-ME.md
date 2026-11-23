# Goblin Skirmisher — dependência externa para teste

Pacote original do autor G4G Assets (gratuito):
https://g4g-assets.itch.io/goblin-skirmisher-100-animations

Baixe **GoblinSkirmisher-Godot-1.0.0.zip** pelo fluxo oficial do itch.io
("Download Now" -> "No thanks, just take me to the downloads").

O ZIP **não está incluído neste repositório**. Extraia os arquivos do pacote
Godot e preserve a estrutura de modelos e texturas nesta pasta:

`Projeto-Godot/modelos/goblin_skirmisher/`

A cena de testes `res://experimentos/goblin_skirmisher_teste.tscn`
procura arquivos `.glb` / `.gltf` de forma recursiva e seleciona
preferencialmente o que contém Skeleton3D + AnimationPlayer.
Se o pacote trouxer animações em bibliotecas separadas ou referências
`res://` absolutas, será necessário adaptá-las após inspecionar o ZIP.

Os modelos de terceiros e suas animações seguem a **licença do autor**:
uso em jogos prontos permitido, mas não redistribuir o pacote como asset isolado.
Consultar LICENSE do ZIP original para condições completas.

**Status:** somente infraestrutura de avaliação criada. É necessário baixar
o ZIP original, integrá-lo e testar as animações antes de substituir
jogador ou NPCs em produção.

Não modifica mundo, save, inventário ou sincronização multiplayer.
