extends Node3D
## Controlador visual do Goblin Skirmisher usado por jogador, NPC e multiplayer.
## Toda a colisao, IA, inventario, rede e saves permanecem no main.gd.
## O asset original nao e modificado: o rig nativo conserva as 110 animacoes.
const MODEL: PackedScene = preload("res://modelos/goblin_skirmisher/Character/GoblinSkirmisher.scn")
const CLIPS := {
	"idle": "A000_Idle",
	"walk": "A-02_Walking",
	"run": "A-01_Running",
	"attack": "A219_Right_hand_Sword_Slash",
	"hit": "A178_Hit_Reaction",
	"death": "A008_Dead"
}
const NPC_INFO := {
	"bruma": {"name": "BRUMA", "color": Color("#a981bc")},
	"talo": {"name": "TALO", "color": Color("#ca9a4b")},
	"guardiao": {"name": "GUARDIAO", "color": Color("#b85446")}
}

var variant := "player"
var sword_equipped := false
var shield_equipped := false
var skeletons: Array[Skeleton3D] = []
var sword_parts: Array[Node3D] = []
var shield_parts: Array[Node3D] = []
var _actor: Node3D
var _animation_player: AnimationPlayer
var _skeleton: Skeleton3D
var _dagger: Node3D
var _shield: Node3D
var _grip_meshes: Array[MeshInstance3D] = []
var _state := ""
var _action_locked := false
var _quiet_idle_time := 0.0
var _quiet_idle_bone := -1
var _quiet_idle_base := Vector3.ONE

func set_variant(role: String) -> void:
	var clean := role.to_lower()
	variant = clean if clean in ["player", "bruma", "talo", "guardiao"] else "player"

func install() -> bool:
	var instance := MODEL.instantiate()
	if not instance is Node3D:
		push_error("Goblin Skirmisher: cena original nao possui raiz Node3D.")
		if instance != null:
			instance.queue_free()
		return false
	_actor = instance as Node3D
	_actor.name = "SkirmisherOriginal"
	add_child(_actor)
	var skeleton_nodes := _actor.find_children("*", "Skeleton3D", true, false)
	if skeleton_nodes.is_empty():
		push_error("Goblin Skirmisher: Skeleton3D nativo ausente.")
		_actor.queue_free()
		return false
	_skeleton = skeleton_nodes[0] as Skeleton3D
	skeletons.append(_skeleton)
	var players := _actor.find_children("*", "AnimationPlayer", true, false)
	for node in players:
		var current := node as AnimationPlayer
		if current != null and current.has_animation(CLIPS["idle"]) and current.has_animation(CLIPS["walk"]):
			_animation_player = current
			break
	if _animation_player == null:
		push_error("Goblin Skirmisher: animacoes principais nao encontradas.")
		_actor.queue_free()
		return false
	for tree in _actor.find_children("*", "AnimationTree", true, false):
		(tree as AnimationTree).active = false
	_dagger = _actor.find_child("Dagger", true, false) as Node3D
	if _dagger != null:
		sword_parts.append(_dagger)
	for mesh_node in _actor.find_children("*", "MeshInstance3D", true, false):
		var part := mesh_node as MeshInstance3D
		if part == null or part.mesh == null:
			continue
		for i in range(part.get_blend_shape_count()):
			if part.mesh.get_blend_shape_name(i) == "WeaponGrip":
				_grip_meshes.append(part)
				break
	_create_shield()
	_create_npc_identifier()
	_animation_player.animation_finished.connect(_on_animation_finished)
	_state = ""
	_action_locked = false
	# Guardioes nascem armados. Os jogadores usam os equipamentos salvos.
	sword_equipped = variant == "guardiao"
	shield_equipped = variant == "guardiao"
	_apply_equipment()
	_switch_motion("idle", 1.0)
	set_meta("skeleton_ready", true)
	set_meta("modelo_skirmisher", true)
	return true

## Prende um acessorio ao osso do tronco, em vez da raiz imovel do jogador.
## O BoneAttachment3D acompanha a pose calculada pelo AnimationPlayer.
func attach_backpack(accessory: Node3D) -> bool:
	if _skeleton == null or not is_instance_valid(_skeleton):
		return false
	var bone_index := -1
	var best_score := -1
	for index in range(_skeleton.get_bone_count()):
		var name := _skeleton.get_bone_name(index).to_lower().replace("_","").replace(".","").replace(":","")
		var score := -1
		if name.contains("spine"):
			score = 10
			if name.contains("2") or name.contains("02"):
				score = 15
			elif name.contains("1") or name.contains("01"):
				score = 13
		elif name.contains("chest") or name.contains("upperbody"):
			score = 14
		elif name.contains("torso"):
			score = 9
		if score>best_score:
			best_score = score
			bone_index = index
	if bone_index<0:
		push_warning("Mochila: nao foi possivel localizar um osso do tronco.")
		return false
	var anchor := BoneAttachment3D.new()
	anchor.name = "MochilaNasCostas"
	anchor.bone_name = _skeleton.get_bone_name(bone_index)
	_skeleton.add_child(anchor)
	accessory.reparent(anchor,false)
	# BoneAttachment herda os eixos locais do osso importado. A orientacao
	# desse osso nem sempre coincide com os eixos da mochila. Compensar a
	# pose inicial evita que ela atravesse o corpo ou fique invisivel.
	var chest_pose: Transform3D = _skeleton.get_bone_global_pose(bone_index)
	var chest_basis: Basis = chest_pose.basis.orthonormalized()
	var correction: Basis = chest_basis.inverse()
	accessory.transform = Transform3D(
		correction.scaled(Vector3.ONE * 0.92),
		correction * Vector3(0.0,-0.07,-0.21)
	)
	return true

func set_equipment(sword: bool, shield: bool) -> void:
	if sword_equipped == sword and shield_equipped == shield and _actor != null:
		return
	sword_equipped = sword
	shield_equipped = shield
	if _actor != null:
		_apply_equipment()

func _apply_equipment() -> void:
	if _dagger != null:
		_dagger.visible = sword_equipped
	if _shield != null:
		_shield.visible = shield_equipped
	for part in _grip_meshes:
		if not is_instance_valid(part) or part.mesh == null:
			continue
		for i in range(part.get_blend_shape_count()):
			if part.mesh.get_blend_shape_name(i) == "WeaponGrip":
				part.set_blend_shape_value(i, 1.0 if sword_equipped else 0.0)

func _find_left_hand() -> int:
	for i in range(_skeleton.get_bone_count()):
		var n := _skeleton.get_bone_name(i).to_lower().replace("_", "").replace(":", "").replace(".", "")
		if n.contains("lefthand") or n.ends_with("handl") or n == "lhand":
			return i
	return -1

func _make_material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	material.metallic = metallic
	return material

func _add_box(parent: Node3D, name_text: String, at: Vector3, size: Vector3, color: Color, tilt: float = 0.0) -> void:
	var piece := MeshInstance3D.new()
	piece.name = name_text
	var cube := BoxMesh.new()
	cube.size = size
	piece.mesh = cube
	piece.material_override = _make_material(color)
	piece.position = at
	piece.rotation.z = tilt
	parent.add_child(piece)

func _create_shield() -> void:
	_shield = Node3D.new()
	_shield.name = "EscudoSkirmisher"
	var left_hand := _find_left_hand()
	if left_hand >= 0:
		var anchor := BoneAttachment3D.new()
		anchor.name = "MaoEsquerdaEscudo"
		anchor.bone_name = _skeleton.get_bone_name(left_hand)
		_skeleton.add_child(anchor)
		anchor.add_child(_shield)
		_shield.position = Vector3(-0.035, 0.015, 0.08)
	else:
		# Fallback seguro para rigs com outros nomes de ossos.
		_actor.add_child(_shield)
		_shield.position = Vector3(-0.40, 0.83, 0.19)
	var disc := MeshInstance3D.new()
	disc.name = "MadeiraDoEscudo"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.225
	mesh.bottom_radius = 0.225
	mesh.height = 0.055
	mesh.radial_segments = 12
	disc.mesh = mesh
	disc.rotation.x = PI * 0.5
	disc.material_override = _make_material(Color("#5d3d2b"))
	_shield.add_child(disc)
	_add_box(_shield, "ReforcoMetalico", Vector3(0.0, 0.0, 0.035), Vector3(0.075, 0.36, 0.045), Color("#888681"))
	_add_box(_shield, "ReforcoHorizontal", Vector3(0.0, 0.0, 0.057), Vector3(0.34, 0.055, 0.028), Color("#888681"))
	shield_parts.append(_shield)

func _create_npc_identifier() -> void:
	if not NPC_INFO.has(variant):
		return
	var info: Dictionary = NPC_INFO[variant]
	var colored: Color = info["color"]
	# Diferenciacao discreta: apenas o nome acima da cabeca, sem faixas
	# cruzadas ou ombreira retangular flutuante sobre as animacoes.
	var name_label := Label3D.new()
	name_label.name = "NomeNPC"
	name_label.text = str(info["name"])
	name_label.position = Vector3(0.0, 1.63, 0.0)
	name_label.font_size = 38
	name_label.pixel_size = 0.0026
	name_label.outline_size = 9
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.modulate = colored.lightened(0.32)
	add_child(name_label)

# Pose noturna procedural sobre o rig original; nao altera os clips do jogador.
var _camp_warm := false
var _camp_stretch := -1.0
var _camp_weight := 0.0
var _camp_base: Dictionary = {}
var _camp_arms: Array[Vector2i] = []
var _camp_head := -1
var _camp_cached := false

func set_camp_warmth(enabled: bool, stretch: float = -1.0) -> void:
	_camp_warm = enabled and variant in ["bruma","talo"]
	_camp_stretch = clampf(stretch,0.0,1.0) if _camp_warm and stretch>=0.0 else -1.0

func _camp_find_bones() -> void:
	if _camp_cached:
		return
	_camp_cached = true
	for i in range(_skeleton.get_bone_count()):
		var n := str(_skeleton.get_bone_name(i)).to_lower().replace("_","").replace(".","").replace(":","")
		if n.contains("head") and not n.contains("end"):
			_camp_head = i
		if n.contains("forearm") or n.contains("lowerarm") or n.contains("elbow"):
			var upper := _skeleton.get_bone_parent(i)
			if upper>=0:
				_camp_arms.append(Vector2i(upper,i))

func _camp_restore() -> void:
	if _skeleton!=null:
		for key in _camp_base:
			_skeleton.set_bone_pose_rotation(int(key),_camp_base[key])
	_camp_base.clear()

func _camp_aim(bone: int, child: int, desired: Vector3, weight: float) -> void:
	var at := _skeleton.get_bone_global_pose(bone).origin
	var toward := _skeleton.get_bone_global_pose(child).origin-at
	if toward.length_squared()<0.00001 or desired.is_zero_approx():
		return
	var delta := Quaternion(toward.normalized(),toward.normalized().lerp(desired.normalized(),weight).normalized())
	var parent := _skeleton.get_bone_parent(bone)
	var parent_basis := Basis.IDENTITY
	if parent>=0:
		parent_basis = _skeleton.get_bone_global_pose(parent).basis.orthonormalized()
	var local_delta := parent_basis.get_rotation_quaternion().inverse()*delta*parent_basis.get_rotation_quaternion()
	_skeleton.set_bone_pose_rotation(bone,(local_delta*_skeleton.get_bone_pose_rotation(bone)).normalized())

func _camp_pose(dt: float) -> void:
	_camp_weight = move_toward(_camp_weight,1.0 if _camp_warm else 0.0,dt*2.5)
	if _camp_weight<=0.0:
		_camp_restore()
		return
	_camp_find_bones()
	# Restaurar a pose de base a cada quadro: nunca acumular rotacoes.
	if _camp_base.is_empty():
		for pair in _camp_arms:
			_camp_base[pair.x] = _skeleton.get_bone_pose_rotation(pair.x)
			_camp_base[pair.y] = _skeleton.get_bone_pose_rotation(pair.y)
		if _camp_head>=0:
			_camp_base[_camp_head] = _skeleton.get_bone_pose_rotation(_camp_head)
	for key in _camp_base:
		_skeleton.set_bone_pose_rotation(int(key),_camp_base[key])
	var stretch := sin(_camp_stretch*PI) if _camp_stretch>=0.0 else 0.0
	stretch = smoothstep(0.0,1.0,stretch)
	var convert := _skeleton.global_transform.basis.orthonormalized().inverse()*global_transform.basis.orthonormalized()
	var forward := (convert*Vector3.BACK).normalized()
	var up := (convert*Vector3.UP).normalized()
	var right := (convert*Vector3.RIGHT).normalized()
	var torso_center := _skeleton.get_bone_global_pose(_quiet_idle_bone).origin if _quiet_idle_bone>=0 else Vector3.ZERO
	for pair in _camp_arms:
		var shoulder := _skeleton.get_bone_global_pose(pair.x).origin
		var side := 1.0 if (shoulder-torso_center).dot(right)>=0.0 else -1.0
		var warm_upper := forward*0.55-up*0.8+right*side*0.18
		var stretch_upper := up*0.9+right*side*0.45+forward*0.14
		_camp_aim(pair.x,pair.y,warm_upper.lerp(stretch_upper,stretch),_camp_weight)
		var hand := -1
		for child in _skeleton.get_bone_children(pair.y):
			hand = child
			break
		if hand>=0:
			var small := sin(_quiet_idle_time*1.3+side)*0.035
			var warm_lower := forward*0.93+up*(0.30+small)-right*side*0.15
			var stretch_lower := up*0.95+right*side*0.18
			_camp_aim(pair.y,hand,warm_lower.lerp(stretch_lower,stretch),_camp_weight)
	if _camp_head>=0:
		var parent := _skeleton.get_bone_parent(_camp_head)
		var axis := right
		if parent>=0:
			axis = _skeleton.get_bone_global_pose(parent).basis.orthonormalized().inverse()*right
		var nod := (0.10+sin(_quiet_idle_time*0.45)*0.025-0.18*stretch)*_camp_weight
		var base: Quaternion = _camp_base[_camp_head]
		_skeleton.set_bone_pose_rotation(_camp_head,(Quaternion(axis.normalized(),nod)*base).normalized())

func _update_quiet_idle(dt: float) -> void:
	if _quiet_idle_bone < 0:
		for i in range(_skeleton.get_bone_count()):
			var n := _skeleton.get_bone_name(i).to_lower()
			if n.contains("chest") or n.contains("spine"):
				_quiet_idle_bone = i
				_quiet_idle_base = _skeleton.get_bone_pose_scale(i)
				if n.contains("chest"):
					break
	if _quiet_idle_bone >= 0:
		_quiet_idle_time += dt
		var breath := 1.0 + sin(_quiet_idle_time * TAU / 3.6) * 0.008
		_skeleton.set_bone_pose_scale(_quiet_idle_bone, _quiet_idle_base * breath)

func _switch_motion(new_state: String, rate: float) -> void:
	if _animation_player == null or not CLIPS.has(new_state):
		return
	var clip: String = CLIPS[new_state]
	if not _animation_player.has_animation(clip):
		return
	if _state != new_state or _animation_player.current_animation != clip:
		_camp_restore()
		_camp_weight = 0.0
		if _state == "idle" and _quiet_idle_bone >= 0:
			_skeleton.set_bone_pose_scale(_quiet_idle_bone, _quiet_idle_base)
		_quiet_idle_bone = -1
		_state = new_state
		_animation_player.speed_scale = 1.0
		_animation_player.play(clip, 0.14, rate)
		if new_state == "idle":
			_animation_player.seek(0.0, true)
			# Manter a animacao idle ativa e congelada no quadro inicial.
			# pause() pode limpar current_animation e romper os testes do Skirmisher.
			_animation_player.speed_scale = 0.0
			_quiet_idle_time = 0.0
	else:
		_animation_player.speed_scale = 0.0 if new_state == "idle" else rate

func animate(velocity: Vector3, _dt: float, grounded: bool = true) -> void:
	if _animation_player == null or _action_locked:
		return
	var speed := Vector2(velocity.x, velocity.z).length()
	var target := "idle"
	var rate := 1.0
	if speed > 2.25 and grounded:
		target = "run"
		rate = clampf(speed / 3.2, 0.85, 1.5)
	elif speed > 0.16 and grounded:
		target = "walk"
		rate = clampf(speed / 1.65, 0.7, 1.55)
	_switch_motion(target, rate)
	if target == "idle":
		_update_quiet_idle(_dt)
		if variant in ["bruma","talo"]:
			_camp_pose(_dt)

func play_action(action: String) -> void:
	if _animation_player == null or action not in ["attack", "hit", "death"]:
		return
	_camp_warm = false
	_camp_stretch = -1.0
	_camp_restore()
	_camp_weight = 0.0
	_action_locked = true
	_switch_motion(action, 1.0)

func _on_animation_finished(_name: StringName) -> void:
	if _action_locked:
		if _state == "death":
			return
		_action_locked = false
		_switch_motion("idle", 1.0)
	elif _state in ["idle", "walk", "run"] and _animation_player != null and not (_state == "idle"):
		_animation_player.play(CLIPS[_state])

func get_animation_player() -> AnimationPlayer:
	return _animation_player

func get_skeleton() -> Skeleton3D:
	return _skeleton
