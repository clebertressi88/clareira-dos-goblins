# Goblin Skirmisher — modelo original para o laboratório

O usuario forneceu o arquivo `GoblinSkirmisher-Godot-1.0.0.zip` do autor G4G Assets.

## Cena a instalar

`res://modelos/goblin_skirmisher/Character/GoblinSkirmisher.scn`

Este é um arquivo binário nativo do Godot 4.7.2 (~35 MB), não um GLB.
Os nomes e IDs das animações são encontrados em `animation-index.json`.
Instale preservando `Character/GoblinSkirmisher.scn`, `animation-index.json`
e os avisos de licença do pacote original.

## Como visualizar

No jogo: Menu Inicial > Laboratório de Skin > Testar Goblin Skirmisher.

À esquerda: goblin anterior. À direita: modelo G4G real.
Use os botões Parado, Andar, Correr, Atacar, Receber dano, Morrer,
Próxima/anterior animação, Adaga, Girar e Zoom.

Os scripts estão na branch `teste-goblin-skirmisher`.
O arquivo `.scn` precisa ser inserido nessa branch por uma cópia local
autenticada antes de compilar a Release Windows. O pacote gerado para o
usuário inclui um instalador PowerShell que faz esse envio e valida no Godot.

## Licença

A licença G4G 1.0 permite integração nos jogos comerciais ou pessoais,
mas proíbe redistribuir o asset como pacote avulso. Mantenha o
repositório de desenvolvimento privado e não publique o arquivo bruto
como download separado. Para terceiros, o jogo compilado é o produto
distribuível. Consulte `LICENSE.txt` e `THIRD_PARTY.md`.

Este laboratório não substitui jogador/NPCs nem modifica saves.