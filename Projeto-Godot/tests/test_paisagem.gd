extends SceneTree
## Teste automatico de inicio do jogo, colisao de arvores e ciclo de regeneracao.
## Executar: godot --headless --path Projeto-Godot --script res://tests/test_paisagem.gd

func _initialize() -> void:
	call_deferred("_run_test")

func fail(message: String) -> void:
	printerr("PAISAGEM TEST FAIL: " + message)
	quit(1)

func _run_test() -> void:
	var scene_resource := load("res://main.tscn") as PackedScene
	if scene_resource == null:
		fail("Cena main.tscn nao encontrada.")
		return
	var game := scene_resource.instantiate() as Node3D
	root.add_child(game)
	await process_frame
	if not is_instance_valid(game):
		fail("A cena principal nao iniciou.")
		return
	var objects: Dictionary = game.get("objects")
	var tree: Node3D
	for candidate in objects.values():
		if is_instance_valid(candidate) and candidate is StaticBody3D and candidate.get_meta("kind","") == "tree":
			tree = candidate
			break
	if tree == null:
		fail("Nenhuma arvore foi gerada nas chunks iniciais.")
		return
	var collision := tree.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null or not (collision.shape is BoxShape3D):
		fail("Arvore sem CollisionShape3D nomeado e valido.")
		return
	var id := str(tree.get_meta("id",""))
	game.call("timber",tree,true)
	var saved: Dictionary = game.get("tree_regrowth")
	if not saved.has(id) or str(tree.get_meta("kind","")) != "stump":
		fail("Corte nao deixou toco regenerativo.")
		return
	var stump := tree.get_node_or_null("Visual/Toco") as Node3D
	if stump == null or not stump.visible:
		fail("Toco com raizes nao ficou visivel.")
		return
	saved[id] = Time.get_unix_time_from_system() - 240.0
	game.call("update_tree_visual",tree)
	var growth := tree.get_node_or_null("Visual/Crescimento") as Node3D
	if growth == null or not growth.visible or growth.scale.y <= 0.07:
		fail("A arvore nao evoluiu apos brotar.")
		return
	saved[id] = Time.get_unix_time_from_system() - 1000.0
	game.call("update_tree_visual",tree)
	if str(tree.get_meta("kind","")) != "tree" or saved.has(id):
		fail("A arvore nao voltou ao estado adulto.")
		return
	print("PAISAGEM TEST OK: cena, arvore, colisao, toco, broto e maturidade.")
	quit(0)
