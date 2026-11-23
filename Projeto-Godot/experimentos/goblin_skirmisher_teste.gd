extends Node3D
## Comparacao isolada entre o modelo atual e o pacote gratuito Goblin Skirmisher.
## Nao modifica personagem, NPCs, inventarios ou saves das partidas.

const CURRENT_RIG = preload("res://npc_goblin.gd")
const ASSET_DIR := "res://modelos/goblin_skirmisher"
const MOTION_LABELS := {"idle": "Parado", "walk": "Andar", "run": "Correr", "attack": "Atacar", "hit": "Receber dano", "death": "Morrer"}
const MOTION_WORDS := {
	"idle": ["idle", "stand", "breath"],
	"walk": ["walk", "scurry", "move"],
	"run": ["run", "sprint", "jog"],
	"attack": ["attack", "slash", "stab", "strike", "sword"],
	"hit": ["hit", "hurt", "impact", "damage", "react"],
	"death": ["death", "die", "dying"]
}

var _current_rig: Node3D
var _skirmisher: Node3D
var _animation_player: AnimationPlayer
var _animation_names: PackedStringArray = PackedStringArray()
var _animation_index := 0
var _motion := "idle"
var _angle := 0.0
var _zoom := 1.0
var _camera: Camera3D
var _info: Label
var _asset_status := ""

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_world()
	_spawn_current()
	_load_skirmisher()
	_build_menu()
	_update_info()

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#99ada3")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#e4e4dc")
	environment.ambient_light_energy = 0.75
	world.environment = environment
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -30, 0)
	light.light_energy = 1.4
	add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(14, 14)
	ground.mesh = plane
	var surface := StandardMaterial3D.new()
	surface.albedo_color = Color("#566b59")
	surface.roughness = 1.0
	ground.material_override = surface
	add_child(ground)
	_camera = Camera3D.new()
	_camera.position = Vector3(0.0, 2.2, 6.3)
	add_child(_camera)
	_camera.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	_camera.current = true
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 3.7

func _spawn_current() -> void:
	var holder := Node3D.new()
	holder.name = "GoblinAtual"
	holder.position = Vector3(-1.35, 0, 0)
	add_child(holder)
	_current_rig = CURRENT_RIG.new()
	holder.add_child(_current_rig)
	if _current_rig.call("install"):
		_current_rig.call("set_equipment", false, false)
	_add_label(holder, "MODELO ATUAL")

func _load_skirmisher() -> void:
	var candidate := _choose_model()
	if candidate.is_empty():
		_asset_status = "Pacote ausente. Extraia o ZIP Godot em:\nProjeto-Godot/modelos/goblin_skirmisher/\nDepois importe o projeto e gere uma nova compilacao."
		return
	var packed := load(candidate) as PackedScene
	if packed == null:
		_asset_status = "Nao foi possivel importar: " + candidate
		return
	var holder := Node3D.new()
	holder.name = "GoblinSkirmisher"
	holder.position = Vector3(1.35, 0, 0)
	add_child(holder)
	_skirmisher = packed.instantiate() as Node3D
	if _skirmisher == null:
		holder.queue_free()
		_asset_status = "O arquivo encontrado nao e uma cena 3D: " + candidate
		return
	holder.add_child(_skirmisher)
	var players := _skirmisher.find_children("*", "AnimationPlayer", true, false)
	for node in players:
		var player := node as AnimationPlayer
		if player != null and player.get_animation_list().size() > _animation_names.size():
			_animation_player = player
			_animation_names = player.get_animation_list()
	for tree in _skirmisher.find_children("*", "AnimationTree", true, false):
		(tree as AnimationTree).active = false
	_add_label(holder, "GOBLIN SKIRMISHER")
	_asset_status = "Modelo encontrado: " + candidate.get_file()
	if _animation_player == null:
		_asset_status += "\nSem AnimationPlayer nesta cena. Procure o arquivo do modelo animado."
	else:
		_play_motion("idle")

func _choose_model() -> String:
	var files: Array[String] = []
	_collect_models(ASSET_DIR, files, 0)
	var best_path := ""
	var best_score := -100000
	for path in files:
		var packed := load(path) as PackedScene
		if packed == null:
			continue
		var instance := packed.instantiate()
		if not (instance is Node3D):
			instance.free()
			continue
		var skeletons := instance.find_children("*", "Skeleton3D", true, false)
		var animations := instance.find_children("*", "AnimationPlayer", true, false)
		var file_name := path.get_file().to_lower()
		var score := 0
		if not skeletons.is_empty(): score += 100
		if file_name.contains("goblin"): score += 50
		if file_name.contains("skirmisher"): score += 50
		if file_name.contains("character") or file_name.contains("model"): score += 25
		if file_name.contains("preview") or file_name.contains("demo"): score -= 60
		for anim in animations:
			score += mini((anim as AnimationPlayer).get_animation_list().size(), 30)
		if path.get_extension().to_lower() == "glb": score += 10
		instance.free()
		if score > best_score:
			best_score = score
			best_path = path
	return best_path

func _collect_models(folder: String, files: Array[String], depth: int) -> void:
	if depth > 6:
		return
	var directory := DirAccess.open(folder)
	if directory == null:
		return
	directory.list_dir_begin()
	while true:
		var entry := directory.get_next()
		if entry.is_empty():
			break
		if entry.begins_with("."):
			continue
		var path := folder.path_join(entry)
		if directory.current_is_dir():
			_collect_models(path, files, depth + 1)
		elif entry.get_extension().to_lower() in ["glb", "gltf"]:
			files.append(path)
	directory.list_dir_end()

func _add_label(holder: Node3D, label_text: String) -> void:
	var label := Label3D.new()
	label.text = label_text
	label.position = Vector3(0, 2.42, 0)
	label.font_size = 35
	label.pixel_size = 0.0025
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	holder.add_child(label)

func _build_menu() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 20)
	panel.custom_minimum_size = Vector2(296, 0)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var header := Label.new()
	header.text = "TESTE: GOBLIN SKIRMISHER"
	header.add_theme_font_size_override("font_size", 16)
	column.add_child(header)
	var desc := Label.new()
	desc.text = "Esquerda: goblin atual\nDireita: modelo baixado (se instalado)"
	column.add_child(desc)
	for motion in ["idle", "walk", "run", "attack", "hit", "death"]:
		var title: String = MOTION_LABELS[motion]
		_add_button(column, title, _play_motion.bind(motion))
	_add_button(column, "Proxima animacao", _advance_animation.bind(1))
	_add_button(column, "Animacao anterior", _advance_animation.bind(-1))
	_add_button(column, "Girar 90 graus", _turn)
	_add_button(column, "Zoom +", _zoom_in)
	_add_button(column, "Zoom -", _zoom_out)
	_add_button(column, "Voltar ao laboratorio", _back)
	_info = Label.new()
	_info.custom_minimum_size = Vector2(294, 0)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_info)

func _add_button(parent: VBoxContainer, title: String, action: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.pressed.connect(action)
	parent.add_child(button)

func _play_motion(motion: String) -> void:
	_motion = motion
	if _animation_player != null:
		var chosen := ""
		for name in _animation_names:
			var lowered := name.to_lower()
			for keyword in MOTION_WORDS.get(motion, []):
				if lowered.contains(keyword):
					chosen = name
					break
			if not chosen.is_empty():
				break
		if chosen.is_empty():
			_asset_status = "Nao achei animacao de '" + motion + "' no pacote."
		else:
			_asset_status = "Animacao ativa: " + chosen
			_animation_index = _animation_names.find(chosen)
			_animation_player.play(chosen)
	_update_info()

func _advance_animation(direction: int) -> void:
	if _animation_player == null or _animation_names.is_empty():
		return
	_animation_index = posmod(_animation_index + direction, _animation_names.size())
	var name := _animation_names[_animation_index]
	_animation_player.play(name)
	_motion = "custom"
	_asset_status = "Animacao %d/%d: %s" % [_animation_index + 1, _animation_names.size(), name]
	_update_info()

func _turn() -> void:
	_angle = fposmod(_angle + PI * 0.5, TAU)
	if _current_rig != null and is_instance_valid(_current_rig):
		(_current_rig.get_parent() as Node3D).rotation.y = _angle
	if _skirmisher != null and is_instance_valid(_skirmisher):
		(_skirmisher.get_parent() as Node3D).rotation.y = _angle

func _zoom_in() -> void:
	_zoom = clampf(_zoom * 0.8, 0.6, 2.0)
	_camera.size = 3.7 * _zoom

func _zoom_out() -> void:
	_zoom = clampf(_zoom * 1.25, 0.6, 2.0)
	_camera.size = 3.7 * _zoom

func _update_info() -> void:
	if _info != null:
		_info.text = _asset_status

func _process(delta: float) -> void:
	if _current_rig == null or not is_instance_valid(_current_rig):
		return
	var speed := 0.0
	if _motion == "walk": speed = 1.6
	if _motion == "run": speed = 3.2
	_current_rig.call("animate", Vector3(0, 0, speed), delta, true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_back()

func _back() -> void:
	get_tree().change_scene_to_file("res://experimentos/goblin_skin_teste.tscn")
