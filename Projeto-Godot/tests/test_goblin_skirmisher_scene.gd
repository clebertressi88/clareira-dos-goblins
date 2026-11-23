extends SceneTree
## Valida carregamento real do Skirmisher e controles do laboratorio.
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_execute")

func _execute() -> void:
	var scene := load("res://experimentos/goblin_skirmisher_teste.tscn") as PackedScene
	if scene == null:
		_fail("Cena do Skirmisher ausente")
		return
	var instance := scene.instantiate() as Node3D
	if instance == null:
		_fail("Raiz da cena nao e 3D")
		return
	root.add_child(instance)
	await process_frame
	await process_frame
	if instance.get_node_or_null("GoblinAtual") == null:
		_fail("Modelo antigo nao aparece na comparacao")
		return
	if not instance.has_method("_play_motion"):
		_fail("Controles de animacao ausentes")
		return
	if not instance.has_method("_choose_model"):
		_fail("Carregador do pacote externo ausente")
		return
	var model := instance.get("_skirmisher") as Node3D
	var animation_player := instance.get("_animation_player") as AnimationPlayer
	if model == null or animation_player == null:
		_fail("Cena 3D ou AnimationPlayer do Skirmisher nao carregou no laboratorio")
		return
	instance.call("_play_motion", "run")
	await process_frame
	if animation_player.current_animation != "A-01_Running":
		_fail("Botao correr nao acionou o clip original A-01_Running")
		return
	instance.call("_play_motion", "attack")
	await process_frame
	if animation_player.current_animation != "A219_Right_hand_Sword_Slash":
		_fail("Botao atacar nao acionou o clip original de ataque")
		return
	if not DirAccess.dir_exists_absolute("res://modelos/goblin_skirmisher"):
		_fail("Diretorio de importacao do Skirmisher ausente")
		return
	print("SKIRMISHER LAB OK: modelo 3D carregado e clips principais acionados")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
