extends SceneTree
## Teste automatizado do NOVO rig; nunca altera a skin atual nem os saves.
const LEGACY = preload("res://npc_goblin.gd")
const EXPERIMENT = preload("res://experimentos/goblin_skin_v2.gd")

func _initialize() -> void:
	call_deferred("_run")


func fail(reason: String) -> void:
	printerr("SKIN V2 FAIL: "+reason)
	quit(1)


func _run() -> void:
	var old: Node3D=LEGACY.new()
	root.add_child(old)
	if not bool(old.call("install")):
		fail("Skin atual nao carregou")
		return
	var newer: Node3D=EXPERIMENT.new()
	root.add_child(newer)
	if not bool(newer.call("install")):
		fail("Skin V2 nao carregou")
		return
	var old_parts: Array = []
	var new_parts: Array = []
	for node in old.find_children("*","MeshInstance3D",true,false):
		var part := node as MeshInstance3D
		if part!=null and part.skin!=null:
			old_parts.append(part)
	for node in newer.find_children("*","MeshInstance3D",true,false):
		var part := node as MeshInstance3D
		if part!=null and part.skin!=null:
			new_parts.append(part)
	if old_parts.size()<2 or old_parts.size()!=new_parts.size():
		fail("O comparador perdeu alguma malha do goblin")
		return
	var changed := 0
	var skin_transitions := 0
	var used_bones := {}
	for i in range(old_parts.size()):
		var before := old_parts[i] as MeshInstance3D
		var after := new_parts[i] as MeshInstance3D
		if before.mesh.get_surface_count()!=after.mesh.get_surface_count():
			fail("Numero de superficies diferente")
			return
		for surface in range(before.mesh.get_surface_count()):
			var a: Array=before.mesh.surface_get_arrays(surface)
			var b: Array=after.mesh.surface_get_arrays(surface)
			var old_uv: PackedVector2Array=a[Mesh.ARRAY_TEX_UV]
			var new_uv: PackedVector2Array=b[Mesh.ARRAY_TEX_UV]
			var old_vertices: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
			var new_vertices: PackedVector3Array=b[Mesh.ARRAY_VERTEX]
			if old_uv!=new_uv or old_vertices!=new_vertices:
				fail("Modelo/textura UV mudaram em vez de apenas os pesos")
				return
			var ids: PackedInt32Array=b[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array=b[Mesh.ARRAY_WEIGHTS]
			if ids.size()!=new_vertices.size()*4 or weights.size()!=ids.size():
				fail("Pesos/indices de ossos invalidos")
				return
			var originals: PackedFloat32Array=a[Mesh.ARRAY_WEIGHTS]
			for v in range(new_vertices.size()):
				var at := v*4
				var total := 0.0
				for w in range(4):
					total+=weights[at+w]
				if absf(total-1.0)>.001:
					fail("Peso total de um vertice diferente de 1")
					return
				if weights[at+1]>.05 and weights[at]>.05:
					skin_transitions+=1
				if absf(weights[at]-originals[at])>.01:
					changed+=1
				if weights[at]>.05:
					used_bones[ids[at]]=true
				if weights[at+1]>.05:
					used_bones[ids[at+1]]=true
			var mat := after.get_active_material(surface) as BaseMaterial3D
			if mat==null or mat.albedo_texture==null:
				fail("Atlas original da textura nao preservado")
				return
	if changed<20 or skin_transitions<20:
		fail("V2 nao alterou a distribuicao dos pesos em articulacoes: %d / %d" % [changed,skin_transitions])
		return
	var legs := false
	var arms := false
	for bone in used_bones.keys():
		if bone in [3,4,5,6]:
			arms=true
		if bone in [7,8,9,10,11,12]:
			legs=true
	if not arms or not legs:
		fail("Novo rig nao atingiu bracos e pernas")
		return
	var v2_skeletons: Array=newer.get("skeletons")
	if v2_skeletons.size()!=1 or (v2_skeletons[0] as Skeleton3D).get_bone_count()!=15:
		fail("Skeleton V2 incorreto")
		return
	newer.set("walk_phase",0.0)
	newer.call("animate",Vector3(0,0,2.0),.2,true)
	var skeleton := v2_skeletons[0] as Skeleton3D
	if skeleton.get_bone_pose_rotation(7).angle_to(Quaternion.IDENTITY)<.05:
		fail("Nova coxa nao gira na caminhada")
		return
	for equipment in ["sword_parts","shield_parts"]:
		var parts: Array=newer.get(equipment)
		if parts.is_empty():
			fail("Equipamento "+equipment+" foi perdido")
			return
	newer.call("set_equipment",false,false)
	if (newer.get("sword_parts") as Array)[0].visible or (newer.get("shield_parts") as Array)[0].visible:
		fail("Nao foi possivel esconder espada/escudo")
		return
	var scene: PackedScene=load("res://experimentos/goblin_skin_teste.tscn")
	if scene==null:
		fail("Cena visual comparativa nao pode ser aberta")
		return
	var lab := scene.instantiate() as Node3D
	if lab==null:
		fail("Nao foi possivel instanciar a cena comparativa")
		return
	root.add_child(lab)
	await process_frame
	var characters: Array=lab.get("characters")
	if characters.size()!=2:
		fail("Cena comparativa nao mostra os dois goblins: "+str(characters.size()))
		return
	for character in characters:
		if not is_instance_valid(character) or not bool(character.get_meta("skeleton_ready",false)):
			fail("Personagem da comparacao sem esqueleto")
			return
	lab.call("_set_motion","run")
	lab.call("_process",.17)
	lab.call("_turn")
	lab.call("_sword")
	lab.call("_shield")
	for character in characters:
		var swords: Array=character.get("sword_parts")
		var shields: Array=character.get("shield_parts")
		if swords.is_empty() or shields.is_empty() or not swords[0].visible or not shields[0].visible:
			fail("Controle visual de equipamento falhou")
			return
	print("SKIN V2 OK: cena aberta com 2 goblins, controles testados, UV intactas, %d vertices alterados, %d transicoes suaves." % [changed,skin_transitions])
	quit(0)
