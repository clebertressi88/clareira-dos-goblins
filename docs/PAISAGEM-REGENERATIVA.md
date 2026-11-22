# Paisagem procedural — montanhas, vales, rios e arvores que rebrotam

Esta alteracao foi integrada ao **jogo atual** em `Projeto-Godot/main.gd`.
Nao e uma demo independente e nao remove a hotbar, craft, NPCs ou construcoes.

## Onde foi implementado

- `landscape_terrain.gd`: relevo deterministico (mesma altura para solo, colisao e objetos), montanhas e vale fluvial.
- `main.gd / create_chunk`: gera terreno, malha do rio e recursos ao redor; nao gera novas arvores dentro do leito.
- `main.gd / spawn_object("tree")`: arvore adulta, toco com raizes e broto.
- `main.gd / timber`: anima a queda do tronco sem excluir o toco.
- `main.gd / update_tree_visual`: crescimento progressivo a partir de relogio real.
- `load_game` e `save_game`: salvam `tree_regrowth` no mesmo save `user://clareira-nativa.json`.

## Ciclo da arvore

1. Corte a arvore com a ferramenta normal do jogo (4 pontos de corte; machados cortam mais rapido).
2. O tronco cai, aparecem 3 troncos coletaveis e fica um toco enraizado no local.
3. Apos **120 segundos**, surge o broto.
4. Durante os **720 segundos seguintes**, o tronco e a copa crescem gradualmente.
5. Quando completa o crescimento, a arvore volta a ser cortavel.

O cronometro usa horario Unix salvo: a arvore evolui mesmo se o jogo for fechado.
O crescimento de arvores carregadas e atualizado a cada 2 s para poupar processamento.
Os valores de tempo estao em `TREE_BUD_DELAY` e `TREE_GROW_SECONDS`.

Arvores que ja haviam sido removidas por corte nas versoes antigas passam a ser tratadas como tocos quando sua chunk e carregada. Itens e criaturas nao sao migrados.

## Rio e montanhas

A clareira inicial fica relativamente plana para preservar o acampamento.
Montanhas e vales aparecem ao se afastar da origem. O rio sinuoso passa a leste
da clareira (aproximadamente x = 34, dependendo de z), com agua em nivel
`-1.05`. O leito fisico e rebaixado em relacao as margens.

**Limitacao:** a agua e visual e ainda nao possui correnteza, natacao nem interacao de pesca.
A aparencia usa malhas procedurais simples. A imagem de referencia aprovada
continua sendo a meta para modelos/texturas mais detalhados.

## Teste no Godot

1. Abra `Projeto-Godot/project.godot` no Godot 4.7.
2. Execute `main.tscn`.
3. Entre no jogo, explore a leste para encontrar o rio e siga para fora da clareira para ver o relevo.
4. Equipe um machado, corte uma arvore, observe as raizes e recolha os troncos.
5. Aguarde o broto, feche e reabra o jogo para confirmar a persistencia do crescimento.
6. Confira inventario (E), hotbar de 9 slots, bancadas, construcao e NPCs.

**Validacao pendente:** esta alteracao ainda precisa ser executada dentro do editor Godot.
A workflow atual do repositorio apenas verifica a existencia de arquivos e caches,
nao compila nem executa GDScript.
