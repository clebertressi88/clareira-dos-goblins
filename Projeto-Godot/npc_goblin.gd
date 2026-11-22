extends Node3D
## NPC GOBLIN - modelo, textura, estrutura de corpo e animacao independentes.
## O GLB original e uma malha unica sem esqueleto. Criamos ossos e pesos de
## skinning em tempo de execucao, mantendo UVs, materiais e textura do arquivo.
## O movimento real e feito por Skeleton3D, nao pelo antigo balanco de cabeca.
const MODEL: PackedScene = preload("res://modelos/goblin_npc.glb")
const EQUIPMENT = preload("res://npc_goblin_equipment.gd")
const SKIN_BUILDER = preload("res://npc_goblin_skin.gd")

const BONES := [
	"Quadril", "Coluna", "Cabeca", "BracoEsq", "AntebracoEsq",
	"BracoDir", "AntebracoDir", "CoxaEsq", "CanelaEsq",
	"CoxaDir", "CanelaDir", "PeEsq", "PeDir", "MaoEsq", "MaoDir"
]
const PARENTS := [-1,0,1,1,3,1,5,0,7,0,9,8,10,4,6]
# Pontos reais do modelo: o GLB apresenta bracos abertos e joelhos separados.
# Local -Y se torna +Y na transformacao de importacao Sketchfab.
const JOINTS := [
	Vector3(0,-22,-5), Vector3(0,-37,-5), Vector3(0,-47,-11),
	Vector3(-9,-40,-10), Vector3(-16,-29,-17),
	Vector3(9,-40,0), Vector3(21,-35,3),
	Vector3(-6,-21,5), Vector3(-8,-13,6),
	Vector3(7,-21,-15), Vector3(8,-13,-16),
	Vector3(-9,-6,8), Vector3(10,-6,-22),
	Vector3(-23,-28,-18), Vector3(34,-28,-2)
]

var skeletons: Array[Skeleton3D] = []
var sword_parts: Array[Node3D] = []
var shield_parts: Array[Node3D] = []
var sword_equipped := true
var shield_equipped := true
var walk_phase := 0.0
var walk_blend := 0.0

func install() -> bool:
	var instance := MODEL.instantiate()
	if not instance is Node3D:
		push_error("GLB invalido: cena 3D ausente.")
		if instance != null:
			instance.queue_free()
		return false
	var pivot := Node3D.new()
	pivot.name = "ModeloGoblinPivot"
	add_child(pivot)
	var model := instance as Node3D
	model.name = "ModeloGoblin"
	pivot.add_child(model)
	var parts := model.find_children("*","MeshInstance3D",true,false)
	var gear_sections: Dictionary = {}
	for node in parts:
		var part := node as MeshInstance3D
		if part == null or part.mesh == null:
			continue
		var pieces: Array = EQUIPMENT.split_mesh(part)
		if pieces[0] == null:
			continue
		gear_sections[part.get_instance_id()] = {"sword":pieces[1],"shield":pieces[2]}
		part.mesh = pieces[0]
	var bounds_min := Vector3(INF,INF,INF)
	var bounds_max := Vector3(-INF,-INF,-INF)
	for node in parts:
		var part := node as MeshInstance3D
		if part == null or part.mesh == null:
			continue
		var box: AABB = part.get_aabb()
		for x in [0.0,1.0]:
			for y in [0.0,1.0]:
				for z in [0.0,1.0]:
					var point := box.position+box.size*Vector3(x,y,z)
					var local := model.to_local(part.to_global(point))
					bounds_min = bounds_min.min(local)
					bounds_max = bounds_max.max(local)
	if not bounds_min.is_finite() or not bounds_max.is_finite():
		push_error("GLB sem malhas validas.")
		pivot.queue_free()
		return false
	var scale_factor := 1.5/maxf(bounds_max.y-bounds_min.y,0.001)
	model.scale = Vector3.ONE*scale_factor
	model.position = Vector3(
		-(bounds_min.x+bounds_max.x)*0.5,
		-bounds_min.y,
		-(bounds_min.z+bounds_max.z)*0.5)*scale_factor
	pivot.rotation.y = 0.0
	# Um unico Skeleton3D compartilhado pelas duas malhas originais.
	var skeleton := _create_anatomical_skeleton(parts[0].get_parent())
	for node in parts:
		var part := node as MeshInstance3D
		if part != null and part.mesh != null:
			_skin_part(part,skeleton)
			if gear_sections.has(part.get_instance_id()):
				var group: Dictionary = gear_sections[part.get_instance_id()]
				EQUIPMENT.attach(part,skeleton,group["sword"] as ArrayMesh,"Espada","MaoDir",sword_parts)
				EQUIPMENT.attach(part,skeleton,group["shield"] as ArrayMesh,"Escudo","MaoEsq",shield_parts)
	if skeletons.is_empty() or sword_parts.is_empty() or shield_parts.is_empty():
		push_error("GLB sem pesos de ossos ou malhas compativeis.")
		pivot.queue_free()
		return false
	set_equipment(sword_equipped,shield_equipped)
	set_meta("skeleton_ready",true)
	set_meta("atlas_original_preservado",true)
	return true

func set_equipment(sword: bool, shield: bool) -> void:
	sword_equipped = sword
	shield_equipped = shield
	for item in sword_parts:
		if is_instance_valid(item): item.visible = sword
	for item in shield_parts:
		if is_instance_valid(item): item.visible = shield

func _create_anatomical_skeleton(parent: Node) -> Skeleton3D:
	var skeleton := Skeleton3D.new()
	skeleton.name = "EsqueletoCorpo"
	parent.add_child(skeleton)
	for i in range(BONES.size()):
		var bone_idx: int = skeleton.add_bone(BONES[i])
		var parent_idx: int = int(PARENTS[i])
		if parent_idx >= 0:
			skeleton.set_bone_parent(bone_idx,parent_idx)
		var joint: Vector3 = JOINTS[i]
		var offset: Vector3 = joint if parent_idx < 0 else joint-JOINTS[parent_idx]
		skeleton.set_bone_rest(bone_idx,Transform3D(Basis.IDENTITY,offset))
	skeleton.reset_bone_poses()
	skeletons.append(skeleton)
	return skeleton


func _skin_part(part: MeshInstance3D, skeleton: Skeleton3D) -> void:
	var source: Mesh = part.mesh
	var skinned: ArrayMesh = SKIN_BUILDER.build(source)
	if skinned.get_surface_count()==0:
		push_error("Falha ao vincular malha ao Skeleton3D.")
		return
	var skin := skeleton.create_skin_from_rest_transforms()
	part.material_override = null
	part.mesh = skinned
	part.skeleton = part.get_path_to(skeleton)
	part.skin = skin


func animate(velocity: Vector3, dt: float, grounded: bool = true) -> void:
	var speed := Vector2(velocity.x,velocity.z).length()
	var target := clampf(speed/1.65,0.0,1.0) if grounded else 0.0
	walk_blend = move_toward(walk_blend,target,dt*6.0)
	walk_phase = fposmod(walk_phase+dt*(4.0+speed*2.2),TAU)
	var left_step := sin(walk_phase)*walk_blend
	var right_step := -left_step
	var breath := sin(Time.get_ticks_msec()*.001*1.6)*.018
	for skel in skeletons:
		if not is_instance_valid(skel):
			continue
		# Passos alternados: quadril, coxas, joelhos e pes articulados.
		skel.set_bone_pose_rotation(7,Quaternion(Vector3.RIGHT,left_step*.55))
		skel.set_bone_pose_rotation(9,Quaternion(Vector3.RIGHT,right_step*.55))
		skel.set_bone_pose_rotation(8,Quaternion(Vector3.RIGHT,maxf(0.0,-left_step)*.48))
		skel.set_bone_pose_rotation(10,Quaternion(Vector3.RIGHT,maxf(0.0,-right_step)*.48))
		skel.set_bone_pose_rotation(11,Quaternion(Vector3.RIGHT,-left_step*.24))
		skel.set_bone_pose_rotation(12,Quaternion(Vector3.RIGHT,-right_step*.24))
		# Contrabalanco de bracos e cotovelos.
		skel.set_bone_pose_rotation(3,Quaternion(Vector3.RIGHT,right_step*.43))
		skel.set_bone_pose_rotation(5,Quaternion(Vector3.RIGHT,left_step*.43))
		skel.set_bone_pose_rotation(4,Quaternion(Vector3.RIGHT,-maxf(0.0,right_step)*.32))
		skel.set_bone_pose_rotation(6,Quaternion(Vector3.RIGHT,-maxf(0.0,left_step)*.32))
		skel.set_bone_pose_rotation(1,Quaternion(Vector3.FORWARD,sin(walk_phase)*walk_blend*.042))
		skel.set_bone_pose_rotation(2,Quaternion(Vector3.RIGHT,breath))
