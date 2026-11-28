extends Control
## Menu medieval ilustrado: todas as placas sao controles Godot interativos.
## O cenario SVG so aparece nesta tela e nao interfere no mundo 3D.

const SIZE := Vector2(1600,900)
const GOLD := Color("#ffd889")
const CREAM := Color("#fff0d6")
const MUTED := Color("#cdbb94")
const BORDER := Color("#c5964c")
const WOOD := Color("#3e2c1e")
const BACKDROP := preload("res://menu_art/cenario_medieval.svg")
const FLAG := preload("res://menu_art/bandeira.svg")
const LOGO := preload("res://menu_art/logo_base.svg")
const PANEL := preload("res://menu_art/painel_central.svg")
const FOOTER := preload("res://menu_art/barra_atalhos.svg")
const NAV_NORMAL := preload("res://menu_art/botao_madeira.svg")
const NAV_HOVER := preload("res://menu_art/botao_madeira_hover.svg")
const PRIMARY := preload("res://menu_art/botao_principal.svg")
const OPTIONS_FILE := "user://clareira-menu.cfg"

var ip_input: LineEdit
var _lan_rooms: VBoxContainer
var _lan_signature := ""
var world_picker: OptionButton
var world_create_input: LineEdit
var world_rename_input: LineEdit
var _state: Dictionary = {}
var _actions: Dictionary = {}
var _page := "home"
var _font: Font
var _stage: Control
var _middle: Control
var _navigation: VBoxContainer
var _page_container: VBoxContainer
var _panel_art: TextureRect
var _primary_button: Button
var _footer_shortcuts: HBoxContainer
var _footer_key_labels: Dictionary = {}
var _controls_model: RefCounted
var _key_capture_action := ""
var _key_buttons: Dictionary = {}
var _key_capture_feedback: Label
var _view_distance_value: Label
var _nav_buttons: Dictionary = {}
var _update_marker: Label
var _volume_label: Label
var _update_status_label: Label
var _update_progress: ProgressBar
var _update_install_button: Button
var _update_check_button: Button

func _ready() -> void:
	_font = SystemFont.new()
	(_font as SystemFont).font_names = PackedStringArray(["Georgia","Palatino Linotype","Times New Roman"])
	resized.connect(_fit)
	_apply_saved_audio()

func rebuild(state: Dictionary, actions: Dictionary, starting_page: String = "home") -> void:
	_state = state
	_actions = actions
	_controls_model = _state.get("controls_model") as RefCounted
	_page = starting_page
	_recreate()

func _recreate() -> void:
	ip_input = null
	_lan_rooms = null
	_lan_signature = ""
	world_picker = null
	world_create_input = null
	world_rename_input = null
	_volume_label = null
	_update_status_label = null
	_update_progress = null
	_update_install_button = null
	_update_check_button = null
	_nav_buttons.clear()
	_footer_key_labels.clear()
	_key_buttons.clear()
	_key_capture_action = ""
	_key_capture_feedback = null
	_view_distance_value = null
	_update_marker = null
	for child in get_children():
		remove_child(child)
		child.queue_free()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_art(self,BACKDROP,Vector2.ZERO,SIZE,true)
	var tint := ColorRect.new()
	tint.color = Color("#241d113d")
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)
	_stage = Control.new()
	_stage.size = SIZE
	add_child(_stage)
	_art(_stage,FLAG,Vector2(29,14),Vector2(338,829))
	_art(_stage,LOGO,Vector2(538,24),Vector2(524,150))
	var title_a := _text("Clareira dos",41,CREAM)
	_place(_stage,title_a,Vector2(573,46),Vector2(460,55))
	title_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_b := _text("GOBLINS",72,GOLD)
	_place(_stage,title_b,Vector2(573,83),Vector2(460,81))
	title_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var status := _text(_installed_build_label(),22,GOLD)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.tooltip_text = "Identificador da compilação instalada neste dispositivo"
	_place(_stage,status,Vector2(1180,25),Vector2(385,40))
	_navigation = VBoxContainer.new()
	_navigation.add_theme_constant_override("separation",5)
	_place(_stage,_navigation,Vector2(58,173),Vector2(307,645))
	_nav_button("▶  Jogar","play",true)
	_nav_button("♜  Multijogador (LAN)","network")
	_nav_button("✚  Novo Mundo","new_world")
	_nav_button("▣  Carregar Mundo","worlds")
	_nav_button("⚙  Configurações","settings")
	if str(_state.get("role","solo"))=="solo":
		_nav_button("⚗  Laboratório (Beta)","lab")
	_nav_button("⇩  Atualizações","updates")
	_nav_button("ⓘ  Créditos","credits")
	_nav_button("⏻  Salvar e sair","quit")
	_middle = Control.new()
	_place(_stage,_middle,Vector2(464,235),Vector2(705,530))
	_art(_stage,FOOTER,Vector2(370,825),Vector2(860,64))
	_build_footer_shortcuts()
	_render_page()
	_refresh_update_indicator()
	_fit()

func _installed_build_label() -> String:
	var version_path := OS.get_executable_path().get_base_dir().path_join("versao-github.txt")
	if FileAccess.file_exists(version_path):
		var revision := FileAccess.get_file_as_string(version_path).strip_edges()
		if not revision.is_empty():
			return "BETA | Windows " + revision.left(8)
	return "BETA | " + ("Dev local" if OS.has_feature("editor") else "Versão não identificada")

func _place(parent: Control,node: Control,pos: Vector2,area: Vector2) -> void:
	parent.add_child(node)
	node.position = pos
	node.size = area

func _art(parent: Control,texture: Texture2D,pos: Vector2,area: Vector2,cover: bool = false) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_SCALE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if cover:
		parent.add_child(image)
		image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		_place(parent,image,pos,area)
	return image

func _fit() -> void:
	if not is_instance_valid(_stage):
		return
	var fit_scale := minf(size.x / SIZE.x,size.y / SIZE.y)
	_stage.scale = Vector2.ONE * fit_scale
	_stage.position = (size-SIZE*fit_scale)*0.5

func _build_footer_shortcuts() -> void:
	# Cada atalho ocupa uma coluna fixa. Isso elimina texto sobreposto
	# e desalinhamento causado por uma unica Label comprida.
	_footer_shortcuts = HBoxContainer.new()
	_footer_shortcuts.add_theme_constant_override("separation",0)
	_place(_stage,_footer_shortcuts,Vector2(390,833),Vector2(820,47))
	var hints := [
		["move","Mover",145],
		["mouse","Atacar / usar",212],
		["goblin_inventario","Inventário",153],
		["goblin_correr","Correr",145],
		["goblin_pular","Pular",165]
	]
	for hint in hints:
		var cell := CenterContainer.new()
		cell.custom_minimum_size = Vector2(float(hint[2]),45)
		_footer_shortcuts.add_child(cell)
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation",6)
		cell.add_child(pair)
		var keycap := PanelContainer.new()
		keycap.add_theme_stylebox_override("panel",_flat(Color("#24190de8"),Color("#ac8248"),1,4))
		pair.add_child(keycap)
		var hotkey_name := str(hint[0])
		var key_label := _text(_footer_key_name(hotkey_name),14,GOLD)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		keycap.add_child(key_label)
		_footer_key_labels[hotkey_name] = key_label
		var action_label := _text(str(hint[1]),15,CREAM)
		pair.add_child(action_label)

func _footer_key_name(action: String) -> String:
	if action=="mouse":
		return "MOUSE"
	if _controls_model==null:
		return "WASD" if action=="move" else ""
	if action=="move":
		var symbols := ""
		for direction in ["goblin_frente","goblin_esquerda","goblin_tras","goblin_direita"]:
			symbols += OS.get_keycode_string(int(_controls_model.call("key_for",direction)))
		return symbols
	return OS.get_keycode_string(int(_controls_model.call("key_for",action)))

func _refresh_footer_hotkeys() -> void:
	for action in _footer_key_labels:
		var label: Label = _footer_key_labels[action]
		if is_instance_valid(label):
			label.text = _footer_key_name(str(action))

func _input(event: InputEvent) -> void:
	if _key_capture_action.is_empty():
		return
	var keyboard := event as InputEventKey
	if keyboard==null or not keyboard.pressed or keyboard.echo:
		return
	get_viewport().set_input_as_handled()
	if keyboard.keycode==KEY_ESCAPE or keyboard.physical_keycode==KEY_ESCAPE:
		_key_capture_action = ""
		_set_key_feedback("Alteração cancelada.",MUTED)
		_refresh_key_buttons()
		return
	if keyboard.alt_pressed or keyboard.ctrl_pressed or keyboard.meta_pressed:
		_set_key_feedback("Pressione apenas uma tecla, sem Ctrl ou Alt.",GOLD)
		return
	var key_code: int = keyboard.physical_keycode if keyboard.physical_keycode!=KEY_NONE else keyboard.keycode
	if not _actions.has("rebind_key"):
		_set_key_feedback("Editor de controles indisponível.",GOLD)
		return
	var action_name: String = _key_capture_action
	var callback: Callable = _actions["rebind_key"]
	var result: String = str(callback.call(action_name,key_code))
	if not result.is_empty():
		_set_key_feedback(result,Color("#ffb999"))
		return
	_key_capture_action = ""
	_set_key_feedback("Tecla alterada e salva.",Color("#a9d992"))
	_refresh_key_buttons()
	_refresh_footer_hotkeys()

func _set_key_feedback(message: String,tint: Color) -> void:
	if is_instance_valid(_key_capture_feedback):
		_key_capture_feedback.text = message
		_key_capture_feedback.add_theme_color_override("font_color",tint)

func _refresh_key_buttons() -> void:
	for action in _key_buttons:
		var button: Button = _key_buttons[action]
		if not is_instance_valid(button):
			continue
		if str(action)==_key_capture_action:
			button.text = "PRESSIONE..."
		elif _controls_model!=null:
			button.text = str(_controls_model.call("text_for",str(action)))

func _begin_capture(action: String) -> void:
	_key_capture_action = action
	_refresh_key_buttons()
	_set_key_feedback("Pressione a nova tecla para "+str(_controls_model.call("label_for",action))+". Esc cancela.",GOLD)

func _restore_keys() -> void:
	_key_capture_action = ""
	_call_action("reset_keys")
	_refresh_key_buttons()
	_refresh_footer_hotkeys()
	_set_key_feedback("Todas as teclas voltaram ao padrão.",Color("#a9d992"))

func _distance_description(radius: int) -> String:
	var names := ["Curto","Padrão","Longo","Muito longo"]
	var side: int = radius*2+1
	return "%s · %d×%d chunks" % [names[clampi(radius-1,0,3)],side,side]

func _on_distance_changed(value: float) -> void:
	var radius: int = clampi(roundi(value),1,4)
	_state["view_radius"] = radius
	if is_instance_valid(_view_distance_value):
		_view_distance_value.text = _distance_description(radius)
	if _actions.has("change_view_radius"):
		var callback: Callable = _actions["change_view_radius"]
		callback.call(radius)

func _nav_button(text_value: String,page: String,featured: bool = false) -> void:
	var button := Button.new()
	button.text = text_value
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(304,59)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_button(button,featured)
	_navigation.add_child(button)
	_nav_buttons[page] = button
	if page=="updates":
		# Pequeno sinal no proprio botao, sem pop-up nem troca de tela.
		_update_marker = _text("●",23,Color("#91ed81"))
		_update_marker.position = Vector2(263,9)
		_update_marker.size = Vector2(31,39)
		_update_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_update_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_update_marker.visible = false
		button.add_child(_update_marker)
	button.pressed.connect(func(): _activate(page))

func _activate(destination: String) -> void:
	match destination:
		"play":
			if str(_state.get("role","solo"))!="solo":
				_call_action("play")
			else:
				_page = "worlds"
				_render_page()
		"home","new_world","worlds","network","settings","controls","updates","credits":
			_page = destination
			_render_page()
		_:
			_call_action(destination)

func _call_action(action_name: String) -> void:
	if _actions.has(action_name):
		var callback: Callable = _actions[action_name]
		if callback.is_valid():
			callback.call()

func _render_page() -> void:
	if not is_instance_valid(_middle):
		return
	ip_input = null
	_lan_rooms = null
	_lan_signature = ""
	world_picker = null
	world_create_input = null
	world_rename_input = null
	_volume_label = null
	_key_capture_feedback = null
	_key_capture_action = ""
	_key_buttons.clear()
	_view_distance_value = null
	_update_status_label = null
	_update_progress = null
	_update_install_button = null
	_update_check_button = null
	for child in _middle.get_children():
		_middle.remove_child(child)
		child.queue_free()
	for key in _nav_buttons:
		var button: Button = _nav_buttons[key]
		button.modulate = Color.WHITE if str(key)==_page or (str(key)=="play" and _page=="home") else Color("#e4d3b7")
	var wide := _page!="home"
	var x := 0.0 if not wide else -30.0
	var y := 24.0 if not wide else -42.0
	var w := 585.0 if not wide else 690.0
	var h := 373.0 if not wide else 548.0
	_panel_art = _art(_middle,PANEL,Vector2(x,y),Vector2(w,h))
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_place(_middle,scroll,Vector2(x+31,y+33),Vector2(w-62,h-69))
	_page_container = VBoxContainer.new()
	_page_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_container.add_theme_constant_override("separation",10)
	scroll.add_child(_page_container)
	_primary_button = null
	match _page:
		"network": _render_network()
		"new_world": _render_new_world()
		"worlds": _render_worlds()
		"settings": _render_settings()
		"controls": _render_controls()
		"updates": _render_updates()
		"credits": _render_credits()
		_: _render_home()

func _render_home() -> void:
	_page_container.add_child(_heading("✦  NOVIDADES DA CLAREIRA"))
	_page_container.add_child(HSeparator.new())
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation",13)
	_page_container.add_child(body)
	var features := VBoxContainer.new()
	features.add_theme_constant_override("separation",9)
	features.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(features)
	for message in [
		"✓  Árvores regenerativas",
		"✓  Construção de pisos e tetos",
		"✓  Multijogador na rede local",
		"✓  Goblins e criaturas em 3D",
		"✓  Fabricação de ferramentas",
		"✓  Múltiplos mapas com nomes"
	]:
		features.add_child(_text(message,19,CREAM,true))
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(121,165)
	portrait_frame.add_theme_stylebox_override("panel",_flat(Color("#120e0aa6"),BORDER,3,8))
	body.add_child(portrait_frame)
	var portrait := TextureRect.new()
	portrait.texture = preload("res://protagonista.jpg")
	portrait.custom_minimum_size = Vector2(100,143)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_frame.add_child(portrait)
	_page_container.add_child(HSeparator.new())
	_page_container.add_child(_text("Mundo selecionado: "+str(_state.get("active_world_name","Mundo original")),17,GOLD,true))
	_message()
	var cta := Button.new()
	cta.text = "▶  JOGAR AGORA"
	cta.custom_minimum_size = Vector2(370,67)
	cta.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_button(cta,true,true)
	_place(_middle,cta,Vector2(100,429),Vector2(370,67))
	cta.pressed.connect(func(): _activate("play"))
	_primary_button = cta

func _render_new_world() -> void:
	_page_container.add_child(_heading("✚  CRIAR NOVO MUNDO"))
	_page_container.add_child(_text("Escolha um nome para sua nova aventura.",19,CREAM,true))
	_page_container.add_child(HSeparator.new())
	_page_container.add_child(_text("NOME DO MAPA",18,GOLD))
	world_create_input = LineEdit.new()
	world_create_input.placeholder_text = "Ex.: Vale dos Goblins"
	world_create_input.max_length = 36
	world_create_input.custom_minimum_size.y = 49
	world_create_input.text_submitted.connect(func(_value: String): _world_create_pressed())
	_style_input(world_create_input)
	_page_container.add_child(world_create_input)
	_page_container.add_child(_text("Cada mundo terá seu próprio inventário, árvores, construções e progresso.",17,MUTED,true))
	var create_button := _action_button("✚  CRIAR E ENTRAR NO MUNDO",true)
	create_button.pressed.connect(_world_create_pressed)
	if str(_state.get("role","solo"))!="solo":
		create_button.disabled = true
		world_create_input.editable = false
		_page_container.add_child(_text("Saia da partida LAN para criar um mundo.",16,GOLD,true))
	_message()

func _render_worlds() -> void:
	var records: Array = _state.get("worlds",[])
	_page_container.add_child(_heading("▣  CARREGAR MUNDO"))
	_page_container.add_child(_text("Selecione um dos seus %d mundos salvos." % records.size(),18,CREAM,true))
	_page_container.add_child(HSeparator.new())
	world_picker = OptionButton.new()
	world_picker.custom_minimum_size.y = 52
	_style_input(world_picker)
	var active := str(_state.get("active_world_id","original"))
	var picked := 0
	for i in range(records.size()):
		var entry: Dictionary = records[i]
		var id := str(entry.get("id",""))
		world_picker.add_item(("★  " if id==active else "▣  ")+str(entry.get("name","Mundo")))
		world_picker.set_item_metadata(i,id)
		if id==active:
			picked=i
	world_picker.select(picked)
	world_picker.item_selected.connect(_world_choice_changed)
	_page_container.add_child(world_picker)
	_page_container.add_child(_text("★ indica o mundo que está aberto agora.",15,MUTED,true))
	var play := _action_button("▶  ENTRAR NO MUNDO SELECIONADO",true)
	play.pressed.connect(_world_load_pressed)
	_page_container.add_child(HSeparator.new())
	_page_container.add_child(_text("RENOMEAR MUNDO SELECIONADO",18,GOLD))
	var rename_row := HBoxContainer.new()
	rename_row.add_theme_constant_override("separation",9)
	_page_container.add_child(rename_row)
	world_rename_input = LineEdit.new()
	world_rename_input.max_length = 36
	world_rename_input.custom_minimum_size.y = 46
	world_rename_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_input(world_rename_input)
	rename_row.add_child(world_rename_input)
	var rename := Button.new()
	rename.text = "RENOMEAR"
	rename.custom_minimum_size = Vector2(138,46)
	_style_button(rename,false)
	rename.pressed.connect(_world_rename_pressed)
	rename_row.add_child(rename)
	var newworld := _action_button("✚  CRIAR OUTRO MUNDO")
	newworld.pressed.connect(func(): _activate("new_world"))
	if str(_state.get("role","solo"))!="solo":
		play.disabled = true
		rename.disabled = true
		newworld.disabled = true
		world_rename_input.editable = false
		_page_container.add_child(_text("Desconecte-se da LAN antes de trocar de mapa.",16,GOLD,true))
	_world_choice_changed(picked)
	_message()

func _selected_world_id() -> String:
	if not is_instance_valid(world_picker) or world_picker.item_count==0:
		return ""
	return str(world_picker.get_item_metadata(world_picker.selected))

func _world_choice_changed(index: int) -> void:
	if not is_instance_valid(world_picker) or not is_instance_valid(world_rename_input):
		return
	if index<0 or index>=world_picker.item_count:
		return
	var id := str(world_picker.get_item_metadata(index))
	for item in _state.get("worlds",[]):
		if str(item.get("id",""))==id:
			world_rename_input.text = str(item.get("name",""))
			break

func _world_load_pressed() -> void:
	var id := _selected_world_id()
	if not id.is_empty() and _actions.has("select_world"):
		var callback: Callable = _actions["select_world"]
		callback.call(id)

func _world_rename_pressed() -> void:
	var id := _selected_world_id()
	if not id.is_empty() and is_instance_valid(world_rename_input) and _actions.has("rename_world"):
		var callback: Callable = _actions["rename_world"]
		callback.call(id,world_rename_input.text)

func _world_create_pressed() -> void:
	if is_instance_valid(world_create_input) and _actions.has("create_world"):
		var callback: Callable = _actions["create_world"]
		callback.call(world_create_input.text)

func _render_network() -> void:
	_page_container.add_child(_heading("♜  MULTIJOGADOR LAN"))
	_page_container.add_child(_text("Mundo: "+str(_state.get("active_world_name","Mundo original")),17,GOLD,true))
	_page_container.add_child(HSeparator.new())
	var role := str(_state.get("role","solo"))
	if role=="solo":
		_page_container.add_child(_text("HOSPEDAR SEU MUNDO",18,GOLD))
		_page_container.add_child(_text("Amigos no mesmo roteador podem entrar na sua partida (UDP 24650).",16,CREAM,true))
		var host := _action_button("♜  HOSPEDAR PARTIDA",true)
		host.pressed.connect(func(): _call_action("host"))
		_page_container.add_child(HSeparator.new())
		_page_container.add_child(_text("PARTIDAS ABERTAS NA REDE",18,GOLD))
		_lan_rooms = VBoxContainer.new()
		_lan_rooms.add_theme_constant_override("separation",6)
		_page_container.add_child(_lan_rooms)
		update_lan_rooms([], "")
		var scan := _action_button("ATUALIZAR LISTA")
		scan.pressed.connect(func(): _call_action("refresh_lan"))
		_page_container.add_child(HSeparator.new())
		_page_container.add_child(_text("ENTRAR PELO IP (OPCIONAL)",18,GOLD))
		ip_input = LineEdit.new()
		ip_input.placeholder_text = "IP do anfitrião: 192.168.1.10"
		ip_input.text = str(_state.get("ip",""))
		ip_input.custom_minimum_size.y = 48
		_style_input(ip_input)
		ip_input.text_submitted.connect(func(_value: String): _call_action("join"))
		_page_container.add_child(ip_input)
		var old_ip := str(_state.get("last_connected_ip",""))
		if not old_ip.is_empty():
			_page_container.add_child(_text("Último servidor: "+old_ip,15,MUTED,true))
		var connect := _action_button("➜  CONECTAR PELO IP",true)
		connect.pressed.connect(func(): _call_action("join"))
	else:
		_page_container.add_child(_text("SALA HOSPEDADA" if role=="host" else "PARTIDA CONECTADA",20,GOLD))
		if role=="host":
			_page_container.add_child(_text("IP local: "+str(_state.get("host_ips","verifique em ipconfig")),18,CREAM,true))
			_page_container.add_child(_text("Jogadores: %d/8 · Porta UDP 24650" % int(_state.get("players",1)),17,CREAM))
		else:
			_page_container.add_child(_text("Anfitrião: "+str(_state.get("ip","")),17,CREAM))
			_page_container.add_child(_text("Mundo sincronizado" if bool(_state.get("world_ready",false)) else "Sincronizando mapa...",17,GOLD))
		var resume := _action_button("▶  VOLTAR À PARTIDA",true)
		resume.pressed.connect(func(): _call_action("play"))
		var leave := _action_button("DESCONECTAR DA PARTIDA")
		leave.pressed.connect(func(): _call_action("disconnect"))
	_message()

func wants_lan_discovery() -> bool:
	return is_visible_in_tree() and _page=="network" and str(_state.get("role","solo"))=="solo" and is_instance_valid(_lan_rooms)

func update_lan_rooms(rooms: Array, status: String) -> void:
	if not is_instance_valid(_lan_rooms):
		return
	var signature := JSON.stringify(rooms)+status
	if signature==_lan_signature:
		return
	_lan_signature = signature
	for child in _lan_rooms.get_children():
		_lan_rooms.remove_child(child)
		child.queue_free()
	if rooms.is_empty():
		_lan_rooms.add_child(_text(status if not status.is_empty() else "Buscando partidas na rede local…",16,MUTED,true))
		return
	for room in rooms:
		var ip := str(room.get("ip",""))
		var players := int(room.get("players",1))
		var button := Button.new()
		button.text = "%s  ·  %d/8 jogadores\n%s%s" % [str(room.get("world","Mundo")),players,ip,"  ·  Lotada" if players>=8 else ""]
		button.custom_minimum_size = Vector2(300,64)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_style_button(button,true,true)
		button.disabled = players>=8
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_lan_rooms.add_child(button)
		button.pressed.connect(_join_discovered.bind(ip))

func _join_discovered(ip: String) -> void:
	if _actions.has("join_discovered"):
		var callback: Callable = _actions["join_discovered"]
		if callback.is_valid():
			callback.call(ip)

func _render_settings() -> void:
	_page_container.add_child(_heading("⚙  CONFIGURAÇÕES"))
	_page_container.add_child(_text("AJUSTES DE SOM",18,GOLD))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",15)
	_page_container.add_child(row)
	var volume := HSlider.new()
	volume.min_value=0
	volume.max_value=100
	volume.step=5
	volume.custom_minimum_size=Vector2(365,40)
	volume.value=_current_volume()
	row.add_child(volume)
	_volume_label=_text("%d%%" % int(volume.value),18,CREAM)
	row.add_child(_volume_label)
	volume.value_changed.connect(_volume_changed)
	_page_container.add_child(HSeparator.new())
	_page_container.add_child(_text("EXIBIÇÃO",18,GOLD))
	var fullscreen := CheckButton.new()
	fullscreen.text="Tela cheia"
	fullscreen.add_theme_font_override("font",_font)
	fullscreen.add_theme_font_size_override("font_size",19)
	fullscreen.button_pressed = DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen.toggled.connect(_set_fullscreen)
	_page_container.add_child(fullscreen)
	var coords := CheckButton.new()
	coords.text = "Mostrar coordenadas e bússola"
	coords.add_theme_font_override("font",_font)
	coords.add_theme_font_size_override("font_size",19)
	coords.button_pressed = bool(_settings().get_value("display","show_coordinates",false))
	coords.toggled.connect(func(enabled: bool):
		var config := _settings()
		config.set_value("display","show_coordinates",enabled)
		config.save(OPTIONS_FILE)
		if _actions.has("toggle_coordinates"):
			var callback: Callable = _actions["toggle_coordinates"]
			if callback.is_valid():
				callback.call(enabled)
	)
	_page_container.add_child(coords)
	_page_container.add_child(HSeparator.new())
	_page_container.add_child(_text("DISTÂNCIA DE VISÃO DO MAPA",18,GOLD))
	var distance_row := HBoxContainer.new()
	distance_row.add_theme_constant_override("separation",15)
	_page_container.add_child(distance_row)
	var distance_slider := HSlider.new()
	distance_slider.min_value = 1
	distance_slider.max_value = 4
	distance_slider.step = 1
	distance_slider.custom_minimum_size = Vector2(315,40)
	distance_row.add_child(distance_slider)
	var current_radius: int = clampi(int(_state.get("view_radius",2)),1,4)
	_view_distance_value = _text(_distance_description(current_radius),17,CREAM,true)
	_page_container.add_child(_view_distance_value)
	distance_slider.set_value_no_signal(current_radius)
	distance_slider.value_changed.connect(_on_distance_changed)
	_page_container.add_child(_text("Padrão: 5×5 chunks. Distâncias maiores carregam mais árvores, terreno e colisões e podem diminuir o FPS.",15,MUTED,true))
	_page_container.add_child(HSeparator.new())
	_page_container.add_child(_text("CONTROLES PERSONALIZADOS",18,GOLD))
	var controls := _action_button("⌨  ALTERAR TECLAS DO JOGO",true)
	controls.pressed.connect(func(): _activate("controls"))
	_page_container.add_child(_text("Volume, exibição, distância de visão e teclas ficam salvos neste computador.",15,MUTED,true))
	_message()

func _render_controls() -> void:
	_page_container.add_child(_heading("⌨  CONFIGURAR TECLAS"))
	_page_container.add_child(_text("Clique na tecla de um comando e pressione a nova tecla. Esc cancela. Teclas 1–9 permanecem reservadas para a barra de itens.",16,CREAM,true))
	_page_container.add_child(HSeparator.new())
	_key_capture_feedback = _text("Escolha um comando abaixo para alterar.",15,MUTED,true)
	_page_container.add_child(_key_capture_feedback)
	if _controls_model==null:
		_page_container.add_child(_text("Os controles personalizados não estão disponíveis nesta tela.",17,GOLD,true))
	else:
		var action_list: Array = _controls_model.call("actions")
		for value in action_list:
			var action: String = str(value)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation",9)
			_page_container.add_child(row)
			var name_label := _text(str(_controls_model.call("label_for",action)),16,CREAM,true)
			name_label.custom_minimum_size.x=270
			name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			row.add_child(name_label)
			var button := Button.new()
			button.custom_minimum_size = Vector2(197,42)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_style_button(button,false)
			button.add_theme_font_size_override("font_size",16)
			button.pressed.connect(_begin_capture.bind(action))
			row.add_child(button)
			_key_buttons[action] = button
		_refresh_key_buttons()
		_page_container.add_child(_text("Setas e a tecla C continuam como alternativas. O mouse mantém os cliques para interagir e atacar.",15,MUTED,true))
		var restore := _action_button("↺  RESTAURAR TECLAS PADRÃO")
		restore.pressed.connect(_restore_keys)
	var back := _action_button("←  VOLTAR ÀS CONFIGURAÇÕES")
	back.pressed.connect(func(): _activate("settings"))

func _render_updates() -> void:
	_page_container.add_child(_heading("⇩  ATUALIZAÇÕES DO JOGO"))
	_page_container.add_child(_text("Atualize diretamente por aqui, sem abrir o navegador.",19,CREAM,true))
	_page_container.add_child(_text("O download é feito antes de fechar o jogo. Depois, a instalação começa automaticamente.",17,MUTED,true))
	_page_container.add_child(HSeparator.new())
	_update_status_label = _text("Consultando atualizações...",19,GOLD,true)
	_page_container.add_child(_update_status_label)
	_update_progress = ProgressBar.new()
	_update_progress.max_value = 100
	_update_progress.min_value = 0
	_update_progress.value = 0
	_update_progress.show_percentage = false
	_update_progress.custom_minimum_size.y = 20
	_page_container.add_child(_update_progress)
	_update_install_button = _action_button("⇩  BAIXAR E INSTALAR",true)
	_update_install_button.pressed.connect(func(): _call_action("install_update"))
	_update_check_button = _action_button("↻  VERIFICAR NOVAMENTE")
	_update_check_button.pressed.connect(func(): _call_action("check_update"))
	_page_container.add_child(HSeparator.new())
	_page_container.add_child(_text("O atualizador confere o arquivo antes de instalar e mantém um backup do executável anterior.",16,CREAM,true))
	_page_container.add_child(_text("Se a instalação falhar, o jogo não deve perder seus mundos e inventários salvos.",16,MUTED,true))
	var link := _action_button("↗  DOWNLOAD MANUAL (GITHUB)")
	link.pressed.connect(func(): OS.shell_open("https://github.com/clebertressi88/clareira-dos-goblins/releases/tag/jogo-windows"))
	_refresh_update_controls()
	if str((_state.get("updater",{}) as Dictionary).get("phase","idle"))=="idle":
		_call_action("check_update")

func refresh_update_state(info: Dictionary) -> void:
	_state["updater"] = info.duplicate(true)
	_refresh_update_indicator()
	if _page=="updates":
		_refresh_update_controls()

func _refresh_update_indicator() -> void:
	if not is_instance_valid(_update_marker):
		return
	var updater_state: Dictionary = _state.get("updater",{})
	_update_marker.visible = bool(updater_state.get("update_available",false))

func _refresh_update_controls() -> void:
	if not is_instance_valid(_update_status_label):
		return
	var status: Dictionary = _state.get("updater",{})
	var phase := str(status.get("phase","idle"))
	var message := str(status.get("message","Clique em verificar para buscar a última versão."))
	_update_status_label.text = message
	_update_progress.visible = phase in ["downloading","verified","installing"]
	_update_progress.value = clampf(float(status.get("percent",0)),0.0,100.0)
	_update_install_button.visible = phase in ["ready","downloading","verified","installing"]
	_update_install_button.disabled = phase!="ready"
	_update_install_button.text = "⇩  BAIXAR E INSTALAR" if phase=="ready" else "⇩  TRANSFERINDO / INSTALANDO..."
	_update_check_button.disabled = phase in ["checking","downloading","verified","installing"]
	if phase=="current":
		_update_status_label.add_theme_color_override("font_color",Color("#b8e58f"))
	elif phase=="error":
		_update_status_label.add_theme_color_override("font_color",Color("#f4b89c"))
	else:
		_update_status_label.add_theme_color_override("font_color",GOLD)

func _render_credits() -> void:
	_page_container.add_child(_heading("ⓘ  CRÉDITOS"))
	_page_container.add_child(_text("CLAREIRA DOS GOBLINS",24,GOLD))
	_page_container.add_child(_text("Jogo independente de aventura, coleta, exploração e construção.",19,CREAM,true))
	_page_container.add_child(HSeparator.new())
	_page_container.add_child(_text("Desenvolvimento do projeto: equipe Clareira dos Goblins.",18,CREAM,true))
	_page_container.add_child(_text("Motor gráfico: Godot Engine.",18,CREAM,true))
	var back := _action_button("←  VOLTAR AO MENU")
	back.pressed.connect(func(): _activate("home"))

func _message() -> void:
	var message := str(_state.get("message",""))
	if not message.is_empty():
		_page_container.add_child(_text(message,16,GOLD,true))

func _heading(value: String) -> Label:
	var title := _text(value,25,GOLD,true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return title

func _action_button(caption: String,highlight: bool = false) -> Button:
	var button := Button.new()
	button.text=caption
	button.custom_minimum_size=Vector2(300,48)
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	_style_button(button,highlight,highlight)
	_page_container.add_child(button)
	return button

func _style_input(control: Control) -> void:
	if control is LineEdit:
		control.add_theme_font_override("font",_font)
		control.add_theme_font_size_override("font_size",19)
		control.add_theme_color_override("font_color",CREAM)
		control.add_theme_color_override("font_placeholder_color",MUTED)
		control.add_theme_stylebox_override("normal",_flat(Color("#21180fdc"),BORDER,2,10))
		control.add_theme_stylebox_override("focus",_flat(Color("#2d231adf"),GOLD,2,10))
	elif control is OptionButton:
		control.add_theme_font_override("font",_font)
		control.add_theme_font_size_override("font_size",19)
		control.add_theme_color_override("font_color",CREAM)
		control.add_theme_stylebox_override("normal",_flat(Color("#21180fdc"),BORDER,2,8))
		control.add_theme_stylebox_override("hover",_flat(Color("#45321fe8"),GOLD,2,8))
		control.add_theme_stylebox_override("pressed",_flat(Color("#45321fe8"),GOLD,2,8))

func _style_button(button: Button,featured: bool = false,green: bool = false) -> void:
	button.add_theme_font_override("font",_font)
	button.add_theme_font_size_override("font_size",23 if green else 20)
	button.add_theme_color_override("font_color",CREAM)
	button.add_theme_color_override("font_hover_color",GOLD)
	button.add_theme_color_override("font_pressed_color",GOLD)
	button.add_theme_color_override("font_disabled_color",MUTED)
	button.add_theme_color_override("font_outline_color",Color("#201005"))
	button.add_theme_constant_override("outline_size",2)
	button.add_theme_stylebox_override("normal",_texture_style(PRIMARY if green else NAV_NORMAL))
	button.add_theme_stylebox_override("hover",_texture_style(PRIMARY if green else NAV_HOVER))
	button.add_theme_stylebox_override("pressed",_texture_style(PRIMARY if green else NAV_HOVER))
	button.add_theme_stylebox_override("focus",_flat(Color.TRANSPARENT,GOLD,2,5))
	button.add_theme_stylebox_override("disabled",_flat(Color("#26221dde"),Color("#705636"),2,6))

func _texture_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture=texture
	style.set_texture_margin_all(14)
	style.set_content_margin_all(10)
	return style

func _flat(fill: Color,border: Color,width: int,inset: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=fill
	style.border_color=border
	style.set_border_width_all(width)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(inset)
	return style

func _text(value: String,font_size: int,tint: Color,wrapped: bool = false) -> Label:
	var node := Label.new()
	node.text=value
	node.add_theme_font_override("font",_font)
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",tint)
	node.add_theme_color_override("font_outline_color",Color("#140b07a8"))
	node.add_theme_constant_override("outline_size",1)
	if wrapped:
		node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return node

func _settings() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(OPTIONS_FILE)
	return config

func _current_volume() -> float:
	var audio_bus := AudioServer.get_bus_index("Master")
	if audio_bus<0:
		return 100.0
	return clampf(AudioServer.get_bus_volume_linear(audio_bus)*100.0,0.0,100.0)

func _apply_saved_audio() -> void:
	var level := clampf(float(_settings().get_value("audio","volume",100.0)),0.0,100.0)
	var audio_bus := AudioServer.get_bus_index("Master")
	if audio_bus>=0:
		AudioServer.set_bus_volume_linear(audio_bus,level/100.0)

func _volume_changed(value: float) -> void:
	var audio_bus := AudioServer.get_bus_index("Master")
	if audio_bus>=0:
		AudioServer.set_bus_volume_linear(audio_bus,value/100.0)
	if is_instance_valid(_volume_label):
		_volume_label.text="%d%%" % int(value)
	var config := _settings()
	config.set_value("audio","volume",value)
	config.save(OPTIONS_FILE)

func _set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
