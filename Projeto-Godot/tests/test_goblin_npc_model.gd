extends SceneTree
## Valida modelo Skirmisher real para jogador, NPCs, guardiao e rede sem
## interferir na IA, colisoes, inventarios, multiplayer ou saves.

func _initialize() -> void:
	call_deferred("_run")

func fail(message: String) -> void:
	printerr("GOBLIN MODEL FAIL: " + message)
	quit(1)

func _test_character(visual: Node3D, title: String, role: String) -> bool:
	if visual == null or not bool(visual.get_meta("modelo_skirmisher", false)):
		fail(title + ": modelo Skirmisher nao vinculado")
		return false
	var controller := visual.get_node_or_null("GoblinRig") as Node3D
	if controller == null:
		fail(title + ": controlador GoblinRig ausente")
		return false
	if str(controller.get("variant")) != role:
		fail(title + ": tipo de personagem incorreto")
		return false
	var skeleton := controller.call("get_skeleton") as Skeleton3D
	var animator := controller.call("get_animation_player") as AnimationPlayer
	if skeleton == null or skeleton.get_bone_count() != 24:
		fail(title + ": esqueleto original de 24 ossos ausente")
		return false
	if animator == null or animator.get_animation_list().size() < 100:
		fail(title + ": biblioteca de animacoes do Skirmisher ausente")
		return false
	for clip in ["A000_Idle", "A-02_Walking", "A-01_Running", "A219_Right_hand_Sword_Slash", "A178_Hit_Reaction", "A008_Dead"]:
		if not animator.has_animation(clip):
			fail(title + ": falta animacao " + clip)
			return false
	var label := controller.get_node_or_null("NomeNPC") as Label3D
	if role == "player":
		if label != null:
			fail(title + ": jogador esta identificado erroneamente como NPC")
			return false
	else:
		if label == null or label.text.is_empty():
			fail(title + ": NPC sem nome visivel")
			return false
		if controller.get_node_or_null("FaixaIdentificacaoFrente") != null or controller.get_node_or_null("FaixaIdentificacaoCostas") != null:
			fail(title + ": faixas antigas ainda aparecem")
			return false
		if controller.get_node_or_null("OmbreiraNPC") != null:
			fail(title + ": ombreira retangular antiga ainda aparece")
			return false
	var swords: Array = controller.get("sword_parts")
	var shields: Array = controller.get("shield_parts")
	if swords.is_empty() or shields.is_empty():
		fail(title + ": armas equipaveis ausentes")
		return false
	controller.call("set_equipment", false, false)
	for part in swords + shields:
		if not is_instance_valid(part) or part.visible:
			fail(title + ": item equipado ainda aparece quando removido")
			return false
	controller.call("set_equipment", true, true)
	for part in swords + shields:
		if not is_instance_valid(part) or not part.visible:
			fail(title + ": equipamento nao reapareceu")
			return false
	controller.call("animate", Vector3(3.2, 0.0, 0.0), 0.016, true)
	if animator.current_animation != "A-01_Running":
		fail(title + ": correr nao iniciou animacao original")
		return false
	controller.call("animate", Vector3(1.45, 0.0, 0.0), 0.016, true)
	if animator.current_animation != "A-02_Walking":
		fail(title + ": andar nao iniciou animacao original")
		return false
	controller.call("animate", Vector3.ZERO, 0.016, true)
	if animator.current_animation != "A000_Idle":
		fail(title + ": parado nao iniciou animacao original")
		return false
	return true

func _run() -> void:
	if not ResourceLoader.exists("res://modelos/goblin_skirmisher/Character/GoblinSkirmisher.scn"):
		fail("Asset original Skirmisher ausente")
		return
	var game_scene := load("res://main.tscn") as PackedScene
	if game_scene == null:
		fail("Cena principal ausente")
		return
	var game := game_scene.instantiate() as Node3D
	root.add_child(game)
	await process_frame
	await physics_frame
	var objects: Dictionary = game.get("objects")
	for data in [["Bruma", "bruma"], ["Talo", "talo"]]:
		var npc_name: String = data[0]
		var npc_role: String = data[1]
		if not objects.has(npc_name):
			fail(npc_name + ": NPC ausente no mundo")
			return
		var visual := (objects[npc_name] as Node3D).get_node_or_null("Visual") as Node3D
		if not _test_character(visual, npc_name, npc_role):
			return
	var guardian := game.call("creature", "guardian", "teste-skirmisher-guardiao", Vector3(3,0,-15), game) as CharacterBody3D
	if guardian == null or not _test_character(guardian.get_node_or_null("Visual") as Node3D, "Guardiao", "guardiao"):
		return
	if not _test_character(game.get("player_model") as Node3D, "Jogador local", "player"):
		return
	var remote := game.call("net_create_avatar", 82) as Node3D
	if remote == null or not _test_character(remote.get_child(0) as Node3D, "Jogador remoto", "player"):
		return
	print("GOBLIN MODEL OK: Skirmisher nativo, 24 ossos, animacoes, equipamentos e NPCs identificados.")
	quit(0)
