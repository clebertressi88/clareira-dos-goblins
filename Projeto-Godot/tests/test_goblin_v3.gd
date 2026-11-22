extends SceneTree
## Confirma que o novo goblin se monta sem o GLB antigo e sem romper a malha.
const GOBLIN_V3 = preload("res://experimentos/goblin_v3_model.gd")

func _initialize() -> void:
	call_deferred("_run")

func fail(reason: String) -> void:
	printerr("GOBLIN V3 FAIL: "+reason)
	quit(1)

func _run() -> void:
	var model: Node3D = GOBLIN_V3.new()
	root.add_child(model)
	await process_frame
	if not bool(model.call("install")):
		fail("Falha ao montar estrutura 3D")
		return
	var skeleton := model.get_node_or_null("EsqueletoGoblinV3") as Skeleton3D
	if skeleton==null or skeleton.get_bone_count()!=16:
		fail("Esqueleto incompleto: esperado 16 articulacoes")
		return
	var keys: Array = [
		"Quadril","Coluna","Pescoco","Cabeca",
		"OmbroEsq","CotoveloEsq","MaoEsq",
		"OmbroDir","CotoveloDir","MaoDir",
		"CoxaEsq","JoelhoEsq","TornozeloEsq",
		"CoxaDir","JoelhoDir","TornozeloDir"
	]
	for name in keys:
		if skeleton.find_bone(name)<0 or skeleton.get_node_or_null("Junta_"+name)==null:
			fail("Articulacao ausente: "+name)
			return
	var parts := model.find_children("*","MeshInstance3D",true,false)
	if parts.size()<125:
		fail("O corpo detalhado precisa de pecas e acabamentos: "+str(parts.size()))
		return
	for part_node in parts:
		var part := part_node as MeshInstance3D
		if part.mesh==null:
			fail("Parte do corpo sem malha: "+part.name)
			return
		if part.skin!=null:
			fail("Parte ainda usa skin que pode esticar: "+part.name)
			return
		if not part.get_parent() is BoneAttachment3D:
			fail("Parte solta do esqueleto: "+part.name)
			return
	if int(model.get_meta("acabamento_v3",0))!=2:
		fail("O acabamento anatomico detalhado nao foi aplicado")
		return
	var names: Dictionary={}
	var detail_materials := 0
	for node in parts:
		var part := node as MeshInstance3D
		names[part.name]=true
		if part.material_override is ShaderMaterial:
			detail_materials+=1
	for required in ["CranioEsculpido","OrelhaExterna-1","OrelhaExterna1",
			"IrisAmbarEsq","IrisAmbarDir","NarizPontudo","TorsoAnatomico",
			"PanturrilhaEsq","PanturrilhaDir","BiqueiraEsq","BiqueiraDir",
			"PalmaAnatomicaEsq","PalmaAnatomicaDir"]:
		if not names.has(required):
			fail("Detalhe anatomico ausente: "+required)
			return
	if detail_materials<45:
		fail("Textura procedural de pele e couro nao foi aplicada: "+str(detail_materials))
		return
	var swords: Array=model.get("sword_parts")
	var shields: Array=model.get("shield_parts")
	if swords.size()<3 or shields.size()<2:
		fail("Espada/escudo precisam ser objetos independentes")
		return
	model.call("set_equipment",true,true)
	if not swords[0].visible or not shields[0].visible:
		fail("Equipar espada e escudo falhou")
		return
	model.call("set_equipment",false,false)
	if swords[0].visible or shields[0].visible:
		fail("Retirar espada e escudo falhou")
		return
	var hip_rest := skeleton.get_bone_rest(0).origin
	model.set("walk_phase",0.0)
	model.set("walk_blend",0.0)
	model.call("animate",Vector3(0,0,1.6),.17,true)
	var walk_angle := skeleton.get_bone_pose_rotation(10).angle_to(Quaternion.IDENTITY)
	if walk_angle<.05:
		fail("Caminhar nao movimenta a coxa")
		return
	model.set("walk_phase",0.0)
	model.set("walk_blend",0.0)
	model.call("animate",Vector3(0,0,4.0),.17,true)
	var run_angle := skeleton.get_bone_pose_rotation(10).angle_to(Quaternion.IDENTITY)
	if run_angle<=walk_angle+.15:
		fail("Correr precisa de passada maior que caminhar: %.2f / %.2f" % [run_angle,walk_angle])
		return
	if skeleton.get_bone_pose_position(0).distance_to(hip_rest)>.09:
		fail("O quadril saiu da posicao e faria o corpo afundar")
		return
	var scene: PackedScene=load("res://experimentos/goblin_v3.tscn")
	if scene==null:
		fail("Cena independente do Goblin V3 ausente")
		return
	var compare_scene: PackedScene=load("res://experimentos/goblin_skin_teste.tscn")
	if compare_scene==null:
		fail("Laboratorio comparativo ausente")
		return
	var lab := compare_scene.instantiate() as Node3D
	root.add_child(lab)
	await process_frame
	var characters: Array=lab.get("characters")
	if characters.size()!=2 or not bool(characters[1].get_meta("modelo_goblin_v3",false)):
		fail("O laboratorio nao mostra goblin antigo versus novo V3")
		return
	lab.call("_set_motion","run")
	lab.call("_process",.17)
	lab.call("_sword")
	lab.call("_shield")
	var right: Node3D=characters[1]
	if not (right.get("sword_parts") as Array)[0].visible or not (right.get("shield_parts") as Array)[0].visible:
		fail("Controles do laboratorio nao equiparam objetos V3")
		return
	print("GOBLIN V3 OK: 16 juntas, %d malhas articuladas e detalhadas, rosto/orelhas/textura/corrida/equipamentos." % parts.size())
	quit(0)
