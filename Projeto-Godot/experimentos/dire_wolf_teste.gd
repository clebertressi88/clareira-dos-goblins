extends Node3D
## Laboratorio isolado. Importa GLB local sem distribuir o pacote original.
var model: Node3D
var holder: Node3D
var camera: Camera3D
var player: AnimationPlayer
var info: Label
var picker: FileDialog
var controls: VBoxContainer
var motion_buttons: Dictionary = {}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#9bb3af")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.8
	world.environment = env
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.4
	add_child(light)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#566b59")
	floor.material_override = mat
	add_child(floor)
	holder = Node3D.new()
	add_child(holder)
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(4, 2.3, 5)
	camera.look_at(Vector3(0, 0.8, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.5
	camera.h_offset = 0.85
	camera.current = true
	_build_controls()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--wolf-asset="):
			_load_model(arg.trim_prefix("--wolf-asset="))
			if "--wolf-test" in OS.get_cmdline_user_args():
				_validate_asset()
			return
	var last_path := ConfigFile.new()
	if last_path.load("user://dire_wolf_lab.cfg") == OK:
		var path: String = str(last_path.get_value("asset", "path", ""))
		if FileAccess.file_exists(path):
			_load_model(path)
			if is_instance_valid(model):
				return
	# O ZIP licenciado permanece no computador do jogador.
	var dirs := PackedStringArray([OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS), OS.get_executable_path().get_base_dir(), "user://"])
	for folder in dirs:
		if folder.is_empty():
			continue
		for filename in ["Dire_Wolf_Lite_v1.0.0.zip", "Dire_Wolf_Lite.glb"]:
			var local_path := folder.path_join(filename)
			if FileAccess.file_exists(local_path):
				_load_model(local_path)
				if is_instance_valid(model):
					return

func _build_controls() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var theme_ui := Theme.new()
	theme_ui.default_font_size = 16
	theme_ui.set_color("font_color", "Label", Color("#e6dfd1"))
	theme_ui.set_color("font_color", "Button", Color("#ede1ca"))
	theme_ui.set_color("font_hover_color", "Button", Color("#ffffff"))
	theme_ui.set_color("font_disabled_color", "Button", Color("#85817a"))
	theme_ui.set_stylebox("normal", "Button", _style(Color("#302b24"), Color("#62503b"), 6))
	theme_ui.set_stylebox("hover", "Button", _style(Color("#493b2a"), Color("#d0a36a"), 6))
	theme_ui.set_stylebox("pressed", "Button", _style(Color("#5e442a"), Color("#e4bd80"), 6))
	theme_ui.set_stylebox("disabled", "Button", _style(Color("#24231f"), Color("#3b3933"), 6))
	var panel := PanelContainer.new()
	layer.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -342
	panel.offset_right = -16
	panel.offset_top = 16
	panel.offset_bottom = -16
	panel.theme = theme_ui
	panel.add_theme_stylebox_override("panel", _style(Color(0.09, 0.11, 0.10, 0.96), Color("#91734d"), 12))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	controls = VBoxContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override("separation", 8)
	scroll.add_child(controls)
	_section("CLAREIRA DOS GOBLINS", 12, Color("#c7a36c"))
	_section("Dire Wolf", 28, Color("#f4ead6"))
	_section("Laboratorio de criaturas  /  Modelo experimental", 13, Color("#a9b0a4"))
	_button("Carregar ZIP ou GLB", func(): picker.popup_centered_ratio(0.8))
	controls.add_child(HSeparator.new())
	_section("ANIMACOES", 13, Color("#c7a36c"))
	var motion_grid := GridContainer.new()
	motion_grid.columns = 2
	motion_grid.add_theme_constant_override("h_separation", 8)
	motion_grid.add_theme_constant_override("v_separation", 8)
	controls.add_child(motion_grid)
	for pair in [["Parado", "idle"], ["Caminhar", "walk"], ["Correr", "run"], ["Morder", "bite"]]:
		var state: String = str(pair[1])
		var btn := _button(str(pair[0]), _play.bind(state), motion_grid)
		btn.disabled = true
		motion_buttons[state] = btn
	controls.add_child(HSeparator.new())
	_section("CAMERA E INSPECAO", 13, Color("#c7a36c"))
	var camera_grid := GridContainer.new()
	camera_grid.columns = 2
	camera_grid.add_theme_constant_override("h_separation", 8)
	camera_grid.add_theme_constant_override("v_separation", 8)
	controls.add_child(camera_grid)
	_button("Girar 90 graus", func(): holder.rotate_y(PI * 0.5), camera_grid)
	_button("Centralizar", _reset_view, camera_grid)
	_button("Zoom +", func(): camera.size = maxf(0.5, camera.size * 0.8), camera_grid)
	_button("Zoom -", func(): camera.size = minf(30.0, camera.size * 1.25), camera_grid)
	controls.add_child(HSeparator.new())
	_section("DADOS DO MODELO", 13, Color("#c7a36c"))
	info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.text = "Selecione o ZIP oficial na pasta Downloads."
	controls.add_child(info)
	_section("Dire Wolf por Literock Studios", 12, Color("#a9b0a4"))
	_button("Voltar ao laboratorio  [ESC]", _back)
	picker = FileDialog.new()
	picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	picker.access = FileDialog.ACCESS_FILESYSTEM
	picker.add_filter("*.glb", "Modelo GLB")
	picker.add_filter("*.zip", "Pacote oficial Dire Wolf")
	picker.file_selected.connect(_load_model)
	layer.add_child(picker)
	var downloads := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if not downloads.is_empty():
		picker.current_dir = downloads

func _style(bg: Color, border: Color, corner: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(corner)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _section(title: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_child(label)

func _button(title: String, action: Callable, parent: Control = null) -> Button:
	var btn := Button.new()
	btn.text = title
	btn.custom_minimum_size.y = 36
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if parent == null:
		controls.add_child(btn)
	else:
		parent.add_child(btn)
	btn.pressed.connect(action)
	return btn

func _reset_view() -> void:
	holder.rotation = Vector3.ZERO
	camera.size = 4.5

func _load_model(path: String) -> void:
	var extension := path.get_extension().to_lower()
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var import_error: Error = ERR_INVALID_PARAMETER
	if extension == "zip":
		var zip := ZIPReader.new()
		if zip.open(path) != OK:
			info.text = "Nao foi possivel abrir o ZIP."
			return
		var asset_name := "Dire_Wolf_Lite/Dire_Wolf_Lite.glb"
		if not zip.file_exists(asset_name):
			zip.close()
			info.text = "O ZIP nao contem o GLB oficial esperado."
			return
		var data := zip.read_file(asset_name)
		zip.close()
		import_error = doc.append_from_buffer(data, "", state)
	elif extension == "glb":
		import_error = doc.append_from_file(path, state)
	else:
		info.text = "Selecione ZIP ou GLB."
		return
	if import_error != OK:
		info.text = "Falha ao ler GLB: " + str(import_error)
		return
	var candidate := doc.generate_scene(state)
	if not (candidate is Node3D):
		if candidate != null:
			candidate.free()
		info.text = "GLB sem raiz 3D valida."
		return
	if is_instance_valid(model):
		holder.remove_child(model)
		model.queue_free()
	model = candidate as Node3D
	holder.add_child(model)
	holder.rotation = Vector3.ZERO
	player = _find_player(model)
	var skeleton := _find_skeleton(model)
	var bone_count: int = skeleton.get_bone_count() if skeleton != null else 0
	var names: PackedStringArray = player.get_animation_list() if player != null else PackedStringArray()
	for key in motion_buttons:
		var btn: Button = motion_buttons[key]
		btn.disabled = _find_animation(str(key)).is_empty()
	info.text = "%s\nOssos: %d | Animacoes: %d\n%s" % [path.get_file(), bone_count, names.size(), ", ".join(names)]
	var cfg := ConfigFile.new()
	cfg.set_value("asset", "path", path)
	cfg.save("user://dire_wolf_lab.cfg")
	_play("idle")

func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _find_animation(action: String) -> String:
	if not is_instance_valid(player):
		return ""
	var expected: Dictionary = {"idle": "idle_loop", "walk": "walk_loop", "run": "run_loop", "bite": "bite"}
	for clip in player.get_animation_list():
		if clip.get_file().to_lower() == str(expected.get(action, action)):
			return clip
	for clip in player.get_animation_list():
		if clip.to_lower().contains(action):
			return clip
	return ""

func _play(action: String) -> void:
	var clip := _find_animation(action)
	if clip.is_empty():
		return
	var animation := player.get_animation(clip)
	if animation != null:
		animation.loop_mode = Animation.LOOP_NONE if action == "bite" else Animation.LOOP_LINEAR
	player.stop()
	player.play(clip)

func _back() -> void:
	get_tree().change_scene_to_file("res://experimentos/goblin_skin_teste.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_back()

func _validate_asset() -> void:
	var skeleton: Skeleton3D = _find_skeleton(model) if is_instance_valid(model) else null
	if skeleton == null or skeleton.get_bone_count() != 35 or not is_instance_valid(player):
		push_error("Dire Wolf: rig ou AnimationPlayer invalido.")
		get_tree().quit(1)
		return
	for action in ["idle", "walk", "run", "bite"]:
		var clip := _find_animation(action)
		if clip.is_empty():
			push_error("Dire Wolf: animacao ausente: " + action)
			get_tree().quit(1)
			return
		_play(action)
		player.advance(0.1)
	print("DIRE_WOLF_LAB_OK: 35 ossos e 4 animacoes")
	get_tree().quit(0)
