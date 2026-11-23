# Laboratório Goblin Skirmisher (experimental)

Entrada: menu de laboratório do jogo > **Testar Goblin Skirmisher**.

Com o arquivo original `Character/GoblinSkirmisher.scn` instalado em
`res://modelos/goblin_skirmisher/Character/`:

- Esquerda: modelo atual. Direita: Goblin Skirmisher verdadeiro (G4G).
- Parado: `A000_Idle`; andar: `A-02_Walking`; correr: `A-01_Running`.
- Atacar: `A219_Right_hand_Sword_Slash`; receber dano: `A178_Hit_Reaction`; morrer: `A008_Dead`.
- Controles: animacao proxima/anterior, mostrar adaga, girar e zoom.
- `WeaponGrip` fecha a mao direita quando a adaga estiver visivel.

**Limites do pacote:** animacoes preservam o movimento de Hips. Este
laboratorio serve para comparacao visual e nao substitui a logica de
movimento, combate, redes ou root motion do jogo real.

Teste automatizado `res://tests/test_goblin_skirmisher_asset.gd`
verifica o modelo original, ossos e animacoes essenciais. A publicacao
Windows deve ocorrer apenas apos o arquivo binario estar versionado e
os testes do runner passarem.