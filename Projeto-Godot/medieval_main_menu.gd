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
var _nav_buttons: Dictionary = {}
var _volume_label: Label

func _ready() -> void:
	_font = SystemFont.new()
	(_font as SystemFont).font_names = PackedStringArray(["Georgia","Palatino Linotype","Times New Roman"])
	resized.connect(_fit)
	_apply_saved_audio()

func rebuild(state: Dictionary, actions: Dictionary, starting_page: String = "home") -> void:
	_state = state
	_actions = actions
	_page = starting_page
	_recreate()

func _recreate() -> void:
	ip_input = null
	world_picker = null
	world_create_input = null
	world_rename_input = null
	_volume_label = null
	_nav_buttons.clear()
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
	var status := _text("●  BETA",20,GOLD)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_stage,status,Vector2(1440,25),Vector2(125,35))
	_navigation = VBoxContainer.new()
	_navigation.add_theme_constant_override("separation",5)
	_place(_stage,_navigation,Vector2(58,173),Vector2(307,645))
	_nav_button("▶  Jogar","home",true)
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
	var help := _text("WASD  MOVER     ·     MOUSE  ATACAR / USAR     ·     E  INVENTÁRIO     ·     SHIFT  CORRER     ·     ESPAÇO  PULAR",18,CREAM)
	_place(_stage,help,Vector2(394,835),Vector2(816,40))
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_render_page()
	_fit()

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

func _nav_button(text_value: String,page: String,featured: bool = false) -> void:
	var button := Button.new()
	button.text = text_value
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(304,59)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_button(button,featured)
	_navigation.add_child(button)
	_nav_buttons[page] = button
	button.pressed.connect(func(): _activate(page))

func _activate(destination: String) -> void:
	match destination:
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
	world_picker = null
	world_create_input = null
	world_rename_input = null
	_volume_label = null
	for child in _middle.get_children():
		_middle.remove_child(child)
		child.queue_free()
	for key in _nav_buttons:
		var button: Button = _nav_buttons[key]
		button.modulate = Color.WHITE if str(key)==_page else Color("#e4d3b7")
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
	cta.pressed.connect(func(): _call_action("play"))
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
		_page_container.add_child(_text("ENTRAR EM OUTRA PARTIDA",18,GOLD))
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
	_page_container.add_child(HSeparator.new())
	var controls := _action_button("⌨  VER CONTROLES DO JOGO")
	controls.pressed.connect(func(): _activate("controls"))
	_page_container.add_child(_text("As opções de som ficam salvas neste computador.",16,MUTED,true))
	_message()

func _render_controls() -> void:
	_page_container.add_child(_heading("⌨  CONTROLES"))
	for pair in [
		["WASD / setas","Movimentar"],["Mouse","Olhar ao redor"],
		["Clique esquerdo","Atacar / construir"],["Clique direito","Pegar / interagir"],
		["Shift","Correr"],["Espaço","Pular"],["E","Inventário"],
		["Q","Largar item"],["V","Trocar câmera"],["Esc","Menu"],
		["F10","Retornar à clareira"]
	]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",10)
		_page_container.add_child(row)
		var key := _text(pair[0],18,GOLD)
		key.custom_minimum_size.x=223
		row.add_child(key)
		row.add_child(_text(pair[1],18,CREAM))
	var back := _action_button("←  VOLTAR ÀS CONFIGURAÇÕES")
	back.pressed.connect(func(): _activate("settings"))

func _render_updates() -> void:
	_page_container.add_child(_heading("⇩  ATUALIZAÇÕES"))
	_page_container.add_child(_text("As versões Windows são publicadas no GitHub do jogo.",19,CREAM,true))
	_page_container.add_child(_text("Você também pode usar o atualizador instalado no computador.",18,MUTED,true))
	_page_container.add_child(HSeparator.new())
	var link := _action_button("⇩  ABRIR PÁGINA DE DOWNLOAD",true)
	link.pressed.connect(func(): OS.shell_open("https://github.com/clebertressi88/clareira-dos-goblins/releases/tag/jogo-windows"))

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
