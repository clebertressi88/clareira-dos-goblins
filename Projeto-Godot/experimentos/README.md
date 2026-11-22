# Laboratorio da skin do Goblin - V2

Esta pasta contem uma segunda estrutura de pele e esqueleto para TESTAR, sem substituir
os NPCs e jogadores utilizados em partidas.

## Como abrir

1. Atualize o jogo pela Release do GitHub.
2. No menu inicial, em modo solo, escolha **Laboratorio: comparar skin atual e skin V2**.
3. Compare os goblins lado a lado: **esquerda = atual; direita = V2**.
4. Teste **Parado**, **Caminhar**, **Correr**, **Girar**, **Espada** e **Escudo**.
5. Selecione **Voltar ao jogo (ESC)**.

O laboratorio nao grava modificacoes de pele nos saves. A versao de producao
continua usando `res://npc_goblin.gd` e `res://npc_goblin_skin.gd`.

## Estrutura

- `goblin_skin_v2.gd`: controlador V2 com um Skeleton3D e articulacoes revisadas.
- `goblin_skin_v2_weights.gd`: skin nova derivada da malha existente. Usa ilhas
  de geometria, centros anatomicos e transicoes restritas aos cotovelos e joelhos.
- `goblin_skin_teste.tscn`: cena independente de comparacao.
- `goblin_skin_teste.gd`: luzes, camera, movimentos e controles de teste.
- `../tests/test_goblin_skin_v2.gd`: teste de pesos, UVs, ossos e equipamentos.

O GLB original e o atlas de textura permanecem intactos. Os equipamentos originais
continuam separados. A V2 e experimental e necessita avaliacao visual antes
de qualquer substituicao da skin em producao.
