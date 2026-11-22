extends SceneTree
# Testa o recurso realmente importado e a aparencia dos goblins em uma cena instanciada.

func _initialize() -> void:
	call_deferred("_run")

func fail(message: String) -> void:
	printerr("GOBLIN MODEL FAIL: " + message)
	quit(1)

func model_visible(game: Node3D, id: String) -> bool:
	var objects: Dictionary = game.get("objects")
	if not objects.has(id):
		return false
	var npc := objects[id] as Node3D
	if npc == null:
		return false
	var visual := npc.get_node_or_null("Visual") as Node3D
	if visual == null or not visual.has_meta("modelo_goblin_npc"):
		return false
	var model := visual.get_node_or_null("ModeloGoblinPivot/ModeloGoblin") as Node3D
	if model == null:
		return false
	var meshes := model.find_children("*","MeshInstance3D",true,false)
	if meshes.size() < 2:
		return false
	for mesh_node in meshes:
		var mesh_instance := mesh_node as MeshInstance3D
		if mesh_instance != null and mesh_instance.mesh != null:
			return true
	return false

func _run() -> void:
	var glb := load("res://modelos/goblin_npc.glb") as PackedScene
	if glb == null:
		fail("O GLB nao foi importado como PackedScene.")
		return
	var scene := load("res://main.tscn") as PackedScene
	if scene == null:
		fail("Cena principal nao encontrada.")
		return
	var game := scene.instantiate() as Node3D
	if game == null:
		fail("Nao foi possivel instanciar main.tscn.")
		return
	root.add_child(game)
	await process_frame
	await physics_frame
	for npc_id in ["Bruma","Talo"]:
		if not model_visible(game,npc_id):
			fail("%s nao esta usando a malha GLB na cena." % npc_id)
			return
		var npc: Node3D = (game.get("objects") as Dictionary)[npc_id]
		var pivot := npc.get_node("Visual/ModeloGoblinPivot") as Node3D
		if absf(pivot.rotation.y) > 0.01:
			fail("%s continua com o GLB invertido em 180 graus." % npc_id)
			return
	var guardian := game.call("creature","guardian","teste-guardiao-glb",Vector3(3.0,0.0,-15.0),game) as CharacterBody3D
	if guardian == null or not model_visible(game,"teste-guardiao-glb"):
		fail("Guardiao continua com a aparencia antiga.")
		return
	var guardian_pivot := guardian.get_node("Visual/ModeloGoblinPivot") as Node3D
	if absf(guardian_pivot.rotation.y) > 0.01:
		fail("Guardiao continua com o GLB invertido em 180 graus.")
		return
	var player_model := game.get("player_model") as Node3D
	if player_model != null and player_model.has_meta("modelo_goblin_npc"):
		fail("Protagonista mudou sem autorizacao.")
		return
	print("GOBLIN MODEL OK: Bruma, Talo e Guardiao renderizam o GLB; jogador preservado.")
	quit(0)
