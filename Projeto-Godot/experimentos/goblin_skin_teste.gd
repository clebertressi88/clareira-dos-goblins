extends Node3D
## Laboratorio de criaturas: somente modelos atuais, sem alterar o mundo salvo.
const GOBLIN_RIG = preload("res://npc_goblin_skirmisher.gd")
const WOLF_RIG = preload("res://dire_wolf_model.gd")
const BACKPACK = preload("res://backpack_model.gd")

var characters: Array[Node3D] = [] # Compatibilidade com ferramentas antigas.
var goblin: Node3D
var wolf: Node3D
var second_goblin: Node3D
var second_goblin_holder: Node3D
var goblin_holder: Node3D
var wolf_holder: Node3D
var camera: Camera3D
var status_label: Label
var wolf_picker: FileDialog
var group_mode := "goblin"
var motion := "idle"
var interaction := "none"
var elapsed := 0.0
var zoom := 4.0
var orbit := 0.0
var sword_on := false
var shield_on := false
var bag_on := false
var bag: Node3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_world()
	_spawn_goblin()
	_spawn_second_goblin()
	_spawn_wolf()
	_build_ui()
	_set_view("goblin")

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#889e91")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#eeebdb")
	env.ambient_light_energy = 0.8
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-43,-31,0)
	sun.light_energy = 1.55
	add_child(sun)
	var floor := MeshInstance3D.new()
	floor.name = "PisoDoLaboratorio"
	var plane := PlaneMesh.new()
	plane.size = Vector2(16,16)
	floor.mesh = plane
	var ground := StandardMaterial3D.new()
	ground.albedo_color = Color("#637560")
	ground.roughness = 1.0
	floor.material_override = ground
	add_child(floor)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	add_child(camera)

func _spawn_goblin() -> void:
	goblin_holder = Node3D.new()
	goblin_holder.name = "GoblinAtual"
	add_child(goblin_holder)
	goblin = GOBLIN_RIG.new()
	goblin.name = "GoblinRig"
	goblin_holder.add_child(goblin)
	goblin.call("set_variant","player")
	if not bool(goblin.call("install")):
		push_warning("Laboratorio: modelo atual do goblin nao carregou.")
		return
	goblin.call("set_equipment",false,false)
	characters.append(goblin)

func _spawn_second_goblin() -> void:
	second_goblin_holder = Node3D.new()
	second_goblin_holder.name = "SegundoGoblin"
	add_child(second_goblin_holder)
	second_goblin = GOBLIN_RIG.new()
	second_goblin.name = "GoblinRig"
	second_goblin_holder.add_child(second_goblin)
	second_goblin.call("set_variant","talo")
	if not bool(second_goblin.call("install")):
		push_warning("Laboratorio: segundo goblin nao carregou.")
		return
	second_goblin.call("set_equipment",false,false)
	characters.append(second_goblin)

func _spawn_wolf() -> void:
	wolf_holder = Node3D.new()
	wolf_holder.name = "LoboAtual"
	add_child(wolf_holder)
	wolf = WOLF_RIG.new()
	wolf.name = "DireWolf"
	wolf_holder.add_child(wolf)
	if not bool(wolf.call("install")):
		# O modelo licenciado e carregado do arquivo local, se disponivel.
		wolf_holder.remove_child(wolf)
		wolf.queue_free()
		wolf = null

func _refresh_wolf() -> void:
	if is_instance_valid(wolf):
		wolf_holder.remove_child(wolf)
		wolf.queue_free()
	wolf = WOLF_RIG.new()
	wolf.name = "DireWolf"
	wolf_holder.add_child(wolf)
	if not bool(wolf.call("install")):
		wolf_holder.remove_child(wolf)
		wolf.queue_free()
		wolf = null
	_set_view(group_mode)

func _choose_wolf_file(file: String) -> void:
	var config := ConfigFile.new()
	config.set_value("asset","path",file)
	config.save("user://dire_wolf_lab.cfg")
	_refresh_wolf()

func _skin(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(7)
	s.content_margin_left = 9
	s.content_margin_right = 9
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _button(parent: Node, title: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = title
	b.custom_minimum_size.y = 34.0
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _heading(parent: Node, value: String) -> void:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size",13)
	l.add_theme_color_override("font_color",Color("#c9a46c"))
	parent.add_child(l)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_left = 14
	panel.offset_right = 326
	panel.offset_top = 18
	panel.offset_bottom = -18
	panel.add_theme_stylebox_override("panel",_skin(Color("#242820f2"),Color("#a48758")))
	layer.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",6)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	var title := Label.new()
	title.text = "LABORATORIO DE CRIATURAS"
	title.add_theme_font_size_override("font_size",19)
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Modelos usados no jogo · testes isolados"
	subtitle.add_theme_font_size_override("font_size",12)
	content.add_child(subtitle)
	content.add_child(HSeparator.new())
	_heading(content,"VISUALIZAR")
	var selector := GridContainer.new()
	selector.columns = 2
	content.add_child(selector)
	_button(selector,"Goblin",_set_view.bind("goblin"))
	_button(selector,"Lobo",_set_view.bind("wolf"))
	_button(selector,"Goblin + lobo",_set_view.bind("group"))
	_button(selector,"Dupla de goblins",_set_view.bind("goblins"))
	content.add_child(HSeparator.new())
	_heading(content,"ANIMACOES")
	var motions := GridContainer.new()
	motions.columns = 2
	content.add_child(motions)
	_button(motions,"Parado",_set_motion.bind("idle"))
	_button(motions,"Caminhar",_set_motion.bind("walk"))
	_button(motions,"Correr",_set_motion.bind("run"))
	_button(motions,"Ataque",_attack)
	content.add_child(HSeparator.new())
	_heading(content,"INTERACOES NO GRUPO")
	_button(content,"Lobo se aproxima",_set_interaction.bind("approach"))
	_button(content,"Goblin enfrenta o lobo",_set_interaction.bind("confront"))
	_button(content,"Lobo recua",_set_interaction.bind("retreat"))
	_button(content,"Reiniciar posicoes",_reset_positions)
	content.add_child(HSeparator.new())
	_heading(content,"EQUIPAMENTOS")
	_button(content,"Espada: equipar / retirar",_sword)
	_button(content,"Escudo: equipar / retirar",_shield)
	_button(content,"Mochila: equipar / retirar",_backpack)
	content.add_child(HSeparator.new())
	_heading(content,"CAMERA")
	var views := GridContainer.new()
	views.columns = 2
	content.add_child(views)
	_button(views,"Girar 90 graus",_rotate)
	_button(views,"Centralizar",_reset_camera)
	_button(views,"Zoom +",_zoom.bind(0.8))
	_button(views,"Zoom -",_zoom.bind(1.25))
	content.add_child(HSeparator.new())
	_button(content,"Carregar modelo do lobo",_pick_wolf)
	_button(content,"Voltar ao jogo (ESC)",_back)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size",12)
	content.add_child(status_label)
	wolf_picker = FileDialog.new()
	wolf_picker.access = FileDialog.ACCESS_FILESYSTEM
	wolf_picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	wolf_picker.add_filter("*.zip","Dire Wolf ZIP")
	wolf_picker.add_filter("*.glb","Dire Wolf GLB")
	wolf_picker.file_selected.connect(_choose_wolf_file)
	layer.add_child(wolf_picker)
	var downloads := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if not downloads.is_empty():
		wolf_picker.current_dir = downloads

func _set_view(value: String) -> void:
	group_mode = value
	if not is_instance_valid(goblin_holder) or not is_instance_valid(wolf_holder) or not is_instance_valid(second_goblin_holder):
		return
	goblin_holder.visible = value in ["goblin","group","goblins"]
	wolf_holder.visible = value in ["wolf","group"]
	second_goblin_holder.visible = value=="goblins"
	_reset_positions()
	_reset_camera()
	_update_status()

func _reset_positions() -> void:
	elapsed = 0.0
	interaction = "none"
	goblin_holder.position = Vector3(-0.83,0,0) if group_mode in ["group","goblins"] else Vector3.ZERO
	second_goblin_holder.position = Vector3(0.83,0,0)
	second_goblin_holder.rotation.y = PI
	wolf_holder.position = Vector3(0.83,0,0) if group_mode=="group" else Vector3.ZERO
	goblin_holder.rotation.y = 0.0
	wolf_holder.rotation.y = PI if group_mode=="group" else 0.0
	_update_status()

func _reset_camera() -> void:
	orbit = 0.0
	zoom = 4.5 if group_mode in ["group","goblins"] else 3.2
	_update_camera()

func _update_camera() -> void:
	if not is_instance_valid(camera):
		return
	var target := Vector3(0,0.95,0)
	camera.size = zoom
	camera.position = target + Vector3(sin(orbit)*6,1.3,cos(orbit)*6)
	camera.look_at(target,Vector3.UP)

func _rotate() -> void:
	orbit = fposmod(orbit+PI/2.0,TAU)
	_update_camera()

func _zoom(factor: float) -> void:
	zoom = clampf(zoom*factor,0.9,9.0)
	_update_camera()

func _set_motion(value: String) -> void:
	motion = value
	interaction = "none"
	_update_status()

func _attack() -> void:
	if goblin_holder.visible and is_instance_valid(goblin):
		goblin.call("play_action","attack")
	if wolf_holder.visible and is_instance_valid(wolf):
		wolf.call("bite")
	if second_goblin_holder.visible and is_instance_valid(second_goblin):
		second_goblin.call("play_action","attack")
	_update_status()

func _set_interaction(value: String) -> void:
	if group_mode!="group" or not is_instance_valid(wolf):
		_update_status()
		return
	interaction = value
	elapsed = 0.0
	_update_status()

func _sword() -> void:
	sword_on = not sword_on
	_apply_equipment()

func _shield() -> void:
	shield_on = not shield_on
	_apply_equipment()

func _apply_equipment() -> void:
	if is_instance_valid(goblin):
		goblin.call("set_equipment",sword_on,shield_on)
	if is_instance_valid(second_goblin):
		second_goblin.call("set_equipment",sword_on,shield_on)
	_update_status()

func _backpack() -> void:
	if not is_instance_valid(goblin):
		return
	bag_on = not bag_on
	if bag_on and not is_instance_valid(bag):
		bag = BACKPACK.new()
		goblin_holder.add_child(bag)
		if not bool(goblin.call("attach_backpack",bag)):
			bag.position = Vector3(0,1.0,-0.28)
	if is_instance_valid(bag):
		bag.visible = bag_on
	_update_status()

func _update_status() -> void:
	if not is_instance_valid(status_label):
		return
	var model_state := "Lobo carregado" if is_instance_valid(wolf) else "Lobo nao encontrado: carregar ZIP/GLB local"
	status_label.text = "Visualizacao: %s\nMovimento: %s\n%s\nMundos salvos preservados." % [group_mode,motion,model_state]

func _process(dt: float) -> void:
	if is_instance_valid(goblin):
		var walking_speed := 0.0 if motion=="idle" else 3.2 if motion=="run" else 1.6
		goblin.call("animate",Vector3(0,0,walking_speed),dt,true)
	if is_instance_valid(second_goblin):
		var second_speed := 0.0 if motion=="idle" else 3.2 if motion=="run" else 1.6
		second_goblin.call("animate",Vector3(0,0,second_speed),dt,true)
	if is_instance_valid(wolf):
		var wolf_speed := 0.0 if motion=="idle" else 3.6 if motion=="run" else 1.4
		wolf.call("animate",Vector3(0,0,wolf_speed))
	if interaction=="none" or group_mode!="group" or not is_instance_valid(wolf):
		return
	elapsed += dt
	if interaction=="approach":
		wolf_holder.position.x = move_toward(wolf_holder.position.x,-0.1,dt*0.36)
		wolf.call("animate",Vector3(0,0,1.6))
	elif interaction=="confront":
		wolf_holder.position.x = move_toward(wolf_holder.position.x,0.05,dt*0.3)
		wolf.call("animate",Vector3(0,0,2.2))
		if elapsed>1.0 and elapsed<1.0+dt:
			goblin.call("play_action","attack")
			wolf.call("bite")
	elif interaction=="retreat":
		wolf_holder.position.x = move_toward(wolf_holder.position.x,1.8,dt*0.85)
		wolf.call("animate",Vector3(0,0,3.0))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		_back()

func _back() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
