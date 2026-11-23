extends SceneTree
## Valida que o laboratorio opcional abre mesmo sem o ZIP de terceiro.
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
	if not DirAccess.dir_exists_absolute("res://modelos/goblin_skirmisher"):
		_fail("Diretorio de importacao do Skirmisher ausente")
		return
	print("SKIRMISHER LAB OK: tela isolada funciona sem arquivos externos")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
