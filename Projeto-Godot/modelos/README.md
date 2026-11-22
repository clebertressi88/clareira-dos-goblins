# Modelo 3D dos goblins NPC

Adicione nesta pasta o arquivo **`goblin_npc.glb`** (arquivo enviado pelo usuário, originalmente `goblin(2).glb`).

O jogo carrega automaticamente `res://modelos/goblin_npc.glb` nos NPCs **Bruma** e **Talo**; o protagonista e os demais personagens não são alterados.

O modelo não tem skeleton nem animações. O jogo preserva a movimentação, colisão, conversa e sincronização de estados dos NPCs e aplica uma oscilação visual discreta durante a caminhada.

O código mantém o visual procedimental antigo como fallback se o arquivo estiver ausente ou não for importado como PackedScene. Para ver o modelo novo, o **arquivo GLB real precisa estar versionado neste repositório**.

Se usar o GitHub no navegador, abra esta pasta, selecione **Add file → Upload files**, escolha `goblin_npc.glb` e confirme o commit na branch main. Ao entrar na branch main, o workflow de Windows deverá importar o arquivo e gerar nova compilação.
