extends SceneTree
## Estrutura de testes V4: geometria organica, bones rigidamente ligados,
## equipamentos opcionais e comparacao no laboratorio sem tocar no jogo real.
const MODEL = preload("res://experimentos/goblin_v4_model.gd")

func _initialize() -> void:
	call_deferred("_run")

func fail(reason: String) -> void:
	printerr("GOBLIN V4 FAIL: "+reason)
	quit(1)

func _run() -> void:
	var goblin := MODEL.new() as Node3D
	root.add_child(goblin)
	await process_frame
	if absf(goblin.scale.y * 2.233 - 1.25) > .015:
		fail("Altura final do V4 diferente de 1,25 m")
		return
	if not goblin.has_meta("modelo_goblin_v4"):
		fail("Escultura V4 nao foi carregada")
		return
	var skeleton := goblin.get_node_or_null("EsqueletoGoblinV3") as Skeleton3D
	if skeleton==null or skeleton.get_bone_count()!=16:
		fail("Esqueleto articulado perdeu ossos")
		return
	var required := [
		"V4_CranioEsculpido","V4_NarizAnatomico",
		"V4_OrelhaEsq","V4_OrelhaDir","V4_ConchaOrelhaEsq",
		"V4_OlhoEsq","V4_OlhoDir","V4_SobrancelhaEsq",
		"V4_TorsoUnificado","V4_CintoDeCouro",
		"V4_ParteSuperiorBracoEsq","V4_ParteSuperiorBracoDir",
		"V4_AntebracoEsq","V4_AntebracoDir",
		"V4_PalmaEsq","V4_PalmaDir",
		"V4_CoxaEsq","V4_CoxaDir","V4_PanturrilhaEsq",
		"V4_PanturrilhaDir","V4_BotaInteiraEsq","V4_BotaInteiraDir"
	]
	var items: Dictionary={}
	var all_meshes:=goblin.find_children("*","MeshInstance3D",true,false)
	for mesh_node in all_meshes:
		var part := mesh_node as MeshInstance3D
		items[part.name]=part
		if part.mesh==null or part.get_parent() is not BoneAttachment3D:
			fail("Malha nao articulada ou sem geometria: "+part.name)
			return
		if part.skin!=null:
			fail("Skin elastica indevida: "+part.name)
			return
	for item in required:
		if not items.has(item):
			fail("Falta detalhe essencial: "+item)
			return
	if all_meshes.size()<75:
		fail("Modelo V4 muito simplificado: "+str(all_meshes.size()))
		return
	# Garante que os novos materiais procedurais estao aplicados na malha real.
	for piece in ["V4_CranioEsculpido", "V4_TorsoUnificado", "V4_CintoDeCouro", "V4_BotaInteiraDir"]:
		var mesh_part := items[piece] as MeshInstance3D
		if not (mesh_part.material_override is ShaderMaterial):
			fail("Material procedural ausente: " + piece)
			return
		var shader_mat := mesh_part.material_override as ShaderMaterial
		if shader_mat.shader == null:
			fail("Shader nao carregado: " + piece)
			return
	var head := items["V4_CranioEsculpido"] as MeshInstance3D
	var ear := items["V4_OrelhaDir"] as MeshInstance3D
	var nose := items["V4_NarizAnatomico"] as MeshInstance3D
	var boot := items["V4_BotaInteiraDir"] as MeshInstance3D
	# Nao basta criar objetos: o formato da anatomia precisa estar presente.
	if head.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()<1500:
		fail("Cabeca ainda usa primitiva simples")
		return
	if ear.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()<100:
		fail("Orelha nao possui concha 3D")
		return
	if nose.mesh.get_aabb().size.z<.14:
		fail("Nariz nao foi esculpido em profundidade")
		return
	if boot.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()<250:
		fail("Bota nao possui biqueira anatomica")
		return
	var swords: Array=goblin.get("sword_parts")
	var shields: Array=goblin.get("shield_parts")
	if swords.size()<3 or shields.size()<2:
		fail("Armas/escudo nao estao separados")
		return
	goblin.call("set_equipment",true,true)
	if not swords[0].visible or not shields[0].visible:
		fail("Equipar falhou")
		return
	goblin.call("set_equipment",false,false)
	if swords[0].visible or shields[0].visible:
		fail("Desequipar falhou")
		return
	goblin.set("walk_phase",0.0)
	goblin.set("walk_blend",0.0)
	goblin.call("animate",Vector3(0,0,1.6),.18,true)
	var walk_angle:=skeleton.get_bone_pose_rotation(10).angle_to(Quaternion.IDENTITY)
	goblin.set("walk_phase",0.0)
	goblin.set("walk_blend",0.0)
	goblin.call("animate",Vector3(0,0,4.0),.18,true)
	var run_angle:=skeleton.get_bone_pose_rotation(10).angle_to(Quaternion.IDENTITY)
	if run_angle<=walk_angle+.12:
		fail("Correr nao tem passada independente")
		return
	var comparison: PackedScene=load("res://experimentos/goblin_skin_teste.tscn")
	if comparison==null:
		fail("Laboratorio de comparacao ausente")
		return
	var lab := comparison.instantiate() as Node3D
	root.add_child(lab)
	await process_frame
	var cast: Array=lab.get("characters")
	if cast.size()!=2 or not cast[1].has_meta("modelo_goblin_v4"):
		fail("Laboratorio nao mostra V4 ao lado do modelo atual")
		return
	print("GOBLIN V4 OK: escultura organica, %d pecas, 16 juntas, orelhas 3D, corrida e equipamentos." % all_meshes.size())
	quit(0)
