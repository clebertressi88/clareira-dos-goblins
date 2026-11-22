# Arquitetura do jogo (Godot 4)

O projeto que o Godot abre esta em `Projeto-Godot/` (arquivo `project.godot`).

## Pontos de entrada e sistemas

| Arquivo | Funcao |
| --- | --- |
| `main.tscn` | Cena principal |
| `main.gd` | Coordenacao de mundo, jogador, NPCs e menus (API original preservada) |
| `sistemas/terreno.gd` | Altura do terreno e malha de pedras |
| `sistemas/materiais.gd` | Texturas e materiais compartilhados |
| `sistemas/visual.gd` | Criacao de malhas e caixas de colisao |
| `sistemas/inventario.gd` | Ordem dos slots e preenchimento da hotbar |
| `sistemas/receitas.gd` | Padroes 2x2 e 3x3 da criacao |
| `sistemas/construcao.gd` | Encaixe de paredes e deteccao de sobreposicoes |
| `sistemas/interface.gd` | Estilos da interface/hotbar |
| `sistemas/salvamento.gd` | Serializacao dos slots da mochila |
| `fogueira.gd` | Fogueira e efeitos |
| `icones/` | Sprites do inventario |

### Como alterar sem quebrar o jogo

1. Use **`main.gd`** como porta de entrada. As funcoes antigas continuam com seus mesmos nomes para evitar quebrar chamadas e sinais.
2. Para alterar um algoritmo de um sistema modularizado, edite `sistemas/<area>.gd`; o `main.gd` delega para ele.
3. Nao altere a ordem de `ITEMS` / `ITEM_KINDS` sem migrar os saves: os indices ja sao persistidos.
4. Nao altere as chaves `stock`, `reserve`, `removed`, `placed` etc. do JSON de save sem migracao.
5. Para novas mecanicas, prefira cenas e scripts pequenos. **Nao** estenda o `main.gd` com mais blocos grandes.

### Otimizacoes desta etapa

- Malhas de cilindros com o mesmo raio e altura sao reutilizadas (`cylinder_mesh_cache`).
- A interface principal e a hotbar sao atualizadas em ate **10 Hz**; fisica permanece nos ticks normais.
- Criaturas distantes sao descartadas no calculo pela distancia ao quadrado, evitando raiz quadrada desnecessaria.
- Nao alteramos a geracao do mapa, rede, atalhos (`E` abre inventario), nem o formato dos saves.

### O que ainda precisa de testes no Godot

- Abrir/clicar/arrastar no inventario e na mochila, construir paredes, bancadas e fogueira.
- Movimento de goblins, coelhos e lobos e colisao das estruturas.
- Multijogador LAN, salvar/recarregar, exportar Windows.
- Medir FPS e tempo de quadro no painel **Debugger > Profiler** antes/depois; nao ha ganho quantificado sem teste executado.

A validacao de CI verifica estrutura e scripts; nao substitui execucao grafica e testes dentro do Godot.
