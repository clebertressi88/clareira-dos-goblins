extends SceneTree
## Um anfitriao distante deve conservar a area jogavel de cada visitante.
## Teste local sem rede: exercita os mesmos centros usados pelos RPCs.

func _initialize() -> void:
	call_deferred("_run")

func fail(message: String) -> void:
	printerr("MULTIPLAYER DISTANT CHUNKS FAIL: " + message)
	quit(1)

func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	if scene==null:
		fail("Cena principal inexistente")
		return
	var game := scene.instantiate() as Node3D
	root.add_child(game)
	await physics_frame
	await physics_frame
	var host: CharacterBody3D = game.get("player")
	if not is_instance_valid(host):
		fail("Jogador anfitriao ausente")
		return
	var host_center: Vector2i = game.call("chunk_from_position",host.global_position)
	var far_x := 384.0
	var far_z := 240.0
	var guest_pos := Vector3(far_x,float(game.call("ground",far_x,far_z))+.7,far_z)
	var guest_center: Vector2i = game.call("chunk_from_position",guest_pos)
	var avatar := game.call("net_create_avatar",88) as Node3D
	if not is_instance_valid(avatar):
		fail("Visitante nao foi criado")
		return
	avatar.global_position = guest_pos
	avatar.set_meta("destination",guest_pos)
	game.set("net_role","host")
	game.call("load_chunks")
	var loaded: Dictionary = game.get("chunks")
	if not loaded.has(host_center) or not loaded.has(host_center+Vector2i(2,0)):
		fail("O anfitriao perdeu chunks locais apos visitante afastar")
		return
	if not loaded.has(guest_center) or not loaded.has(guest_center+Vector2i(1,0)):
		fail("Area distante do visitante nao foi carregada")
		return
	var tree_found := false
	for obj in (game.get("objects") as Dictionary).values():
		if not is_instance_valid(obj) or str(obj.get_meta("kind",""))!="tree":
			continue
		if obj.global_position.distance_to(guest_pos)<30.0:
			tree_found = true
			break
	if not tree_found:
		fail("Arvores distantes ausentes no servidor: cortes nao seriam reconhecidos")
		return
	if int(game.call("collectible_item_for_kind","stick"))!=1 or int(game.call("collectible_item_for_kind","stone"))!=-1:
		fail("Regras de coleta e mineracao incorretas")
		return
	game.call("remove_remote",88)
	game.call("load_chunks")
	loaded = game.get("chunks")
	if not loaded.has(host_center) or loaded.has(guest_center):
		fail("Chunks nao foram liberados apos a saida do visitante")
		return
	print("MULTIPLAYER DISTANT CHUNKS OK: anfitriao e visitante distantes, recursos interativos e descarga segura.")
	quit(0)
