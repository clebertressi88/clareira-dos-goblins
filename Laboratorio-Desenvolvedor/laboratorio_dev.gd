extends "res://main.gd"
## Aplicacao separada para desenvolvedores. Compartilha mecanicas e recursos,
## mas nunca carrega nem grava os saves do Clareira dos Goblins.

const LAB_WIDTH := 160.0
var dev_panel: PanelContainer
var dev_body: VBoxContainer
var catalog: ItemList
var catalog_filter: LineEdit
var catalog_ids: Array[int] = []
var mob_selector: OptionButton
var test_mob_sequence := 0
var immortal := true
var lab_open := false
var lab_note: Label

func _ready() -> void:
	# NAO chamar super._ready(): ele abre slots, saves e o mapa do jogo.
	while stock.size() < ITEMS.size():
		stock.append(0)
	while reserve.size() < ITEMS.size():
		reserve.append(0)
	inventory_slots.resize(ITEMS.size())
	inventory_slots.fill(-1)
	backpack_slots.resize(BACKPACK_SIZE)
	backpack_slots.fill(Vector2i(-1,0))
	village_population.clear()
	setup_world()
	configure_movement_inputs()
	_create_flat_arena()
	make_player()
	make_ui()
	_create_developer_ui()
	health = 100
	moving = true
	panel.hide()
	medieval_menu.hide()
	set_gameplay_overlays_visible(true)
	set_hotbar_interactive(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Materiais basicos para fabricar imediatamente e testar a bancada.
	for id in [1,2,4,6,7,11,23]:
		stock[id] = 64
	sync_hotbar()
	notice("Laboratorio independente: F6 abre o painel de desenvolvedor.")

func ground(_x: float, _z: float) -> float:
	return 0.0

func _create_flat_arena() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "ChaoPlanoDeTestes"
	floor_body.collision_layer = SOLID
	floor_body.collision_mask = 0
	floor_body.set_meta("kind","")
	add_child(floor_body)
	var floor_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(LAB_WIDTH,1.0,LAB_WIDTH)
	floor_shape.shape = shape
	floor_shape.position.y = -0.5
	floor_body.add_child(floor_shape)
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(LAB_WIDTH,LAB_WIDTH)
	mesh.mesh = plane
	var surface := StandardMaterial3D.new()
	surface.albedo_color = Color("#78846b")
	surface.roughness = 1.0
	mesh.material_override = surface
	floor_body.add_child(mesh)
	# Marcacoes discretas em intervalos de dez metros, sem colisao.
	var grid_mesh := ImmediateMesh.new()
	grid_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for n in range(-70,71,10):
		for endpoints in [[Vector3(float(n),.012,-80.0),Vector3(float(n),.012,80.0)],
				[Vector3(-80.0,.012,float(n)),Vector3(80.0,.012,float(n))]]:
			grid_mesh.surface_add_vertex(endpoints[0])
			grid_mesh.surface_add_vertex(endpoints[1])
	grid_mesh.surface_end()
	var grid := MeshInstance3D.new()
	grid.name = "GradeDeReferencia"
	grid.mesh = grid_mesh
	var grid_mat := StandardMaterial3D.new()
	grid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_mat.albedo_color = Color("#9da894")
	grid.material_override = grid_mat
	add_child(grid)

func load_chunks() -> void:
	pass # Arena ja esta inteira em uma unica malha; sem chunks, arvores ou mato.

func _process(_delta: float) -> void:
	pass # Nao executar streaming de chunks nem horizonte do mundo original.

func npc_has_loaded_ground(_pos: Vector3) -> bool:
	return true

func player_in_water() -> bool:
	return false

func player_head_submerged() -> bool:
	return false

func update_wolf_spawns(_dt: float) -> void:
	pass # Criaturas aparecem APENAS ao clicar em Criar mob.

func save_game() -> bool:
	return true # NENHUMA escrita no mundo ou inventario principal.

func _physics_process(dt: float) -> void:
	super._physics_process(dt)
	if immortal:
		health = 100
	if is_instance_valid(hud):
		hud.text = "LABORATORIO DO DESENVOLVEDOR  |  Arena plana  |  F6: ferramentas"
	if is_instance_valid(lab_note):
		lab_note.text = "Criaturas: %d  |  Objetos: %d  |  %s" % [mobs.size()+villagers.size(),placed.size(),"Invulneravel" if immortal else "Dano ativo"]

func show_menu(_starting_page: String = "home") -> void:
	_toggle_panel(true)

func begin() -> void:
	super.begin()
	if is_instance_valid(dev_panel):
		dev_panel.hide()
	lab_open = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F6:
			_toggle_panel(not lab_open)
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)

func _toggle_panel(visible_now: bool) -> void:
	if inventory:
		panel.hide()
		inventory = false
	dev_panel.visible = visible_now
	lab_open = visible_now
	moving = not visible_now
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible_now else Input.MOUSE_MODE_CAPTURED
	set_hotbar_interactive(false)

func _create_developer_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FerramentasDesenvolvedor"
	add_child(layer)
	dev_panel = PanelContainer.new()
	dev_panel.name = "PainelDesenvolvedor"
	layer.add_child(dev_panel)
	dev_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	dev_panel.offset_left = -368
	dev_panel.offset_right = -10
	dev_panel.offset_top = 14
	dev_panel.offset_bottom = -14
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1c241fee")
	style.border_color = Color("#a18b5a")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	dev_panel.add_theme_stylebox_override("panel",style)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dev_panel.add_child(scroll)
	dev_body = VBoxContainer.new()
	dev_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dev_body.add_theme_constant_override("separation",7)
	scroll.add_child(dev_body)
	_heading("LABORATORIO DEV",24)
	_heading("Clareira dos Goblins - sandbox",14)
	lab_note = Label.new()
	dev_body.add_child(lab_note)
	_lab_button("Fechar painel  [F6 / Esc]",func(): _toggle_panel(false))
	dev_body.add_child(HSeparator.new())
	_heading("INVENTARIO CRIATIVO",18)
	catalog_filter = LineEdit.new()
	catalog_filter.placeholder_text = "Buscar item ou ferramenta..."
	catalog_filter.text_changed.connect(_refresh_catalog)
	dev_body.add_child(catalog_filter)
	catalog = ItemList.new()
	catalog.custom_minimum_size = Vector2(315,205)
	catalog.select_mode = ItemList.SELECT_SINGLE
	catalog.item_activated.connect(func(_idx: int): _give_item(64))
	dev_body.add_child(catalog)
	_refresh_catalog("")
	_lab_button("Adicionar 1 item",func(): _give_item(1))
	_lab_button("Adicionar 64 e equipar na hotbar",func(): _give_item(64))
	_lab_button("Reabastecer todos os materiais",_restock_materials)
	dev_body.add_child(HSeparator.new())
	_heading("CRAFTING REAL DO JOGO",18)
	_lab_button("Inventario / crafting 2x2",func(): _open_test_craft("basic"))
	_lab_button("Bancada nivel 1 - crafting 3x3",func(): _open_test_craft("station",1))
	_lab_button("Bancada nivel 2 - crafting 3x3",func(): _open_test_craft("station",2))
	_lab_button("Marcenaria - crafting 5x5",func(): _open_test_craft("carpentry"))
	dev_body.add_child(HSeparator.new())
	_heading("CRIATURAS E NPCS",18)
	mob_selector = OptionButton.new()
	for label_value in ["Lobo predador","Coelho","Goblin guardiao","Bruma (NPC)","Talo (NPC)"]:
		mob_selector.add_item(label_value)
	dev_body.add_child(mob_selector)
	_lab_button("Criar criatura a 5 metros",_spawn_selected_mob)
	_lab_button("Remover todas as criaturas",_remove_mobs)
	dev_body.add_child(HSeparator.new())
	_heading("CONTROLES DE TESTE",18)
	var god_mode := CheckButton.new()
	god_mode.text = "Invulnerabilidade do jogador"
	god_mode.button_pressed = immortal
	god_mode.toggled.connect(func(value: bool): immortal = value)
	dev_body.add_child(god_mode)
	_lab_button("Definir meio-dia",func(): _set_lab_time(300.0))
	_lab_button("Definir meia-noite",func(): _set_lab_time(1500.0))
	_lab_button("Remover estruturas / limpar arena",_clear_structures)
	_lab_button("Voltar ao centro da arena",_reset_player)
	var footer := Label.new()
	footer.text = "WASD mover | mouse olhar/usar | E inventario\n1-9 hotbar | R girar | F5 camera | F6 painel"
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dev_body.add_child(footer)
	dev_panel.hide()

func _heading(content: String,font_size: int) -> void:
	var item := Label.new()
	item.text = content
	item.add_theme_font_size_override("font_size",font_size)
	item.add_theme_color_override("font_color",Color("#f1dcaf"))
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dev_body.add_child(item)

func _lab_button(content: String,callback: Callable) -> void:
	var b := Button.new()
	b.text = content
	b.custom_minimum_size.y = 34
	b.pressed.connect(callback)
	dev_body.add_child(b)

func _refresh_catalog(filter_value: String) -> void:
	catalog.clear()
	catalog_ids.clear()
	for i in range(ITEMS.size()):
		if not filter_value.is_empty() and not ITEMS[i].to_lower().contains(filter_value.to_lower()):
			continue
		catalog_ids.append(i)
		catalog.add_item(ITEMS[i],ITEM_ICONS[i])
	if catalog.item_count>0:
		catalog.select(0)

func _give_item(amount: int) -> void:
	var selected_items := catalog.get_selected_items()
	if selected_items.is_empty():
		notice("Selecione um item no catalogo.")
		return
	var id: int = catalog_ids[selected_items[0]]
	stock[id] = mini(999999,stock[id]+amount)
	bar_items[selected] = id
	hotbar_manual = true
	item_received(id)
	sync_hotbar()
	notice("%s: +%d (slot %d)" % [ITEMS[id],amount,selected+1])

func _restock_materials() -> void:
	for i in range(ITEMS.size()):
		stock[i] = maxi(64,int(stock[i]))
	sync_hotbar()
	notice("Todos os materiais e equipamentos receberam pelo menos 64 unidades.")

func _open_test_craft(mode: String,level: int = 1) -> void:
	_toggle_panel(false)
	if mode=="station":
		station_level = level
		_place_test_bench("bench2" if level==2 else "bench")
	elif mode=="carpentry":
		_place_test_bench("carpentry_bench")
	open_craft(mode)

func _place_test_bench(kind: String) -> void:
	for entry in placed:
		if str(entry.get("kind",""))==kind:
			var p: Array = entry.get("p",[])
			if p.size()>=3 and player.position.distance_to(Vector3(float(p[0]),float(p[1]),float(p[2])))<3.0:
				return
	var at: Vector3 = player.position-player.global_basis.z*1.8+player.global_basis.x*1.6
	at.y = ground(at.x,at.z)
	store_object(kind,at,player.rotation.y)

func _spawn_selected_mob() -> void:
	if not is_instance_valid(player):
		return
	var at: Vector3 = player.global_position-player.global_basis.z*5.0
	at.y = 0.0
	test_mob_sequence += 1
	match mob_selector.selected:
		0: creature("wolf","lab-wolf-%d" % test_mob_sequence,at,self)
		1: creature("rabbit","lab-rabbit-%d" % test_mob_sequence,at,self)
		2: creature("guardian","lab-guardian-%d" % test_mob_sequence,at,self)
		3,4:
			var id := "Bruma" if mob_selector.selected==3 else "Talo"
			if objects.has(id) and is_instance_valid(objects[id]):
				notice("%s ja existe na arena." % id)
				return
			village_population[id] = {"age":5400.0,"job":"Agricultor" if id=="Bruma" else "Lenhador"}
			spawn_friendly_goblin(id,at)
	notice("Criatura colocada na arena.")
	_toggle_panel(false)

func _remove_mobs() -> void:
	for mob in mobs:
		if is_instance_valid(mob):
			objects.erase(str(mob.get_meta("id","")))
			mob.queue_free()
	mobs.clear()
	for npc in villagers:
		if is_instance_valid(npc):
			objects.erase(str(npc.get_meta("id","")))
			npc.queue_free()
	villagers.clear()
	village_population.clear()
	roaming_wolf = null
	notice("Criaturas removidas.")

func _clear_structures() -> void:
	for entry in placed:
		var id: String = str(entry.get("id",""))
		if objects.has(id) and is_instance_valid(objects[id]):
			(objects[id] as Node).queue_free()
		objects.erase(id)
	placed.clear()
	chest_storage.clear()
	notice("Arena limpa, sem afetar os mundos do jogo.")

func _set_lab_time(clock: float) -> void:
	npc_world_clock = clock
	update_npc_daylight(0.0)
	notice("Iluminacao de teste alterada.")

func _reset_player() -> void:
	player.position = Vector3(0,1.0,0)
	player.velocity = Vector3.ZERO
	notice("Jogador voltou ao centro.")
