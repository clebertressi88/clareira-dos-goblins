extends "res://npc_goblin.gd"
## Laboratorio de rig v2: aproveita modelo, textura, espada e escudo existentes.
## Sobrescreve somente a skin, os pontos anatomicos e a animacao do esqueleto.
## O rig utilizado pelos NPCs na partida continua em npc_goblin.gd.
const SKIN_V2 = preload("res://experimentos/goblin_skin_v2_weights.gd")

const JOINTS_V2 := [
	Vector3(0,-22,-6),    # quadril
	Vector3(0,-37,-7),    # peito
	Vector3(0,-54,-12),   # cabeca
	Vector3(-12,-39,-12), # ombro esquerdo
	Vector3(-19,-29,-17), # cotovelo esquerdo
	Vector3(13,-41,1),    # ombro direito
	Vector3(25,-33,2),    # cotovelo direito
	Vector3(-8,-20,6),    # quadril esquerdo
	Vector3(-8,-12,7),    # joelho esquerdo
	Vector3(8,-20,-16),   # quadril direito
	Vector3(9,-12,-18),   # joelho direito
	Vector3(-8,-5,8),    # pe esquerdo
	Vector3(10,-5,-21),   # pe direito
	Vector3(-25,-24,-18), # mao esquerda
	Vector3(34,-25,-2)    # mao direita
]

func _create_anatomical_skeleton(parent: Node) -> Skeleton3D:
	var skeleton := Skeleton3D.new()
	skeleton.name = "EsqueletoV2"
	parent.add_child(skeleton)
	for i in range(BONES.size()):
		var idx: int = skeleton.add_bone(BONES[i])
		var parent_idx: int = int(PARENTS[i])
		if parent_idx>=0:
			skeleton.set_bone_parent(idx,parent_idx)
		var offset: Vector3 = JOINTS_V2[i]
		if parent_idx>=0:
			offset-=JOINTS_V2[parent_idx]
		skeleton.set_bone_rest(idx,Transform3D(Basis.IDENTITY,offset))
	skeleton.reset_bone_poses()
	skeletons.append(skeleton)
	return skeleton


func _skin_part(part: MeshInstance3D, skeleton: Skeleton3D) -> void:
	var new_mesh: ArrayMesh = SKIN_V2.build(part.mesh)
	if new_mesh.get_surface_count()==0:
		push_error("Teste V2: malha sem superficies.")
		return
	part.mesh=new_mesh
	part.material_override=null
	part.skeleton=part.get_path_to(skeleton)
	part.skin=skeleton.create_skin_from_rest_transforms()


func animate(velocity: Vector3, dt: float, grounded: bool=true) -> void:
	var speed := Vector2(velocity.x,velocity.z).length()
	var target := clampf(speed/2.25,0,1) if grounded else 0.0
	walk_blend=move_toward(walk_blend,target,dt*4.0)
	walk_phase=fposmod(walk_phase+dt*(3.8+speed*2.5),TAU)
	var left := sin(walk_phase)*walk_blend
	var right := -left
	var bounce := sin(walk_phase*2.0)*walk_blend*.025
	var breath := sin(Time.get_ticks_msec()*.001*1.4)*.008
	for skel in skeletons:
		if not is_instance_valid(skel):
			continue
		skel.set_bone_pose_position(0,Vector3(0,bounce,0))
		skel.set_bone_pose_rotation(7,Quaternion(Vector3.RIGHT,left*.53))
		skel.set_bone_pose_rotation(9,Quaternion(Vector3.RIGHT,right*.53))
		skel.set_bone_pose_rotation(8,Quaternion(Vector3.RIGHT,maxf(-left,0)*.57))
		skel.set_bone_pose_rotation(10,Quaternion(Vector3.RIGHT,maxf(-right,0)*.57))
		skel.set_bone_pose_rotation(11,Quaternion(Vector3.RIGHT,-left*.26))
		skel.set_bone_pose_rotation(12,Quaternion(Vector3.RIGHT,-right*.26))
		skel.set_bone_pose_rotation(3,Quaternion(Vector3.RIGHT,right*.39))
		skel.set_bone_pose_rotation(5,Quaternion(Vector3.RIGHT,left*.39))
		skel.set_bone_pose_rotation(4,Quaternion(Vector3.RIGHT,maxf(-right,0)*.21))
		skel.set_bone_pose_rotation(6,Quaternion(Vector3.RIGHT,maxf(-left,0)*.21))
		skel.set_bone_pose_rotation(1,Quaternion(Vector3.FORWARD,left*.027))
		skel.set_bone_pose_rotation(2,Quaternion(Vector3.RIGHT,breath))
