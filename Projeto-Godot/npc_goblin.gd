extends Node3D
## NPC GOBLIN - modelo, textura, estrutura de corpo e animacao independentes.
## O GLB original e uma malha unica sem esqueleto. Criamos ossos e pesos de
## skinning em tempo de execucao, mantendo UVs, materiais e textura do arquivo.
## O movimento real e feito por Skeleton3D, nao pelo antigo balanco de cabeca.
const MODEL: PackedScene = preload("res://modelos/goblin_npc.glb")

const BONES := [
	"Quadril",       # 0
	"Coluna",        # 1
	"Cabeca",        # 2
	"BracoEsq",      # 3
	"AntebracoEsq",  # 4
	"BracoDir",      # 5
	"AntebracoDir",  # 6
	"CoxaEsq",       # 7
	"CanelaEsq",     # 8
	"CoxaDir",       # 9
	"CanelaDir",     # 10
	"PeEsq",         # 11
	"PeDir"          # 12
]
const PARENTS := [-1,0,1,1,3,1,5,0,7,0,9,8,10]

var skeletons: Array[Skeleton3D] = []
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
	for node in parts:
		var part := node as MeshInstance3D
		if part != null and part.mesh != null:
			_skin_part(part)
	if skeletons.is_empty():
		push_error("GLB sem pesos de ossos ou malhas compativeis.")
		pivot.queue_free()
		return false
	set_meta("skeleton_ready",true)
	return true

func _skin_part(part: MeshInstance3D) -> void:
	var original := part.mesh
	var aabb := original.get_aabb()
	var h := maxf(aabb.size.y,0.001)
	var low := aabb.position.y
	# Centra os ossos no corpo, nao na arma/orelha mais distante.
	var center_x := aabb.position.x+aabb.size.x*0.4
	var center_z := aabb.position.z+aabb.size.z*0.55
	var width := h
	# Pivots em coordenadas locais da malha. No GLB original a origem
	# esta na parte inferior e o eixo Y e invertido pelo node do importador.
	var joints := [
		Vector3(center_x,low+h*.64,center_z),
		Vector3(center_x,low+h*.49,center_z),
		Vector3(center_x,low+h*.29,center_z),
		Vector3(center_x-width*.15,low+h*.48,center_z),
		Vector3(center_x-width*.23,low+h*.61,center_z),
		Vector3(center_x+width*.15,low+h*.48,center_z),
		Vector3(center_x+width*.23,low+h*.61,center_z),
		Vector3(center_x-width*.07,low+h*.67,center_z),
		Vector3(center_x-width*.08,low+h*.82,center_z),
		Vector3(center_x+width*.07,low+h*.67,center_z),
		Vector3(center_x+width*.08,low+h*.82,center_z),
		Vector3(center_x-width*.08,low+h*.96,center_z),
		Vector3(center_x+width*.08,low+h*.96,center_z)
	]
	var skeleton := Skeleton3D.new()
	skeleton.name = "EsqueletoGoblin%d" % skeletons.size()
	part.get_parent().add_child(skeleton)
	for i in range(BONES.size()):
		var bone_id: int = skeleton.add_bone(BONES[i])
		var parent_id: int = int(PARENTS[i])
		if parent_id >= 0:
			skeleton.set_bone_parent(bone_id,parent_id)
		var offset: Vector3 = joints[i] if parent_id < 0 else joints[i]-joints[parent_id]
		skeleton.set_bone_rest(bone_id,Transform3D(Basis.IDENTITY,offset))
	skeleton.reset_bone_poses()
	var skinned := ArrayMesh.new()
	var vertex_total := 0
	for surface in range(original.get_surface_count()):
		var arrays: Array = original.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if vertices.is_empty():
			continue
		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()
		bones.resize(vertices.size()*4)
		weights.resize(vertices.size()*4)
		for i in range(vertices.size()):
			var assignment := _vertex_bone_weights(vertices[i],low,h,center_x)
			var index := i*4
			bones[index] = int(assignment.x)
			bones[index+1] = int(assignment.y)
			bones[index+2] = 0
			bones[index+3] = 0
			weights[index] = assignment.z
			weights[index+1] = 1.0-assignment.z
			weights[index+2] = 0.0
			weights[index+3] = 0.0
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
		skinned.add_surface_from_arrays(original.surface_get_primitive_type(surface),arrays)
		var original_material: Material = part.get_active_material(surface)
		if original_material != null:
			skinned.surface_set_material(skinned.get_surface_count()-1,original_material)
		vertex_total += vertices.size()
	if vertex_total == 0:
		skeleton.queue_free()
		return
	var skin := skeleton.create_skin_from_rest_transforms()
	part.material_override = null
	part.mesh = skinned
	part.skeleton = part.get_path_to(skeleton)
	part.skin = skin
	skeletons.append(skeleton)

func _vertex_bone_weights(v: Vector3, low: float, h: float, center_x: float) -> Vector3:
	var t := clampf((v.y-low)/h,0.0,1.0)
	var dx := (v.x-center_x)/h
	var lateral := absf(dx)
	var side_left := dx < 0.0
	var bone := 0
	var strength := 0.0
	# Cabeca/pescoco: a rotacao se transmite aos olhos e orelhas.
	if t < .42 and lateral < .48:
		bone = 2
		strength = clampf((.45-t)/.12,0.0,.95)
	# Bracos e antebracos, dos dois lados do tronco.
	elif t >= .40 and t < .71 and lateral > .13 and lateral < .44:
		var lower_arm := t > .57
		bone = (4 if lower_arm else 3) if side_left else (6 if lower_arm else 5)
		strength = clampf((lateral-.13)/.11,0.0,.96) * clampf((.73-t)/.09,0.0,1.0)
	# Pernas da cintura aos pes. Joelho e tornozelo recebem ossos proprios.
	elif t >= .61 and lateral < .26:
		if t > .90:
			bone = 11 if side_left else 12
		elif t > .78:
			bone = 8 if side_left else 10
		else:
			bone = 7 if side_left else 9
		strength = clampf((t-.61)/.12,0.0,.98)
	# Coluna, abdomen e ombros.
	elif t >= .34 and t < .69:
		bone = 1
		strength = clampf((.71-t)/.18,0.0,.85)
	# Equipamentos e outros vertices ficam vinculados ao quadril.
	var parent_id: int = int(PARENTS[bone])
	if parent_id < 0:
		parent_id = 0
	return Vector3(float(bone),float(parent_id),strength)

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
