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
var lab_update_button: Button
var lab_update_dialog: ConfirmationDialog
var lab_update_status: Label
var lab_update_progress: ProgressBar
var lab_update_state: Dictionary = {}
var lab_update_resume := false
const LAB_UPDATER = preload("res://laboratorio_updater.gd")
var creative_panel: PanelContainer
var creative_list: ItemList
var creative_search: LineEdit
var creative_category: OptionButton
var creative_entries: Array[Dictionary] = []
var creative_visible := false
var placement_kind := ""
const NATURAL := [["Árvore adulta","tree",21],["Toco com raízes","stump",6],["Árvore jovem","young_tree",21],["Rocha mineral","stone",2],["Samambaia","fern",21],["Arbusto","forest_shrub",21],["Junco","river_reed",21],["Arbusto de cipó","vine_bush",11],["Tomateiro adulto","tomato_plant",27],["Muda de árvore","seedling",21]]
const CREATURES := [["Lobo","wolf"],["Coelho","rabbit"],["Goblin guardião","guardian"],["Bruma","Bruma"],["Talo","Talo"]]

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
	_create_creative_inventory()
	_create_lab_update_ui()
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
	# O topo da caixa fisica fica exatamente em Y=0, igual a ground().
	floor_shape.position.y = -shape.size.y * 0.5
	floor_body.add_child(floor_shape)
	var mesh := MeshInstance3D.new()
	mesh.name = "SuperficieVisual"
	var plane := PlaneMesh.new()
	plane.size = Vector2(LAB_WIDTH,LAB_WIDTH)
	mesh.mesh = plane
	# Usar a mesma altura do topo da colisao, sem deslocamento de 0,5 m.
	mesh.position.y = floor_shape.position.y + shape.size.y * 0.5
	assert(is_equal_approx(mesh.position.y, ground(0.0,0.0)))
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
		hud.text = "LABORATORIO DO DESENVOLVEDOR  |  Arena plana  |  E: inventário criativo  |  F6: ferramentas"
	if is_instance_valid(lab_note):
		lab_note.text = "Criaturas: %d  |  Objetos: %d  |  %s" % [mobs.size()+villagers.size(),placed.size(),"Invulneravel" if immortal else "Dano ativo"]

func show_menu(_starting_page: String = "home") -> void:
	_toggle_panel(true)

func begin() -> void:
	creative_visible = false
	if is_instance_valid(creative_panel):
		creative_panel.hide()
	super.begin()
	if is_instance_valid(dev_panel):
		dev_panel.hide()
	lab_open = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("goblin_inventario") or event.keycode == KEY_E:
			if creative_visible or inventory:
				begin()
			else:
				_open_creative_inventory()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE and creative_visible:
			begin()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE and not placement_kind.is_empty():
			placement_kind = ""
			notice("Posicionamento cancelado.")
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F7:
			_open_lab_update()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F6:
			_toggle_panel(not lab_open)
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)

func _toggle_panel(visible_now: bool) -> void:
	if is_instance_valid(creative_panel):
		creative_panel.hide()
	creative_visible = false
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
	dev_panel.offset_top = 65
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
	_lab_button("Abrir inventário criativo [E]",_open_creative_inventory)
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
	tree_regrowth.clear()
	tree_vines.clear()
	vegetation_harvest.clear()
	tomato_fruits.clear()
	tomato_crop_times.clear()
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

func _create_creative_inventory() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	creative_panel = PanelContainer.new()
	layer.add_child(creative_panel)
	creative_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	creative_panel.offset_left = 100
	creative_panel.offset_right = -100
	creative_panel.offset_top = 40
	creative_panel.offset_bottom = -150
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#202820f5")
	style.border_color = Color("#a18b5a")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	creative_panel.add_theme_stylebox_override("panel",style)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",8)
	creative_panel.add_child(body)
	var title := Label.new()
	title.text = "INVENTÁRIO CRIATIVO   |   Clique em um item para equipar ou posicionar"
	title.add_theme_font_size_override("font_size",22)
	body.add_child(title)
	var top := HBoxContainer.new()
	body.add_child(top)
	creative_category = OptionButton.new()
	for category in ["Todos","Ferramentas","Construção","Materiais","Natureza","Agricultura","Criaturas"]:
		creative_category.add_item(category)
	creative_category.item_selected.connect(func(_index: int): _rebuild_creative())
	top.add_child(creative_category)
	creative_search = LineEdit.new()
	creative_search.placeholder_text = "Pesquisar todos os itens..."
	creative_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	creative_search.text_changed.connect(func(_value: String): _rebuild_creative())
	top.add_child(creative_search)
	var close := Button.new()
	close.text = "Fechar [E / Esc]"
	close.pressed.connect(begin)
	top.add_child(close)
	creative_list = ItemList.new()
	creative_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	creative_list.max_columns = 0
	creative_list.fixed_column_width = 142
	creative_list.same_column_width = true
	creative_list.fixed_icon_size = Vector2i(42,42)
	creative_list.icon_mode = ItemList.ICON_MODE_TOP
	creative_list.max_text_lines = 2
	creative_list.add_theme_constant_override("h_separation",8)
	creative_list.add_theme_constant_override("v_separation",8)
	creative_list.item_clicked.connect(func(index: int,_pos: Vector2,button_index: int):
		if button_index==MOUSE_BUTTON_LEFT:
			_choose_creative(index))
	body.add_child(creative_list)
	var actions := HBoxContainer.new()
	body.add_child(actions)
	for option in [["Inventário / Crafting 2×2","basic",1],["Bancada 1","station",1],["Bancada 2","station",2],["Marcenaria","carpentry",1]]:
		var b := Button.new()
		b.text = str(option[0])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_open_test_craft.bind(str(option[1]),int(option[2])))
		actions.add_child(b)
	var caption := Label.new()
	caption.text = "Itens: 64 unidades no slot selecionado. Natureza e criaturas: selecione e clique no chão. Esc cancela."
	body.add_child(caption)
	creative_panel.hide()

func _open_creative_inventory() -> void:
	dev_panel.hide()
	lab_open = false
	panel.hide()
	inventory = false
	moving = false
	creative_visible = true
	creative_panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_hotbar_interactive(false)
	_rebuild_creative()

func _creative_add(label_value: String, category: String, kind: String, id: int, icon: Texture2D) -> void:
	var selected_category := creative_category.get_item_text(creative_category.selected)
	if selected_category!="Todos" and selected_category!=category:
		return
	if not creative_search.text.is_empty() and not label_value.to_lower().contains(creative_search.text.to_lower()):
		return
	creative_entries.append({"label":label_value,"kind":kind,"id":id})
	creative_list.add_item(label_value,icon)

func _rebuild_creative() -> void:
	creative_list.clear()
	creative_entries.clear()
	for i in range(ITEMS.size()):
		var category := "Materiais"
		if i in [0,8,9,10,20,24,25,26,34]:
			category = "Ferramentas"
		elif i in [13,14,16,17,18,19,22,29,30,31,32,33,35]:
			category = "Construção"
		elif i in [21,27,28]:
			category = "Agricultura"
		_creative_add(ITEMS[i],category,"item",i,ITEM_ICONS[i])
	for entry in NATURAL:
		_creative_add(str(entry[0]),"Agricultura" if entry[1]=="tomato_plant" else "Natureza",str(entry[1]),-1,ITEM_ICONS[int(entry[2])])
	for entry in CREATURES:
		_creative_add(str(entry[0]),"Criaturas",str(entry[1]),-1,null)

func _choose_creative(index: int) -> void:
	if index<0 or index>=creative_entries.size():
		return
	var entry: Dictionary = creative_entries[index]
	placement_kind = ""
	if entry["kind"]=="item":
		var id := int(entry["id"])
		stock[id] = maxi(64,int(stock[id]))
		# Evitar duplicar o mesmo item em varios slots.
		for i in range(bar_items.size()):
			if bar_items[i]==id:
				bar_items[i] = -1
		hotbar_manual = true
		bar_items[selected] = id
		item_received(id)
		sync_hotbar()
		notice(str(entry["label"])+" equipado.")
	else:
		placement_kind = str(entry["kind"])
		notice(str(entry["label"])+" | Clique esquerdo no chão; Esc cancela.")
	begin()

func primary() -> void:
	if placement_kind.is_empty():
		super.primary()
		return
	var hit := ray(30.0)
	if hit.is_empty() or str(hit["collider"].get_meta("kind",""))!="" or (hit["normal"] as Vector3).y<.7:
		notice("Aponte para um espaço livre no chão.")
		return
	var at: Vector3 = hit["position"]
	at.y = 0.0
	if at.distance_to(player.position)<1.5:
		notice("Posicione um pouco mais longe do jogador.")
		return
	var kind := placement_kind
	test_mob_sequence += 1
	var id := "lab-natural-%d" % test_mob_sequence
	if kind in ["wolf","rabbit","guardian"]:
		creature(kind,id,at,self)
	elif kind in ["Bruma","Talo"]:
		if objects.has(kind) and is_instance_valid(objects[kind]):
			notice("Este NPC já está no mapa.")
			return
		village_population[kind] = {"age":5400.0,"job":"Agricultor" if kind=="Bruma" else "Lenhador"}
		spawn_friendly_goblin(kind,at)
	else:
		var actual := "tree" if kind in ["stump","young_tree","seedling"] else kind
		if kind in ["stump","young_tree","seedling"]:
			var age := 0.0 if kind=="stump" else TREE_BUD_DELAY+TREE_GROW_SECONDS*.65 if kind=="young_tree" else TREE_BUD_DELAY+TREE_GROW_SECONDS*.25
			tree_regrowth[id] = Time.get_unix_time_from_system()-age
		placed.append({"kind":actual,"id":id,"p":[at.x,at.y,at.z],"r":0.0,"level":0})
		spawn_object(actual,id,at,self)
	notice("Objeto colocado. Clique novamente ou Esc para cancelar.")

func _create_lab_update_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 12
	add_child(layer)
	lab_update_button = Button.new()
	lab_update_button.text = "↻  ATUALIZAR  [F7]"
	lab_update_button.add_theme_font_size_override("font_size",18)
	lab_update_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	layer.add_child(lab_update_button)
	lab_update_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lab_update_button.offset_left = -255
	lab_update_button.offset_right = -12
	lab_update_button.offset_top = 8
	lab_update_button.offset_bottom = 53
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#245b39")
	normal.border_color = Color("#9bd28e")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	lab_update_button.add_theme_stylebox_override("normal",normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#337b4e")
	lab_update_button.add_theme_stylebox_override("hover",hover)
	lab_update_button.pressed.connect(_open_lab_update)
	lab_update_dialog = ConfirmationDialog.new()
	lab_update_dialog.title = "Atualização do Laboratório Dev"
	lab_update_dialog.min_size = Vector2i(470,180)
	lab_update_dialog.ok_button_text = "Baixar e instalar"
	lab_update_dialog.cancel_button_text = "Fechar"
	layer.add_child(lab_update_dialog)
	var body := VBoxContainer.new()
	lab_update_dialog.add_child(body)
	lab_update_status = Label.new()
	lab_update_status.custom_minimum_size.x = 430
	lab_update_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(lab_update_status)
	var warning := Label.new()
	warning.text = "A atualização reinicia somente o laboratório. A arena temporária será perdida."
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(warning)
	lab_update_progress = ProgressBar.new()
	lab_update_progress.show_percentage = true
	body.add_child(lab_update_progress)
	lab_update_dialog.confirmed.connect(_install_lab_update)
	lab_update_dialog.canceled.connect(_close_lab_update)
	lab_update_dialog.close_requested.connect(_close_lab_update)
	updater = LAB_UPDATER.new()
	updater.status_changed.connect(_lab_update_changed)
	updater.install_ready.connect(_lab_update_verified)
	add_child(updater)
	_lab_update_changed(updater.get_state())

func _open_lab_update() -> void:
	if lab_update_dialog.visible:
		return
	lab_update_resume = moving
	moving = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	lab_update_dialog.popup_centered()
	_lab_update_changed(updater.get_state())
	if str(lab_update_state.get("phase","")) not in ["ready","downloading","verified","installing"]:
		updater.check_updates()

func _close_lab_update() -> void:
	if lab_update_resume and not creative_visible and not inventory and not lab_open:
		moving = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _install_lab_update() -> void:
	if str(lab_update_state.get("phase",""))!="ready":
		return
	lab_update_dialog.popup_centered.call_deferred()
	updater.download_and_install()

func _lab_update_verified() -> void:
	if updater.launch_installer():
		get_tree().quit()

func _lab_update_changed(state: Dictionary) -> void:
	lab_update_state = state
	var phase := str(state.get("phase","idle"))
	lab_update_status.text = str(state.get("message","Verificando versão...")).replace("do jogo","do laboratório").replace("Seu jogo","Seu laboratório")
	lab_update_progress.value = int(state.get("percent",0))
	lab_update_progress.visible = phase in ["downloading","verified","installing"]
	lab_update_dialog.get_ok_button().disabled = phase!="ready"
	lab_update_button.text = "↻  NOVA VERSÃO  [F7]" if bool(state.get("update_available",false)) else "↻  ATUALIZAR  [F7]"
	if phase=="downloading":
		lab_update_button.text = "Baixando %d%%" % int(state.get("percent",0))
