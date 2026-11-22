# Clareira dos Goblins

Jogo de sobrevivência, exploração e construção desenvolvido em **Godot 4.x** (o projeto local foi utilizado com Godot 4.7.2).

## Abrir o projeto

1. Instale o Godot com uma versão compatível com `Projeto-Godot/project.godot`.
2. Abra o Godot e escolha **Importar**.
3. Selecione `Projeto-Godot/project.godot`.
4. Aguarde a importação dos recursos e execute a cena principal (`main.tscn`).

Estrutura principal:

```text
Clareira-dos-Goblins-Windows/
├── Projeto-Godot/
│   ├── project.godot       # Configuracao Godot
│   ├── main.tscn          # Cena principal
│   ├── main.gd            # Logica do jogo
│   ├── icones/            # Icones do inventario e hotbar
│   └── ...                # Texturas, modelos, shaders e outros recursos
├── GERAR-EXE-WINDOWS-CORRIGIDO.cmd  # Se existir no computador
├── GERAR-EXE-WINDOWS-CORRIGIDO.ps1  # Se existir no computador
├── .gitignore
└── README.md
```

## Jogabilidade e recursos

- Clareira com coleta de materiais, fabricação, mochila, inventário e hotbar com nove espaços.
- Bancadas de trabalho nível 1 (madeira) e nível 2 (tampo de pedra).
- Paredes com versões fechadas, portas e janelas; construção modular, piso/teto e pavimentos.
- Fogueira, goblins/NPCs, coelhos e lobos.

Os detalhes exatos de gameplay e controles dependem da versão de `main.gd` incluída no repositório. Consulte [docs/CONTROLES.md](docs/CONTROLES.md).

## Gerar executável Windows

No PC de desenvolvimento, utilize o script `GERAR-EXE-WINDOWS-CORRIGIDO.cmd`, se estiver presente. É necessário o **Godot instalado** e o preset de exportação de Windows em `Projeto-Godot/export_presets.cfg`.

**Não adicione EXEs, arquivos `.pck` ou a pasta `.ferramentas/` ao código-fonte.** Para compartilhar uma versão jogável, crie uma **GitHub Release** e anexe o ZIP gerado pelo exportador.

## GitHub e colaboração

Este repositório deve conter arquivos-fonte e assets de desenvolvimento; os arquivos `.godot/`, builds e backups são excluídos pelo `.gitignore`.

1. Faça um commit por mudança funcional.
2. Teste o projeto no Godot antes de disponibilizar uma nova release.
3. Preserve os arquivos `.uid` e os ajustes `.import` dos recursos, quando existirem.
4. Use uma branch para alterações experimentais.
5. Verifique a autorização de uso das imagens, modelos e sons antes de tornar o repositório público.

## Licença

**Nenhuma licença de redistribuição foi definida.** Até escolher uma licença, não presuma que o código e os recursos podem ser reutilizados por terceiros.

## Organizacao e desempenho

Os algoritmos reutilizaveis foram separados em `Projeto-Godot/sistemas/` (terreno, materiais, visual, inventario, receitas, construcao, interface e salvamento).
O `main.gd` continua como coordenador para preservar compatibilidade com as cenas e saves atuais.
Consulte **[docs/ARQUITETURA.md](docs/ARQUITETURA.md)** para encontrar cada subsistema e executar as verificacoes.

Teste estatico local: `python3 tests/verificar_estrutura.py`. Os FPS precisam ser medidos no Godot.

Para localizar rapidamente as rotinas do script principal, veja o **[Mapa de funcoes](docs/MAPA_FUNCOES.md)**.
  
## Modelo 3D dos goblins

Os goblins NPC (Bruma, Talo e guardioes) usam o modelo `Projeto-Godot/modelos/goblins/goblin.glb` com ajuste de escala automatico por `personagens/goblin_visual.gd`. O jogador conserva seu modelo original. Como o GLB e estatico, o movimento visual e uma oscilacao simples, sem animacao de esqueleto.

[Creditos e licenca do modelo](docs/CREDITOS_MODELOS.md).
