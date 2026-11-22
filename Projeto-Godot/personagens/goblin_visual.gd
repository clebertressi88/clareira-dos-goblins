extends RefCounted
## Integra o goblin GLB aos NPCs mantendo colisao, IA e scripts originais.
## Modelo estatico: nao possui armadura nem animacoes internas.
## Ajuste a rotacao abaixo se a frente do arquivo importar invertida.

const CAMINHO_MODELO := "res://modelos/goblins/goblin.glb"
const ALTURA_DESEJADA := 1.45
const AJUSTE_FRENTE_GRAUS := 0.0

static func _coletar_malhas(node: Node, destino: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		destino.append(node as MeshInstance3D)
	for child in node.get_children():
		_coletar_malhas(child, destino)

static func anexar(pai: Node3D) -> bool:
	if not ResourceLoader.exists(CAMINHO_MODELO):
		push_warning("Modelo dos goblins nao localizado: " + CAMINHO_MODELO)
		return false

	var recurso: Resource = load(CAMINHO_MODELO)
	if not (recurso is PackedScene):
		push_warning("Modelo GLB nao importado como cena: " + CAMINHO_MODELO)
		return false

	var cena: Node = (recurso as PackedScene).instantiate()
	if not (cena is Node3D):
		cena.free()
		return false

	var suporte := Node3D.new()
	suporte.name = "ModeloGoblin3D"
	pai.add_child(suporte)
	suporte.add_child(cena)

	var malhas: Array[MeshInstance3D] = []
	_coletar_malhas(cena, malhas)
	var minimo := Vector3(INF, INF, INF)
	var maximo := Vector3(-INF, -INF, -INF)
	var encontrou := false
	var transformacao_raiz := suporte.global_transform.affine_inverse()

	for malha in malhas:
		if malha.mesh == null:
			continue
		var caixa := malha.get_aabb()
		var transformacao_local := transformacao_raiz * malha.global_transform
		for xx in [0.0, 1.0]:
			for yy in [0.0, 1.0]:
				for zz in [0.0, 1.0]:
					var ponto := caixa.position + caixa.size * Vector3(xx, yy, zz)
					ponto = transformacao_local * ponto
					minimo = minimo.min(ponto)
					maximo = maximo.max(ponto)
					encontrou = true

	var altura := maximo.y - minimo.y
	if not encontrou or not is_finite(altura) or altura <= 0.001:
		push_warning("Nao foi possivel calcular o tamanho do goblin importado.")
		suporte.queue_free()
		return false

	# O arquivo Sketchfab tem dimensoes originais muito maiores que metros.
	# Centraliza X/Z, coloca o pe no solo e ajusta para 1,45 m de altura.
	var fator := ALTURA_DESEJADA / altura
	var centro := (minimo + maximo) * 0.5
	suporte.scale = Vector3.ONE * fator
	suporte.position = Vector3(-centro.x * fator, -minimo.y * fator, -centro.z * fator)
	suporte.rotation.y = deg_to_rad(AJUSTE_FRENTE_GRAUS)

	pai.set_meta("goblin_glb", true)
	pai.set_meta("goblin_glb_suporte", suporte)
	pai.set_meta("goblin_glb_y", suporte.position.y)
	pai.set_meta("goblin_glb_fase", 0.0)
	pai.set_meta("goblin_glb_peso", 0.0)
	return true

static func animar(pai: Node3D, velocidade: Vector3, dt: float, no_chao: bool = true) -> void:
	# Sem armadura nao existe animacao real de pernas; apenas movimento corporal sutil.
	var suporte: Node3D = pai.get_meta("goblin_glb_suporte", null) as Node3D
	if not is_instance_valid(suporte):
		return

	var rapidez := minf(Vector2(velocidade.x, velocidade.z).length(), 8.0)
	var alvo := clampf(rapidez / 3.5, 0.0, 1.0) if no_chao else 0.0
	var peso := move_toward(float(pai.get_meta("goblin_glb_peso", 0.0)), alvo, dt * 6.0)
	var fase := fposmod(float(pai.get_meta("goblin_glb_fase", 0.0)) + rapidez * dt * 4.8, TAU)
	pai.set_meta("goblin_glb_fase", fase)
	pai.set_meta("goblin_glb_peso", peso)
	suporte.position.y = float(pai.get_meta("goblin_glb_y", 0.0)) + absf(sin(fase)) * 0.025 * peso
	suporte.rotation.z = sin(fase) * 0.025 * peso
