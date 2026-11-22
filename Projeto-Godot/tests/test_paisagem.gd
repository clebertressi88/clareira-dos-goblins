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
	# Testa o fluxo real: o menu bloqueia movimento ate clicar Jogar.
	var player := game.get("player") as CharacterBody3D
	if player == null:
		fail("Jogador nao foi criado.")
		return
	# Evita atravessar a fronteira da chunk no teste e gerar dezenas de chunks.
	# O jogador continua dentro da clareira, a dois metros de obstaculos conhecidos.
	player.position = Vector3(6.0, float(game.call("ground",6.0,6.0))+1.25, 6.0)
	player.velocity = Vector3.ZERO
	game.call("begin")
	if not bool(game.get("moving")):
		fail("O botao Jogar/continuar nao ativou a movimentacao.")
		return
	var initial_position := Vector2(player.position.x,player.position.z)
	var key_down := InputEventKey.new()
	key_down.keycode = KEY_W
	key_down.physical_keycode = KEY_W
	key_down.pressed = true
	Input.parse_input_event(key_down)
	for tick in range(35):
		await physics_frame
	var key_up := InputEventKey.new()
	key_up.keycode = KEY_W
	key_up.physical_keycode = KEY_W
	key_up.pressed = false
	Input.parse_input_event(key_up)
	var travel := initial_position.distance_to(Vector2(player.position.x,player.position.z))
	if travel < .45:
		fail("WASD nao movimentou o jogador; deslocamento = %.3f" % travel)
		return
	# Validar seta e layout logico sem depender apenas de scan code fisico.
	var arrow_down := InputEventKey.new()
	arrow_down.keycode = KEY_UP
	arrow_down.physical_keycode = KEY_UP
	arrow_down.pressed = true
	Input.parse_input_event(arrow_down)
	await physics_frame
	var mapped: Vector2 = game.call("movement_axis")
	if mapped.y > -.8:
		fail("Seta para cima nao foi reconhecida: eixo = " + str(mapped))
		return
	var arrow_up := InputEventKey.new()
	arrow_up.keycode = KEY_UP
	arrow_up.physical_keycode = KEY_UP
	arrow_up.pressed = false
	Input.parse_input_event(arrow_up)
	# Tecla W tambem inicia a partir do menu sem exigir foco em um botao.
	game.call("show_menu")
	var resume_down := InputEventKey.new()
	resume_down.keycode = KEY_W
	resume_down.physical_keycode = KEY_W
	resume_down.pressed = true
	Input.parse_input_event(resume_down)
	await process_frame
	if not bool(game.get("moving")):
		fail("W no menu nao ativou Jogar/continuar")
		return
	var resume_up := InputEventKey.new()
	resume_up.keycode = KEY_W
	resume_up.physical_keycode = KEY_W
	resume_up.pressed = false
	Input.parse_input_event(resume_up)
	print("CONTROLES TEST OK: Jogar/continuar, tecla W e deslocamento de %.2f m; setas e iniciar por tecla." % travel)
	print("PAISAGEM TEST OK: cena, arvore, colisao, toco, broto e maturidade.")
	quit(0)
