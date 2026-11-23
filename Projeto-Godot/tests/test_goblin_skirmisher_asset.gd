extends SceneTree
## Testa o Skirmisher original importado sem alterar nenhuma partida.
const MODEL = "res://modelos/goblin_skirmisher/Character/GoblinSkirmisher.scn"
const REQUIRED = ["A000_Idle", "A-02_Walking", "A-01_Running", "A219_Right_hand_Sword_Slash", "A178_Hit_Reaction", "A008_Dead"]

func _initialize() -> void:
	call_deferred("_execute")

func _execute() -> void:
	if not FileAccess.file_exists(MODEL):
		_fail("Pacote original nao foi instalado: " + MODEL)
		return
	var scene := load(MODEL) as PackedScene
	if scene == null:
		_fail("Arquivo binario .scn nao carregou como PackedScene")
		return
	var model := scene.instantiate() as Node3D
	if model == null:
		_fail("Modelo principal nao possui raiz Node3D")
		return
	root.add_child(model)
	await process_frame
	var skeleton := _find_type(model, "Skeleton3D") as Skeleton3D
	var player := _find_type(model, "AnimationPlayer") as AnimationPlayer
	if skeleton == null or skeleton.get_bone_count() < 20:
		_fail("Esqueleto de 24 ossos nao foi encontrado")
		return
	if player == null:
		_fail("AnimationPlayer ausente")
		return
	if player.get_animation_list().size() < 100:
		_fail("Menos de 100 animacoes no personagem")
		return
	for clip in REQUIRED:
		if not player.has_animation(clip):
			_fail("Animacao obrigatoria ausente: " + clip)
			return
		player.play(clip)
		player.seek(0.1, true)
		await process_frame
	print("SKIRMISHER ASSET OK: ", skeleton.get_bone_count(), " ossos, ", player.get_animation_list().size(), " clips.")
	quit(0)

func _find_type(node: Node, kind: String) -> Node:
	if node.is_class(kind):
		return node
	for child in node.get_children():
		var found := _find_type(child, kind)
		if found != null:
			return found
	return null

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
