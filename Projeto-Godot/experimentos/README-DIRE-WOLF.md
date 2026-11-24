# Laboratorio Dire Wolf Lite

Experimento isolado: nao altera lobos das partidas, IA, saves nem multiplayer.

1. Baixe o ZIP oficial em https://literock-studios.itch.io/direwolf-lite.
2. Mantenha o ZIP ou GLB local: a licenca permite embarcar o modelo em produtos finais, mas proibe redistribuir o asset isolado.
3. No Godot 4.7, abra a cena `res://experimentos/dire_wolf_teste.tscn` (F6) ou use o botao Testar Dire Wolf do laboratorio de goblins.
4. Selecione o ZIP oficial ou o GLB. O laboratorio exibe os 35 ossos e os clips bite, idle_loop, run_loop, walk_loop. Teste repouso, caminhada, corrida, mordida, giro e zoom.

## Teste automatizado local

Com Godot instalado e o checkout da branch teste-dire-wolf, execute na raiz do repositorio (PowerShell; substitua os caminhos conforme o computador):

```powershell
godot --headless --path Projeto-Godot res://experimentos/dire_wolf_teste.tscn -- "--wolf-asset=C:\Downloads\Dire_Wolf_Lite_v1.0.0.zip" --wolf-test
```

Sucesso esperado: DIRE_WOLF_LAB_OK: 35 ossos e 4 animacoes. O caminho local e salvo apenas em user://dire_wolf_lab.cfg. A compilacao e a inspecao visual ainda precisam ser executadas em Godot.
