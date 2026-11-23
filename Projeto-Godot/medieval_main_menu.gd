extends Control
## Tela principal independente do inventario. Usa somente controles nativos do Godot.

const GOLD := Color("#f4d18a")
const CREAM := Color("#f5ebd2")
const MUTED := Color("#c5b89c")
const DARK := Color("#181b16f0")
const WOOD := Color("#30251ced")
const BORDER := Color("#a47b44")

var ip_input: LineEdit
var world_picker: OptionButton
var world_create_input: LineEdit
var world_rename_input: LineEdit
var _state: Dictionary = {}
var _actions: Dictionary = {}
var _page := "home"
var _page_container: VBoxContainer

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
	for child in get_children():
		remove_child(child)
		child.queue_free()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color("#07130bb0")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	var base := VBoxContainer.new()
	base.add_theme_constant_override("separation", 14)
	margin.add_child(base)
	_build_header(base)
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	base.add_child(content)
	_build_navigation(content)
	var detail := _card(DARK, BORDER, 2, 22)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(detail)
	var scrolling := ScrollContainer.new()
	scrolling.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scrolling.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scrolling.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail.add_child(scrolling)
	_page_container = VBoxContainer.new()
	_page_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_container.add_theme_constant_override("separation", 11)
	scrolling.add_child(_page_container)
	_build_footer(base)
	_render_page()

func _build_header(parent: VBoxContainer) -> void:
	var header := _card(Color("#211810ed"), Color("#b68a4c"), 2, 12)
	header.custom_minimum_size.y = 102
	parent.add_child(header)
	var row := HBoxContainer.new()
	header.add_child(row)
	var ornament := _text("✦", 38, GOLD)
	ornament.custom_minimum_size.x = 68
	ornament.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ornament.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(ornament)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(titles)
	var title := _text("CLAREIRA DOS GOBLINS", 35, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titles.add_child(title)
	var subtitle := _text("UMA AVENTURA ENTRE FLORESTAS, PEDRAS E LENDAS", 13, MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titles.add_child(subtitle)
	var status := VBoxContainer.new()
	status.alignment = BoxContainer.ALIGNMENT_CENTER
	status.custom_minimum_size.x = 190
	row.add_child(status)
	status.add_child(_text("ACESSO ANTECIPADO", 13, GOLD))
	var role := String(_state.get("role", "solo"))
	var role_text := "MODO SOLO"
	if role == "host":
		role_text = "SALA LAN ABERTA"
	elif role == "client":
		role_text = "CONECTADO À LAN" if bool(_state.get("connected", false)) else "CONECTANDO..."
	status.add_child(_text(role_text, 13, CREAM))

func _build_navigation(parent: HBoxContainer) -> void:
	var card := _card(WOOD, BORDER, 2, 18)
	card.custom_minimum_size.x = 295
	parent.add_child(card)
	var links := VBoxContainer.new()
	links.add_theme_constant_override("separation", 10)
	card.add_child(links)
	links.add_child(_text("✦ ESCOLHA SEU CAMINHO", 16, GOLD))
	links.add_child(HSeparator.new())
	_menu_button(links, "▶  Jogar / continuar", "play", true)
	_menu_button(links, "▤  Meus mundos / mapas", "worlds")
	_menu_button(links, "♜  Multijogador LAN", "network")
	_menu_button(links, "⌨  Controles", "controls")
	if String(_state.get("role", "solo")) == "solo":
		_menu_button(links, "⚒  Laboratório de goblins", "lab")
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	links.add_child(spacer)
	_menu_button(links, "⏻  Salvar e sair", "quit")
	links.add_child(_text("Seu progresso é salvo ao sair.", 12, MUTED))

func _menu_button(parent: VBoxContainer, caption: String, action: String, featured: bool = false) -> void:
	var button := Button.new()
	button.text = caption
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 51
	_style_button(button, featured)
	button.pressed.connect(func(): _activate(action))
	parent.add_child(button)

func _activate(action: String) -> void:
	match action:
		"home", "network", "controls", "worlds":
			_page = action
			_render_page()
		_:
			_call_action(action)

func _call_action(action: String) -> void:
	if _actions.has(action):
		var cb: Callable = _actions[action]
		if cb.is_valid():
			cb.call()

func _render_page() -> void:
	if not is_instance_valid(_page_container):
		return
	ip_input = null
	world_picker = null
	world_create_input = null
	world_rename_input = null
	for child in _page_container.get_children():
		_page_container.remove_child(child)
		child.queue_free()
	match _page:
		"worlds":
			_render_worlds()
		"network":
			_render_network()
		"controls":
			_render_controls()
		_:
			_render_home()

func _render_home() -> void:
	_page_container.add_child(_text("BEM-VINDO À CLAREIRA", 25, GOLD))
	_page_container.add_child(_text("MUNDO ATIVO  ·  " + str(_state.get("active_world_name", "Mundo original")), 16, GOLD, true))
	_page_container.add_child(_text("Explore, construa seu abrigo e sobreviva às criaturas do vale.", 17, CREAM, true))
	_page_container.add_child(HSeparator.new())
	var subtitle := _text("O QUE ESPERA POR VOCÊ", 15, GOLD)
	_page_container.add_child(subtitle)
	for message in [
		"✦  Uma floresta viva com árvores que voltam a crescer",
		"✦  Construção de pisos, paredes, portas e telhados",
		"✦  Fabricação de ferramentas, armas e equipamentos",
		"✦  Lobos, coelhos e goblins pelo mundo",
		"✦  Exploração solo ou com amigos pela rede local"
	]:
		_page_container.add_child(_text(message, 16, CREAM, true))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_container.add_child(spacer)
	_page_container.add_child(_text("PRONTO PARA RETORNAR AO VALE?", 14, MUTED))
	var start := Button.new()
	start.text = "▶  ENTRAR NA AVENTURA"
	start.custom_minimum_size = Vector2(320, 58)
	_style_button(start, true)
	start.pressed.connect(func(): _call_action("play"))
	_page_container.add_child(start)
	_add_message()

func _render_worlds() -> void:
	_page_container.add_child(_text("MEUS MUNDOS", 25, GOLD))
	_page_container.add_child(_text("Cada mundo tem seu próprio inventário, construções e progresso.", 15, CREAM, true))
	_page_container.add_child(HSeparator.new())
	var records: Array = _state.get("worlds",[])
	_page_container.add_child(_text("ESCOLHA O MAPA  ·  %d salvos" % records.size(), 16, GOLD))
	world_picker = OptionButton.new()
	world_picker.custom_minimum_size.y = 43
	var current := str(_state.get("active_world_id","original"))
	var selected_index := 0
	for i in range(records.size()):
		var entry: Dictionary = records[i]
		var id := str(entry.get("id",""))
		var display_name := str(entry.get("name","Mundo"))
		world_picker.add_item(("★  " if id==current else "    ")+display_name)
		world_picker.set_item_metadata(i,id)
		if id==current:
			selected_index = i
	world_picker.select(selected_index)
	world_picker.item_selected.connect(_world_choice_changed)
	_page_container.add_child(world_picker)
	_page_container.add_child(_text("★ indica o mundo carregado neste computador.", 12, MUTED))
	var load_button := Button.new()
	load_button.text = "▶  CARREGAR MUNDO SELECIONADO"
	load_button.custom_minimum_size.y = 49
	_style_button(load_button,true)
	load_button.pressed.connect(_world_load_pressed)
	_page_container.add_child(load_button)
	_page_container.add_child(HSeparator.new())
	_page_container.add_child(_text("RENOMEAR MAPA", 16, GOLD))
	var rename_row := HBoxContainer.new()
	rename_row.add_theme_constant_override("separation",8)
	world_rename_input = LineEdit.new()
	world_rename_input.max_length = 36
	world_rename_input.custom_minimum_size.y = 43
	world_rename_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rename_row.add_child(world_rename_input)
	var rename_button := Button.new()
	rename_button.text = "Renomear"
	rename_button.custom_minimum_size.x = 125
	_style_button(rename_button,false)
	rename_button.pressed.connect(_world_rename_pressed)
	rename_row.add_child(rename_button)
	_page_container.add_child(rename_row)
	_page_container.add_child(HSeparator.new())
	_page_container.add_child(_text("CRIAR NOVO MUNDO", 16, GOLD))
	var create_row := HBoxContainer.new()
	create_row.add_theme_constant_override("separation",8)
	world_create_input = LineEdit.new()
	world_create_input.placeholder_text = "Nome do novo mapa (até 36 caracteres)"
	world_create_input.max_length = 36
	world_create_input.custom_minimum_size.y = 44
	world_create_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_create_input.text_submitted.connect(func(_text: String): _world_create_pressed())
	create_row.add_child(world_create_input)
	var create_button := Button.new()
	create_button.text = "＋  Criar"
	create_button.custom_minimum_size.x = 125
	_style_button(create_button,true)
	create_button.pressed.connect(_world_create_pressed)
	create_row.add_child(create_button)
	_page_container.add_child(create_row)
	_page_container.add_child(_text("Novo mundo começa do zero. O Mundo original permanece salvo.", 13, MUTED, true))
	if str(_state.get("role","solo"))!="solo":
		_page_container.add_child(_text("Para trocar de mundo, desconecte primeiro da partida LAN.", 13, Color("#f1c78b"), true))
		load_button.disabled = true
		rename_button.disabled = true
		create_button.disabled = true
		world_create_input.editable = false
		world_rename_input.editable = false
	_world_choice_changed(selected_index)
	_add_message()

func _selected_world_id() -> String:
	if not is_instance_valid(world_picker) or world_picker.item_count==0:
		return ""
	return str(world_picker.get_item_metadata(world_picker.selected))

func _world_choice_changed(index: int) -> void:
	if not is_instance_valid(world_picker) or not is_instance_valid(world_rename_input):
		return
	if index<0 or index>=world_picker.item_count:
		return
	var selected_id := str(world_picker.get_item_metadata(index))
	for record in _state.get("worlds",[]):
		if str(record.get("id",""))==selected_id:
			world_rename_input.text = str(record.get("name",""))
			break

func _world_load_pressed() -> void:
	var id := _selected_world_id()
	if not id.is_empty() and _actions.has("select_world"):
		var action: Callable = _actions["select_world"]
		action.call(id)

func _world_rename_pressed() -> void:
	var id := _selected_world_id()
	if not id.is_empty() and is_instance_valid(world_rename_input) and _actions.has("rename_world"):
		var action: Callable = _actions["rename_world"]
		action.call(id,world_rename_input.text)

func _world_create_pressed() -> void:
	if is_instance_valid(world_create_input) and _actions.has("create_world"):
		var action: Callable = _actions["create_world"]
		action.call(world_create_input.text)

func _render_network() -> void:
	_page_container.add_child(_text("MULTIJOGADOR · REDE LOCAL", 24, GOLD))
	_page_container.add_child(_text("Jogue no mesmo mapa com amigos ligados à mesma rede.", 16, CREAM, true))
	_page_container.add_child(_text("Mapa do anfitrião: " + str(_state.get("active_world_name","Mundo original")), 15, GOLD, true))
	_page_container.add_child(HSeparator.new())
	var role := String(_state.get("role", "solo"))
	if role == "solo":
		_page_container.add_child(_text("CRIAR PARTIDA", 17, GOLD))
		_page_container.add_child(_text("Este computador será o anfitrião. A porta usada é UDP 24650.", 15, MUTED, true))
		var host := Button.new()
		host.text = "♜  HOSPEDAR PARTIDA"
		host.custom_minimum_size.y = 53
		_style_button(host, true)
		host.pressed.connect(func(): _call_action("host"))
		_page_container.add_child(host)
		_page_container.add_child(HSeparator.new())
		_page_container.add_child(_text("ENTRAR EM UMA PARTIDA", 17, GOLD))
		_page_container.add_child(_text("Digite o endereço IPv4 do computador anfitrião:", 15, CREAM))
		ip_input = LineEdit.new()
		ip_input.placeholder_text = "Exemplo: 192.168.1.10"
		ip_input.text = String(_state.get("ip", ""))
		ip_input.custom_minimum_size.y = 47
		ip_input.focus_mode = Control.FOCUS_ALL
		ip_input.text_submitted.connect(func(_value: String): _call_action("join"))
		_page_container.add_child(ip_input)
		var previous_ip := String(_state.get("last_connected_ip", ""))
		if not previous_ip.is_empty():
			_page_container.add_child(_text("Último servidor conectado: " + previous_ip, 13, MUTED))
		var connect_button := Button.new()
		connect_button.text = "➜  CONECTAR PELO IP"
		connect_button.custom_minimum_size.y = 51
		_style_button(connect_button, false)
		connect_button.pressed.connect(func(): _call_action("join"))
		_page_container.add_child(connect_button)
	else:
		var active := _text("SALA HOSPEDADA" if role == "host" else "PARTIDA CONECTADA", 19, GOLD)
		_page_container.add_child(active)
		if role == "host":
			_page_container.add_child(_text("IP local: " + String(_state.get("host_ips", "verifique em ipconfig")), 17, CREAM, true))
			_page_container.add_child(_text("Jogadores: %d/8 · UDP 24650" % int(_state.get("players", 1)), 16, CREAM))
		else:
			_page_container.add_child(_text("Anfitrião: " + String(_state.get("ip", "")), 16, CREAM))
			_page_container.add_child(_text("Mundo sincronizado" if bool(_state.get("world_ready", false)) else "Aguardando sincronização do mundo...", 16, MUTED))
		var resume := Button.new()
		resume.text = "▶  VOLTAR À PARTIDA"
		resume.custom_minimum_size.y = 53
		_style_button(resume, true)
		resume.pressed.connect(func(): _call_action("play"))
		_page_container.add_child(resume)
		var disconnect := Button.new()
		disconnect.text = "Desconectar da partida"
		disconnect.custom_minimum_size.y = 48
		_style_button(disconnect, false)
		disconnect.pressed.connect(func(): _call_action("disconnect"))
		_page_container.add_child(disconnect)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_container.add_child(spacer)
	_page_container.add_child(_text("Todos precisam usar a mesma versão do jogo e a mesma rede.", 13, MUTED, true))
	_add_message()

func _render_controls() -> void:
	_page_container.add_child(_text("CONTROLES DO AVENTUREIRO", 24, GOLD))
	_page_container.add_child(_text("Os comandos básicos para começar a jogar.", 16, CREAM))
	_page_container.add_child(HSeparator.new())
	for item in [
		["W A S D / setas", "Movimentar"],
		["Mouse", "Olhar ao redor"],
		["Clique esquerdo", "Atacar / construir"],
		["Clique direito", "Pegar / interagir"],
		["Shift", "Correr"],
		["Espaço", "Pular"],
		["E", "Abrir inventário"],
		["Q", "Largar item"],
		["V", "Trocar câmera"],
		["ESC", "Pausar / abrir menu"],
		["F10", "Retornar à clareira"]
	]:
		var row := HBoxContainer.new()
		var key := _text(item[0], 15, GOLD)
		key.custom_minimum_size.x = 185
		row.add_child(key)
		row.add_child(_text(item[1], 15, CREAM))
		_page_container.add_child(row)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_container.add_child(spacer)
	var back := Button.new()
	back.text = "←  VOLTAR À TELA INICIAL"
	_style_button(back, false)
	back.pressed.connect(func(): _activate("home"))
	_page_container.add_child(back)

func _add_message() -> void:
	var msg := String(_state.get("message", ""))
	if msg.is_empty():
		return
	var alert := _text(msg, 14, Color("#f1c78b"), true)
	_page_container.add_child(alert)

func _build_footer(parent: VBoxContainer) -> void:
	var footer := _card(Color("#211b15e9"), Color("#715b3d"), 1, 9)
	parent.add_child(footer)
	var hint := _text("WASD  Mover     ·     Mouse  Mirar     ·     E  Inventário     ·     Shift  Correr     ·     ESC  Menu", 14, CREAM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(hint)

func _card(fill: Color, edge: Color, thickness: int, inset: int) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(thickness)
	style.set_corner_radius_all(9)
	style.content_margin_left = inset
	style.content_margin_right = inset
	style.content_margin_top = inset
	style.content_margin_bottom = inset
	style.shadow_color = Color("#0909079d")
	style.shadow_size = 5
	card.add_theme_stylebox_override("panel", style)
	return card

func _style_button(button: Button, featured: bool) -> void:
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_focus_color", GOLD)
	button.add_theme_stylebox_override("normal", _button_style(Color("#4b3423") if featured else Color("#322820"), BORDER))
	button.add_theme_stylebox_override("hover", _button_style(Color("#72502b"), GOLD))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#65401f"), GOLD))
	button.add_theme_stylebox_override("focus", _button_style(Color("#00000000"), GOLD))
	button.add_theme_stylebox_override("disabled", _button_style(Color("#242421"), Color("#565044")))

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.content_margin_left = 15
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _text(value: String, size: int, tint: Color, wrap_text: bool = false) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", tint)
	if wrap_text:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return result
