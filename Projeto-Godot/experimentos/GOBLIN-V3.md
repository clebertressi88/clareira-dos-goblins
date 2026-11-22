# Goblin V3 - estrutura 3D da imagem de referencia

Esta e uma **versao experimental**, independente do GLB antigo. A anatomia,
a silhueta e a paleta foram reconstruidas com malhas e materiais novos:
cabeca com orelhas pontudas e chifre, olhos grandes, nariz, peito, alcas,
cinto, saia, maos, pernas completas e botas.

- `goblin_v3_model.gd`: cria um `Skeleton3D` com **16 ossos/juntas**.
- Cada peca e um `MeshInstance3D` vinculado a um `BoneAttachment3D`.
- Caminhar e correr utilizam ciclos diferentes, com joelhos/cotovelos proprios.
- Espada e escudo sao componentes independentes, equipaveis sem alterar o corpo.
- `goblin_v3.tscn`: cena que instancia o personagem novo automaticamente.
- O modelo nao reproduz pixels, letras nem marcas-d'agua da imagem enviada.
- A representacao e aproximada; uma imagem frontal nao contem a geometria
  traseira nem permite recuperar todos os detalhes reais do personagem.
- Antes de substituir o modelo usado na partida, abra o laboratorio pelo
  menu inicial e compare **ATUAL** a esquerda com **V3** a direita.

Teste automatizado: `res://tests/test_goblin_v3.gd`.

A skin V2 e o GLB antigo permanecem no projeto para nao quebrar o jogo.
