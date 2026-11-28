extends "res://main.gd"
## Aplicacao separada para desenvolvedores. Compartilha mecanicas e recursos,
## mas nunca carrega nem grava os saves do Clareira dos Goblins.

const LAB_WIDTH := 160.0
const LAB_SAVE := "user://laboratorio-arena-v1.dat"
var lab_loaded := false
var lab_floor: StaticBody3D
var lab_save_clock := 0.0
var lab_god_mode: CheckButton
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
var lab_icon_cache: Dictionary = {}
const LAB_ICON_SVG := {
	"tree": '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#34392a" stroke-width="1.6" stroke-linejoin="round"><path fill="#795032" d="M56 113l4-53-17-17 8-7 15 15 14-19 8 7-18 25 5 49 18 8H36z"/><path fill="#345b31" d="M14 63Q0 43 23 31Q21 9 50 14Q65-4 85 14Q112 9 113 36Q135 52 112 73Q91 91 65 74Q37 89 14 63Z"/><path fill="#699747" d="M22 42Q24 20 48 25Q63 7 81 25Q108 19 110 44Q84 59 66 44Q42 66 22 42Z"/></g></svg>',
	"young_tree": '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#34392a" stroke-width="1.6" stroke-linejoin="round"><path fill="#93643a" d="M59 115l3-42-14-15 5-5 12 12 12-15 5 4-13 20 2 41 10 5H48z"/><path fill="#4e7637" d="M31 64Q18 47 38 38Q34 21 56 25Q69 9 83 28Q105 28 103 49Q117 67 91 77Q64 87 31 64Z"/><path fill="#8cb65a" d="M37 44Q43 29 58 36Q70 20 85 37Q101 38 97 52Q72 64 37 44Z"/></g></svg>',
	"seedling": '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#34392a" stroke-width="1.6" stroke-linejoin="round"><path fill="#785037" d="M48 115l17-8 18 8-18 7z"/><path fill="none" stroke="#547e38" stroke-width="5" d="M65 112V69"/><path fill="#83b951" d="M65 90Q35 91 33 68Q57 64 65 90Z M65 80Q70 52 96 54Q94 78 65 80Z"/></g></svg>',
	"stump": '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#34392a" stroke-width="1.6" stroke-linejoin="round"><path fill="#805335" d="M40 54L36 91 8 110 38 105 48 97 58 119 70 102 99 115 88 91 86 54Z"/><ellipse fill="#dab17b" cx="63" cy="53" rx="24" ry="13"/><ellipse fill="none" stroke="#9c6e40" stroke-width="2" cx="63" cy="53" rx="14" ry="7"/><path fill="none" stroke="#c18a53" d="M47 69l-3 24m20-25v30m12-29 6 22"/></g></svg>',
	"wolf": '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#34392a" stroke-width="1.6" stroke-linejoin="round"><path fill="#50565a" d="M12 80L6 53 23 64 42 44 81 47 91 29 97 8 109 30 118 16 119 45 126 64 113 74 95 68 85 92 88 111 75 114 69 90 49 87 40 113 27 114 30 82Z"/><path fill="#92989a" d="M39 51l35 4 13 15-15 13-27-8-12 10-15-8Z"/><path fill="#c4c3b6" d="M90 44l16 5 17 15-14 7-18-10-11 11z"/><path fill="#e1ac40" d="M99 44l8 2-5 5z"/><path fill="#22292d" d="M119 60l7 4-7 5z"/></g></svg>',
	"rabbit": '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#34392a" stroke-width="1.6" stroke-linejoin="round"><ellipse fill="#96704c" cx="48" cy="87" rx="35" ry="25"/><ellipse fill="#d8c3a0" cx="16" cy="79" rx="10" ry="12"/><ellipse fill="#b18b62" cx="85" cy="68" rx="23" ry="24"/><ellipse fill="#b18b62" cx="75" cy="31" rx="9" ry="27" transform="rotate(-14 75 31)"/><ellipse fill="#c6988b" cx="75" cy="31" rx="4" ry="20" transform="rotate(-14 75 31)"/><ellipse fill="#96704c" cx="96" cy="31" rx="8" ry="25" transform="rotate(15 96 31)"/><ellipse fill="#dfc8a0" cx="91" cy="82" rx="13" ry="11"/><ellipse fill="#bd996e" cx="69" cy="108" rx="20" ry="8"/><circle fill="#241d17" cx="94" cy="62" r="4"/><circle fill="#49302d" cx="107" cy="77" r="3"/></g></svg>',
	"guardian": '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#34392a" stroke-width="1.6" stroke-linejoin="round"><path fill="#72503c" d="M40 71l-9 28 14 6 9-19 18 0 8 25 15-4-8-37Z"/><path fill="#637f3d" d="M36 58l-21 23 9 9 19-17 42 0 14 17 9-8-19-24z"/><path fill="#77618b" d="M40 58l24 10 23-10-4 31H43Z"/><path fill="#7b9849" d="M39 28L10 20 30 46 41 48 49 61 77 61 87 48 118 20 89 28 77 15 51 15Z"/><path fill="#39532e" d="M39 30l15 3-9 7zm49 0-15 3 9 7z"/><path fill="#e8c566" d="M43 33h9v4h-9zm33 0h9v4h-9z"/><path fill="#39432b" d="M54 48l9-8 10 8-8 5Z"/><path fill="#e9d7a2" d="M51 55l5-9 4 10m12 0 5-10 4 9"/><path fill="#9b7245" d="M102 18h5v99h-5z"/><path fill="#9ba5a0" d="M104 3l9 21-18 0z"/></g></svg>',
	"tomato_plant": '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#34392a" stroke-width="1.6" stroke-linejoin="round"><path fill="none" stroke="#54783a" stroke-width="5" d="M64 117V21M64 94L29 61M64 80L99 49M64 55L37 30M64 46L87 20"/><g fill="#689b43"><path d="M64 57Q30 57 19 35Q47 25 64 57Z M64 76Q100 44 117 51Q110 78 64 76Z M62 98Q28 95 12 73Q43 61 62 98Z M64 49Q62 15 88 10Q100 35 64 49Z M65 105Q92 80 113 91Q103 113 65 105Z"/></g><g fill="#d64b31"><circle cx="39" cy="70" r="12"/><circle cx="87" cy="68" r="13"/><circle cx="79" cy="99" r="12"/><circle cx="50" cy="100" r="11"/></g><g fill="#3d7031"><path d="M29 59l10 4 10-4-5 9-10 0z M77 55l10 5 10-5-5 10h-10z M69 87l10 5 10-5-5 9H74z"/></g></g></svg>',
	"fern": '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#34392a" stroke-width="1.6" stroke-linejoin="round"><path fill="none" stroke="#476b32" stroke-width="4" d="M64 116Q35 70 13 32M64 116Q63 49 64 10M64 116Q91 61 115 30"/><g fill="#6eaa53"><ellipse cx="20" cy="37" rx="16" ry="6" transform="rotate(28 20 37)"/><ellipse cx="108" cy="35" rx="16" ry="6" transform="rotate(-28 108 35)"/><ellipse cx="54" cy="25" rx="14" ry="6" transform="rotate(25 54 25)"/><ellipse cx="75" cy="25" rx="14" ry="6" transform="rotate(-25 75 25)"/><ellipse cx="27" cy="50" rx="16" ry="6" transform="rotate(28 27 50)"/><ellipse cx="101" cy="48" rx="16" ry="6" transform="rotate(-28 101 48)"/><ellipse cx="54" cy="38" rx="14" ry="6" transform="rotate(25 54 38)"/><ellipse cx="75" cy="38" rx="14" ry="6" transform="rotate(-25 75 38)"/><ellipse cx="34" cy="63" rx="16" ry="6" transform="rotate(28 34 63)"/><ellipse cx="94" cy="61" rx="16" ry="6" transform="rotate(-28 94 61)"/><ellipse cx="54" cy="51" rx="14" ry="6" transform="rotate(25 54 51)"/><ellipse cx="75" cy="51" rx="14" ry="6" transform="rotate(-25 75 51)"/><ellipse cx="41" cy="76" rx="16" ry="6" transform="rotate(28 41 76)"/><ellipse cx="87" cy="74" rx="16" ry="6" transform="rotate(-28 87 74)"/><ellipse cx="54" cy="64" rx="14" ry="6" transform="rotate(25 54 64)"/><ellipse cx="75" cy="64" rx="14" ry="6" transform="rotate(-25 75 64)"/><ellipse cx="48" cy="89" rx="16" ry="6" transform="rotate(28 48 89)"/><ellipse cx="80" cy="87" rx="16" ry="6" transform="rotate(-28 80 87)"/><ellipse cx="54" cy="77" rx="14" ry="6" transform="rotate(25 54 77)"/><ellipse cx="75" cy="77" rx="14" ry="6" transform="rotate(-25 75 77)"/></g></g></svg>',
	"forest_shrub": '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#34392a" stroke-width="1.6" stroke-linejoin="round"><path fill="#795637" d="M61 118V70h6v48Z"/><g fill="#527d3a"><ellipse cx="37" cy="86" rx="29" ry="23"/><ellipse cx="85" cy="85" rx="33" ry="26"/><ellipse cx="64" cy="59" rx="33" ry="32"/></g><g fill="#8caf58"><ellipse cx="38" cy="72" rx="19" ry="11"/><ellipse cx="64" cy="44" rx="19" ry="11"/><ellipse cx="88" cy="69" rx="20" ry="12"/></g></g></svg>',
	"river_reed": '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#34392a" stroke-width="1.6" stroke-linejoin="round"><g stroke="#648b42" stroke-width="5" fill="none"><path d="M58 117Q35 72 29 21M64 117V13M70 117Q95 58 103 24M60 114L15 65M66 114l48-52"/></g><g fill="#8b5a30"><rect x="24" y="10" width="10" height="35" rx="5"/><rect x="59" y="4" width="10" height="38" rx="5"/><rect x="98" y="12" width="10" height="34" rx="5"/></g></g></svg>',
	"vine_bush": '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#34392a" stroke-width="1.6" stroke-linejoin="round"><path fill="#567d3a" d="M12 86Q3 52 33 47Q47 15 68 38Q101 20 113 53Q133 81 105 100Q72 116 39 104Z"/><path fill="none" stroke="#b0b76b" stroke-width="5" d="M41 40Q12 80 48 94T45 122M82 41Q111 63 79 83T92 121"/><path fill="#93b75c" d="M25 63l22-9-6 24zM79 50l22 8-19 12zM55 83l21-4-12 21z"/></g></svg>',
	"Bruma": '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#34392a" stroke-width="1.6" stroke-linejoin="round"><path fill="#72503c" d="M40 71l-9 28 14 6 9-19 18 0 8 25 15-4-8-37Z"/><path fill="#637f3d" d="M36 58l-21 23 9 9 19-17 42 0 14 17 9-8-19-24z"/><path fill="#a04f79" d="M40 58l24 10 23-10-4 31H43Z"/><path fill="#7b9849" d="M39 28L10 20 30 46 41 48 49 61 77 61 87 48 118 20 89 28 77 15 51 15Z"/><path fill="#39532e" d="M39 30l15 3-9 7zm49 0-15 3 9 7z"/><path fill="#e8c566" d="M43 33h9v4h-9zm33 0h9v4h-9z"/><path fill="#39432b" d="M54 48l9-8 10 8-8 5Z"/><path fill="#e9d7a2" d="M51 55l5-9 4 10m12 0 5-10 4 9"/></g></svg>',
	"Talo": '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke="#34392a" stroke-width="1.6" stroke-linejoin="round"><path fill="#72503c" d="M40 71l-9 28 14 6 9-19 18 0 8 25 15-4-8-37Z"/><path fill="#637f3d" d="M36 58l-21 23 9 9 19-17 42 0 14 17 9-8-19-24z"/><path fill="#996b43" d="M40 58l24 10 23-10-4 31H43Z"/><path fill="#7b9849" d="M39 28L10 20 30 46 41 48 49 61 77 61 87 48 118 20 89 28 77 15 51 15Z"/><path fill="#39532e" d="M39 30l15 3-9 7zm49 0-15 3 9 7z"/><path fill="#e8c566" d="M43 33h9v4h-9zm33 0h9v4h-9z"/><path fill="#39432b" d="M54 48l9-8 10 8-8 5Z"/><path fill="#e9d7a2" d="M51 55l5-9 4 10m12 0 5-10 4 9"/></g></svg>'
}
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
	_sync_game_wolf_asset()
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
	_restore_lab_arena()
	lab_loaded = true
	get_tree().auto_accept_quit = false
	notice("Laboratório: arena salva automaticamente.")

func ground(_x: float, _z: float) -> float:
	return 0.0

func _create_flat_arena() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "ChaoPlanoDeTestes"
	lab_floor = floor_body
	floor_body.set_meta("lab_terrain",true)
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
	if not lab_loaded:
		return true
	var residents: Dictionary = {}
	var resources: Dictionary = {}
	for npc in villagers:
		if is_instance_valid(npc) and not npc.is_queued_for_deletion():
			var id := str(npc.get_meta("id",""))
			residents[id] = village_population.get(id,{}).duplicate(true)
			var values: Dictionary = {}
			for key in NPC_RESOURCE_KEYS:
				values[key] = npc.get_meta(key,-1 if key=="axe_item" else 0)
			values["extra_items"] = npc_extra_items(npc).duplicate(true)
			resources[id] = values
	var snapshot := capture_net_world()
	var live_objects: Array = []
	for entry in placed:
		var id := str(entry.get("id",""))
		var obj: Node3D = objects.get(id,null)
		if not is_instance_valid(obj) or obj.is_queued_for_deletion():
			continue
		var record: Dictionary = entry.duplicate(true)
		record["position"] = obj.global_position
		record["rotation"] = obj.rotation
		var metadata: Dictionary = {}
		for key in ["hp","cuts","hits"]:
			if obj.has_meta(key):
				metadata[key] = obj.get_meta(key)
		record["metadata"] = metadata
		live_objects.append(record)
	snapshot["placed"] = live_objects
	var data := {"format":1,"world":snapshot,"inventory":capture_inventory_state(),
		"residents":residents,"resources":resources,"birth_clock":village_birth_clock,
		"sequence":test_mob_sequence,"immortal":immortal,"player_position":player.position,
		"player_rotation":player.rotation,"camera_rotation":camera.rotation,
		"third_person":third_person,"saved_at":Time.get_unix_time_from_system()}
	var path := ProjectSettings.globalize_path(LAB_SAVE)
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:
		return false
	file.store_var(data,false)
	file.flush()
	var error := file.get_error()
	file.close()
	if error!=OK:
		return false
	if FileAccess.file_exists(path):
		if DirAccess.copy_absolute(path,path+".backup")!=OK:
			return false
	if DirAccess.rename_absolute(path+".tmp",path)!=OK:
		return false
	return true

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if save_game():
			get_tree().quit()
		else:
			notice("Falha ao salvar a arena. Fechamento cancelado.")

func _restore_lab_arena() -> void:
	var data: Variant = null
	for candidate in [LAB_SAVE,LAB_SAVE+".backup"]:
		if not FileAccess.file_exists(candidate):
			continue
		var file := FileAccess.open(candidate,FileAccess.READ)
		if file==null:
			continue
		data = file.get_var(false)
		file.close()
		if data is Dictionary and int(data.get("format",0))==1:
			break
	if not data is Dictionary or int(data.get("format",0))!=1:
		return
	var world: Dictionary = data.get("world",{})
	removed = world.get("removed",{})
	cleared_stumps = world.get("cleared_stumps",{})
	tree_regrowth = world.get("tree_regrowth",{})
	tree_vines = world.get("tree_vines",{})
	vegetation_harvest = world.get("vegetation_harvest",{})
	tomato_crop_times = world.get("tomato_crop_times",{})
	tomato_fruits = world.get("tomato_fruits",{})
	chest_storage = world.get("chest_storage",{})
	npc_saved_resources = data.get("resources",{})
	village_population = data.get("residents",{})
	village_birth_clock = float(data.get("birth_clock",0.0))
	npc_world_clock = float(world.get("npc_world_clock",0.0))
	test_mob_sequence = int(data.get("sequence",0))
	immortal = bool(data.get("immortal",true))
	if is_instance_valid(lab_god_mode):
		lab_god_mode.set_pressed_no_signal(immortal)
	# Manter o estagio das plantas durante o tempo em que o programa ficou fechado.
	var offline := maxf(0.0,Time.get_unix_time_from_system()-float(data.get("saved_at",Time.get_unix_time_from_system())))
	for timers in [tree_regrowth,tomato_crop_times,vegetation_harvest]:
		for id in timers:
			if timers[id] is float or timers[id] is int:
				timers[id] = float(timers[id])+offline
	for entry in world.get("placed",[]):
		if not entry is Dictionary:
			continue
		var id := str(entry.get("id",""))
		var kind := str(entry.get("kind",""))
		var at: Vector3 = entry.get("position",Vector3.ZERO)
		if id.is_empty() or kind.is_empty() or not at.is_finite():
			continue
		var obj := spawn_object(kind,id,at,self,float(entry.get("r",0.0)))
		obj.rotation = entry.get("rotation",obj.rotation)
		for key in entry.get("metadata",{}):
			obj.set_meta(key,entry["metadata"][key])
		placed.append({"kind":kind,"id":id,"p":[at.x,at.y,at.z],"r":obj.rotation.y,"level":int(entry.get("level",0))})
	for entity in world.get("entities",[]):
		var id := str(entity.get("id",""))
		var kind := str(entity.get("kind",""))
		var at: Vector3 = entity.get("p",Vector3.ZERO)
		if id.is_empty() or not at.is_finite():
			continue
		var obj: Node3D
		if bool(entity.get("resident",false)):
			spawn_friendly_goblin(id,at)
			obj = objects.get(id,null)
		elif kind in ["wolf","rabbit","guardian"]:
			obj = creature(kind,id,at,self)
		if is_instance_valid(obj):
			obj.global_position = at
			obj.rotation.y = float(entity.get("r",0.0))
			if int(entity.get("hp",-1))>=0:
				obj.set_meta("hp",int(entity["hp"]))
			obj.set_meta("wolf_fleeing",bool(entity.get("wolf_fleeing",false)))
	apply_inventory_state(data.get("inventory",{}))
	player.position = data.get("player_position",Vector3(0,1,0))
	player.rotation = data.get("player_rotation",Vector3.ZERO)
	camera.rotation = data.get("camera_rotation",Vector3.ZERO)
	if bool(data.get("third_person",false))!=third_person:
		toggle_view()
	update_npc_daylight(0.0)


func _physics_process(dt: float) -> void:
	super._physics_process(dt)
	lab_save_clock += dt
	if lab_save_clock >= 10.0:
		lab_save_clock = 0.0
		save_game()
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
	var version_path := OS.get_executable_path().get_base_dir().path_join("versao-github.txt")
	var build_label := "Dev local" if OS.has_feature("editor") else "Versão não identificada"
	if FileAccess.file_exists(version_path):
		var revision := FileAccess.get_file_as_string(version_path).strip_edges()
		if not revision.is_empty():
			build_label = revision.left(8)
	_heading("Versão: " + build_label,16)
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
	_lab_button("Importar skin Dire Wolf (ZIP/GLB)",_select_lab_wolf_skin)
	_lab_button("Sincronizar lobo do jogo",_sync_existing_wolves)
	_lab_button("Criar criatura a 5 metros",_spawn_selected_mob)
	_lab_button("Remover todas as criaturas",_remove_mobs)
	dev_body.add_child(HSeparator.new())
	_heading("CONTROLES DE TESTE",18)
	_lab_button("Salvar arena agora",func(): notice("Arena salva." if save_game() else "Falha ao salvar arena."))
	var god_mode := CheckButton.new()
	lab_god_mode = god_mode
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

func _select_lab_wolf_skin() -> void:
	var dialog := FileDialog.new()
	dialog.title = "Selecionar modelo Dire Wolf original"
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = PackedStringArray(["*.zip ; Pacote Dire Wolf","*.glb ; Modelo Dire Wolf"])
	add_child(dialog)
	dialog.file_selected.connect(func(path: String):
		if DIRE_WOLF.select_asset(path):
			for mob in mobs:
				if not is_instance_valid(mob) or mob.get_meta("kind","") != "wolf":
					continue
				var visual := mob.get_node_or_null("Visual") as Node3D
				if visual == null:
					continue
				var replacement: Node3D = DIRE_WOLF.new()
				replacement.name = "DireWolfRig"
				if replacement.call("install"):
					for child in visual.get_children():
						visual.remove_child(child)
						child.queue_free()
					visual.add_child(replacement)
				else:
					replacement.free()
			lab_note.text = "Skin Dire Wolf carregada."
		else:
			lab_note.text = "Arquivo invalido ou incompatível. Selecione o ZIP/GLB original."
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered_ratio(0.75)

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
		_creative_add(str(entry[0]),"Agricultura" if entry[1]=="tomato_plant" else "Natureza",str(entry[1]),-1,_lab_catalog_icon(str(entry[1]),ITEM_ICONS[int(entry[2])]))
	for entry in CREATURES:
		_creative_add(str(entry[0]),"Criaturas",str(entry[1]),-1,_lab_catalog_icon(str(entry[1]),null))

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
	lab_update_dialog.min_size = Vector2i(470,220)
	lab_update_dialog.max_size = Vector2i(560,320)
	lab_update_dialog.unresizable = true
	lab_update_dialog.dialog_hide_on_ok = false
	lab_update_dialog.ok_button_text = "Baixar e instalar"
	lab_update_dialog.cancel_button_text = "Fechar"
	layer.add_child(lab_update_dialog)
	var body := VBoxContainer.new()
	lab_update_dialog.add_child(body)
	body.add_theme_constant_override("separation",10)
	body.custom_minimum_size = Vector2(430,100)
	lab_update_status = Label.new()
	lab_update_status.custom_minimum_size.x = 430
	lab_update_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(lab_update_status)
	var warning := Label.new()
	warning.text = "A arena será salva antes da instalação e restaurada ao reiniciar."
	warning.custom_minimum_size = Vector2(430,48)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(warning)
	lab_update_progress = ProgressBar.new()
	lab_update_progress.custom_minimum_size.y = 24
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
	lab_update_dialog.popup_centered(Vector2i(500,260))
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
	if not save_game():
		updater.abort_install("Falha ao salvar a arena. Atualização cancelada.")
		return
	updater.download_and_install()

func _lab_update_verified() -> void:
	if not save_game():
		updater.abort_install("Falha ao salvar a arena. Atualização cancelada para proteger seus testes.")
		return
	if updater.launch_installer():
		get_tree().quit()

func _lab_update_changed(state: Dictionary) -> void:
	lab_update_state = state
	var phase := str(state.get("phase","idle"))
	lab_update_status.text = str(state.get("message","Verificando versão...")).replace("do jogo","do laboratório").replace("Seu jogo","Seu laboratório")
	lab_update_progress.value = int(state.get("percent",0))
	lab_update_progress.visible = phase in ["downloading","verified","installing"]
	lab_update_dialog.get_ok_button().disabled = phase!="ready"
	lab_update_dialog.get_ok_button().custom_minimum_size = Vector2(180,38)
	lab_update_dialog.get_cancel_button().custom_minimum_size = Vector2(100,38)
	lab_update_button.text = "↻  NOVA VERSÃO  [F7]" if bool(state.get("update_available",false)) else "↻  ATUALIZAR  [F7]"
	if phase=="downloading":
		lab_update_button.text = "Baixando %d%%" % int(state.get("percent",0))

# O modelo licenciado permanece no PC; compartilhar somente a referencia.
func _sync_game_wolf_asset() -> bool:
	var game_dir := ProjectSettings.globalize_path("user://").get_base_dir().path_join("Clareira dos Goblins")
	# globalize_path pode terminar em barra; normalizar antes de subir.
	var lab_dir := ProjectSettings.globalize_path("user://").trim_suffix("/").trim_suffix("\\")
	game_dir = lab_dir.get_base_dir().path_join("Clareira dos Goblins")
	var config := ConfigFile.new()
	if config.load(game_dir.path_join("dire_wolf_lab.cfg")) == OK:
		var path := str(config.get_value("asset","path",""))
		if FileAccess.file_exists(path) and DIRE_WOLF.select_asset(path):
			return true
	for folder in [game_dir,OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS),OS.get_executable_path().get_base_dir()]:
		for filename in ["Dire_Wolf_Lite_v1.0.0.zip","Dire_Wolf_Lite.glb"]:
			var path := str(folder).path_join(filename)
			if FileAccess.file_exists(path) and DIRE_WOLF.select_asset(path):
				return true
	return DIRE_WOLF._cache_asset()

func creature(kind: String, id: String, at: Vector3, parent: Node3D) -> CharacterBody3D:
	var body := super.creature(kind,id,at,parent)
	if kind=="wolf" and body.get_node_or_null("Visual/DireWolfRig")==null:
		notice("Dire Wolf indisponível. F6 > Importar skin Dire Wolf (ZIP/GLB).")
	return body

func _sync_existing_wolves() -> void:
	if not _sync_game_wolf_asset():
		notice("Modelo original não localizado. Importe o ZIP/GLB pelo F6.")
		return
	for mob in mobs:
		if not is_instance_valid(mob) or mob.get_meta("kind","")!="wolf":
			continue
		var visual := mob.get_node_or_null("Visual") as Node3D
		if visual==null:
			continue
		var rig: Node3D = DIRE_WOLF.new()
		if not bool(rig.call("install")):
			rig.free()
			continue
		for child in visual.get_children():
			visual.remove_child(child)
			child.queue_free()
		rig.name = "DireWolfRig"
		visual.add_child(rig)
	notice("Modelo Dire Wolf sincronizado com o jogo.")


func _lab_catalog_icon(kind: String, fallback: Texture2D) -> Texture2D:
	if not LAB_ICON_SVG.has(kind):
		return fallback
	if not lab_icon_cache.has(kind):
		var img := Image.new()
		if img.load_svg_from_string(str(LAB_ICON_SVG[kind]))!=OK:
			return fallback
		lab_icon_cache[kind] = ImageTexture.create_from_image(img)
	return lab_icon_cache[kind] as Texture2D
