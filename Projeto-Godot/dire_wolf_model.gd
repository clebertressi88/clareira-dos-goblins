extends Node3D
## Dire Wolf por Literock Studios. Somente visual; IA e colisoes ficam no main.
## O asset licenciado nao e redistribuido no repositorio publico.
static var cached_scene: PackedScene
var animation_player: AnimationPlayer
var attack_clip := ""
var current_clip := ""

static func _find_asset() -> String:
	var config := ConfigFile.new()
	if config.load("user://dire_wolf_lab.cfg") == OK:
		var path := str(config.get_value("asset", "path", ""))
		if FileAccess.file_exists(path):
			return path
	for folder in [OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS), OS.get_executable_path().get_base_dir(), "user://"]:
		if str(folder).is_empty():
			continue
		for filename in ["Dire_Wolf_Lite_v1.0.0.zip", "Dire_Wolf_Lite.glb"]:
			var path := str(folder).path_join(filename)
			if FileAccess.file_exists(path):
				return path
	return ""

static func _assign_owners(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		_assign_owners(child, root)

static func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null

static func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

static func _cache_asset() -> bool:
	if cached_scene != null:
		return true
	var bundled := "res://modelos/dire_wolf/Dire_Wolf_Lite.glb"
	if ResourceLoader.exists(bundled, "PackedScene"):
		cached_scene = load(bundled) as PackedScene
		return cached_scene != null
	var path := _find_asset()
	if path.is_empty():
		return false
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var result: Error = ERR_INVALID_PARAMETER
	if path.get_extension().to_lower() == "zip":
		var zip := ZIPReader.new()
		if zip.open(path) != OK:
			return false
		var entry := "Dire_Wolf_Lite/Dire_Wolf_Lite.glb"
		if not zip.file_exists(entry):
			zip.close()
			return false
		var data := zip.read_file(entry)
		zip.close()
		result = document.append_from_buffer(data, "", state)
	elif path.get_extension().to_lower() == "glb":
		result = document.append_from_file(path, state)
	if result != OK:
		return false
	var imported := document.generate_scene(state)
	if not (imported is Node3D):
		if imported != null:
			imported.free()
		return false
	var skeleton := _find_skeleton(imported)
	if skeleton == null or skeleton.get_bone_count() != 35 or _find_player(imported) == null:
		imported.free()
		return false
	_assign_owners(imported, imported)
	var packed := PackedScene.new()
	var pack_error := packed.pack(imported)
	imported.free()
	if pack_error != OK:
		return false
	cached_scene = packed
	return true

func install() -> bool:
	if not _cache_asset():
		return false
	var instance := cached_scene.instantiate() as Node3D
	if instance == null:
		return false
	animation_player = _find_player(instance)
	var skeleton := _find_skeleton(instance)
	if animation_player == null or skeleton == null or skeleton.get_bone_count() != 35:
		instance.free()
		return false
	for action in ["idle_loop", "walk_loop", "run_loop", "bite"]:
		if _clip(action).is_empty():
			instance.free()
			animation_player = null
			return false
	add_child(instance)
	# GLB olha +Z, enquanto os animais do jogo olham -Z.
	instance.rotation.y += PI
	# Altura visual aproximada de 1 m; preserva o collider original do lobo.
	instance.scale *= 0.70
	attack_clip = _clip("bite")
	_play("idle_loop", true)
	return true

func _clip(action: String) -> String:
	if not is_instance_valid(animation_player):
		return ""
	for clip in animation_player.get_animation_list():
		if clip.get_file().to_lower() == action:
			return clip
	return ""

func _play(action: String, loop: bool, speed: float = 1.0) -> void:
	var clip := _clip(action)
	if clip.is_empty():
		return
	var anim := animation_player.get_animation(clip)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	if current_clip != clip or not animation_player.is_playing():
		animation_player.play(clip, 0.12, speed)
		current_clip = clip
	else:
		animation_player.speed_scale = speed

func bite() -> void:
	if not is_instance_valid(animation_player):
		return
	animation_player.speed_scale = 1.0
	animation_player.stop()
	current_clip = ""
	_play("bite", false)

func animate(velocity: Vector3) -> void:
	if not is_instance_valid(animation_player):
		return
	if current_clip == attack_clip and animation_player.is_playing():
		return
	var speed := Vector2(velocity.x, velocity.z).length()
	if speed < 0.15:
		_play("idle_loop", true)
	elif speed < 1.7:
		_play("walk_loop", true, clampf(speed / 1.15, 0.65, 1.35))
	else:
		_play("run_loop", true, clampf(speed / 2.25, 0.75, 1.35))
