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
	if player_model == null or not player_model.has_meta("modelo_goblin_npc"):
		fail("Jogador local nao esta usando o modelo texturizado GLB.")
		return
	var avatar := game.call("net_create_avatar",92) as Node3D
	if avatar == null or not (avatar.get_child(0) as Node3D).has_meta("modelo_goblin_npc"):
		fail("Jogador remoto nao esta usando o GLB texturizado.")
		return
	for visual in [player_model,avatar.get_child(0),guardian.get_node("Visual"),
			(game.get("objects") as Dictionary)["Bruma"].get_node("Visual"),
			(game.get("objects") as Dictionary)["Talo"].get_node("Visual")]:
		var anim_materials: Array = visual.get_meta("npc_anim_materials",[])
		if anim_materials.size() < 2:
			fail("Modelo sem material animado/texturizado: " + visual.name)
			return
		for animated_material in anim_materials:
			if not animated_material is ShaderMaterial:
				fail("Material nao e ShaderMaterial: " + visual.name)
				return
			if not (animated_material as ShaderMaterial).get_shader_parameter("atlas_texture") is Texture2D:
				fail("Textura GLB nao esta conectada ao shader: " + visual.name)
				return
		game.call("animate_npc_model",visual,Vector3(2.0,0.0,0.0),0.2,true)
		if float((anim_materials[0] as ShaderMaterial).get_shader_parameter("move_strength")) <= 0.0:
			fail("A animacao nao reagiu a caminhada de " + visual.name)
			return
	print("GOBLIN MODEL OK: NPCs e jogadores usam atlas GLB e animacao procedural.")
	quit(0)
