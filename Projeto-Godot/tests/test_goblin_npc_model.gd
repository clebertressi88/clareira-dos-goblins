extends SceneTree
# Verifica articulacao real, pesos de vertices e atlas original dos NPCs/jogadores.
func _initialize() -> void:
	call_deferred("_run")

func fail(message: String) -> void:
	printerr("GOBLIN MODEL FAIL: "+message)
	quit(1)

func _test_character(visual: Node3D, title: String) -> bool:
	if visual == null or not visual.has_meta("modelo_goblin_npc"):
		fail(title+": nao usa controlador independente")
		return false
	var controller := visual.get_node_or_null("GoblinRig") as Node3D
	if controller == null:
		fail(title+": arquivo NPC nao instanciou controlador")
		return false
	var skeletons: Array = controller.get("skeletons")
	if skeletons.size()<2:
		fail(title+": malhas nao possuem Skeleton3D completo")
		return false
	var meshes := controller.find_children("*","MeshInstance3D",true,false)
	var arms := false
	var legs := false
	var active_parts := 0
	for node in meshes:
		var part := node as MeshInstance3D
		if part == null or part.mesh == null or part.skin == null:
			continue
		var skel := part.get_node_or_null(part.skeleton) as Skeleton3D
		if skel == null or skel.get_bone_count()!=13:
			fail(title+": ossos nao vinculados a malha")
			return false
		var arrays: Array = part.mesh.surface_get_arrays(0)
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		if bones.size() != part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()*4:
			fail(title+": quantidade invalida de pesos")
			return false
		for i in range(0,bones.size(),4):
			if weights[i]>.1 and bones[i] in [3,4,5,6]:
				arms = true
			if weights[i]>.1 and bones[i] in [7,8,9,10,11,12]:
				legs = true
		var material := part.get_active_material(0) as BaseMaterial3D
		if material == null or material.albedo_texture == null:
			fail(title+": textura original nao preservada")
			return false
		active_parts += 1
	if active_parts<2 or not arms or not legs:
		fail(title+": nao ha pele articulada em bracos E pernas")
		return false
	var swords: Array = controller.get("sword_parts")
	var shields: Array = controller.get("shield_parts")
	if swords.is_empty() or shields.is_empty():
		fail(title+": espada e escudo nao foram separados da malha do corpo")
		return false
	controller.call("set_equipment",false,false)
	for piece in swords+shields:
		if not is_instance_valid(piece) or piece.visible or (piece as MeshInstance3D).mesh == null:
			fail(title+": item nao foi removido da mao corretamente")
			return false
	controller.call("set_equipment",true,true)
	for piece in swords+shields:
		if not piece.visible:
			fail(title+": item nao reapareceu ao equipar")
			return false
	controller.call("animate",Vector3(2,0,0),.3,true)
	var skeleton := skeletons[0] as Skeleton3D
	if skeleton.get_bone_pose_rotation(7).angle_to(Quaternion.IDENTITY)<.05 or skeleton.get_bone_pose_rotation(3).angle_to(Quaternion.IDENTITY)<.05:
		fail(title+": ossos dos bracos ou pernas nao animaram")
		return false
	return true

func _run() -> void:
	if not ResourceLoader.exists("res://modelos/goblin_npc.glb"):
		fail("Modelo GLB original ausente")
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
	for name in ["Bruma","Talo"]:
		if not objects.has(name) or not _test_character(objects[name].get_node("Visual"),name):
			return
	var guardian := game.call("creature","guardian","teste-guardiao-com-ossos",Vector3(3,0,-15),game) as CharacterBody3D
	if guardian == null or not _test_character(guardian.get_node("Visual"),"Guardiao"):
		return
	if not _test_character(game.get("player_model"),"Jogador local"):
		return
	var remote := game.call("net_create_avatar",82) as Node3D
	if remote == null or not _test_character(remote.get_child(0),"Jogador remoto"):
		return
	print("GOBLIN MODEL OK: esqueletos 13 ossos, bracos/pernas animados e texturas preservadas.")
	quit(0)
