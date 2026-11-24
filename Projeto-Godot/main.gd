extends Node3D

const SAVE := "user://clareira-nativa.json"
const LAN_PREFS_PATH := "user://clareira-multiplayer.cfg" # Arquivo antigo continua sendo o Mundo original
const WORLD_SLOTS := preload("res://world_slots.gd")
const LAN_INVENTORY := preload("res://lan_inventory_slots.gd")
const CELL := 0.85
const CHUNK := 16
const TERRAIN := preload("res://landscape_terrain.gd")
const MEDIEVAL_MENU := preload("res://medieval_main_menu.gd")
const GAME_UPDATER := preload("res://game_updater.gd")
const PLAY_AFTER_WORLD_CHANGE := "clareira_enter_world_after_reload"
const TREE_BUD_DELAY := 120.0
const TREE_GROW_SECONDS := 720.0
const TOMATO_ITEM := 27
const TOMATO_HEAL := 12
const TOMATO_SEED_ITEM := 28
const TOMATO_GROW_SECONDS := 300.0
const TOMATO_FRUIT_SECONDS := 600.0 # 10 min para cada novo fruto.
const TOMATO_MAX_FRUITS := 4
var tomato_fruits: Dictionary = {} # id -> {count, next}; estado compartilhado e salvo.
var tomato_crop_times: Dictionary = {}
const VINE_INTERVAL_SECONDS := 300.0 # Uma vinha a cada 5 min, apenas em arvores adultas.
var tree_vines: Dictionary = {} # id -> {count, next}; persistido/sincronizado pelo anfitriao.
var tree_regrowth: Dictionary = {} # id -> horario real do corte (segundos Unix)
var cleared_stumps: Dictionary = {} # locais de tocos desenterrados, persistente
var tree_regrowth_clock := 0.0
const ITEMS := ["Lança de pedra", "Graveto", "Pedra", "Carne", "Couro", "Pé de coelho", "Tronco", "Tábua", "Lança de madeira", "Machado de madeira", "Machado de pedra", "Cipó", "Corda", "Bancada de trabalho", "Fogueira", "Mochila", "Parede de madeira", "Parede com porta", "Parede com janela", "Bancada de trabalho · Nível 2", "Pá de madeira", "Muda de árvore", "Piso / teto de madeira", "Dente de lobo", "Porrete de espinhos", "Picareta de madeira", "Picareta de pedra", "Tomate", "Sementes de tomate", "Baú", "Escada reta", "Escada em L", "Escada vertical", "Bancada de marcenaria"]
const ITEM_KINDS := ["spear","stick","stone","meat","hide","foot","log","plank","wood_spear","wood_axe","stone_axe","vine","rope","bench","fire","backpack","wood_wall","wood_doorway","wood_window","bench2","shovel","sapling","wood_floor","wolf_tooth","spiked_club", "wood_pickaxe", "stone_pickaxe","tomato","tomato_seed","chest","stairs_straight","stairs_l","ladder","carpentry_bench"]
const CRAFT_OUTPUT := {"bench":"Bancada de trabalho · Nível 1","fire":"Fogueira","plank":"4 tábuas","spear":"Lança de pedra","wood_spear":"Lança de madeira","wood_axe":"Machado de madeira","stone_axe":"Machado de pedra","rope":"Corda","backpack":"Mochila","wood_wall":"Parede de madeira","wood_doorway":"Parede com porta","wood_window":"Parede com janela","bench2":"Bancada de trabalho · Nível 2","shovel":"Pá de madeira","spiked_club":"Porrete de espinhos","wood_pickaxe":"Picareta de madeira","stone_pickaxe":"Picareta de pedra","wood_floor":"Piso / teto de madeira","chest":"Baú","stairs_straight":"Escada reta","stairs_l":"Escada em L","ladder":"Escada vertical","carpentry_bench":"Bancada de marcenaria","tomato_seeds":"3 sementes de tomate"}
const LEVEL_2_RECIPES := ["stone_pickaxe","spiked_club","spear","carpentry_bench"]
const CARPENTRY_PATTERNS := {"wood_wall":[-1,-1,-1,-1,-1,-1,7,7,7,-1,-1,7,7,7,-1,-1,7,7,7,-1,-1,-1,-1,-1,-1],"wood_doorway":[-1,-1,-1,-1,-1,-1,7,7,7,-1,-1,7,-1,7,-1,-1,7,-1,7,-1,-1,-1,-1,-1,-1],"wood_window":[-1,-1,-1,-1,-1,-1,7,7,7,-1,-1,7,-1,7,-1,-1,7,7,7,-1,-1,-1,-1,-1,-1],"wood_floor":[-1,-1,-1,-1,-1,-1,7,7,7,-1,-1,7,6,7,-1,-1,7,7,7,-1,-1,-1,-1,-1,-1],"chest":[-1,-1,-1,-1,-1,-1,7,7,7,-1,-1,7,11,7,-1,-1,7,7,7,-1,-1,-1,-1,-1,-1],"ladder":[-1,-1,-1,-1,-1,-1,1,11,1,-1,-1,1,-1,1,-1,-1,1,11,1,-1,-1,-1,-1,-1,-1],"stairs_straight":[-1,-1,-1,7,7,-1,-1,7,7,1,-1,7,7,-1,-1,7,7,-1,-1,-1,1,-1,-1,-1,-1],"stairs_l":[-1,-1,-1,7,7,-1,-1,7,7,1,-1,1,7,7,7,-1,7,7,7,1,7,7,1,-1,-1]}
const STATION_PATTERNS := {"spear":[-1,-1,2,-1,1,-1,1,-1,-1],"wood_spear":[-1,-1,1,-1,1,-1,1,-1,-1],"wood_axe":[1,7,-1,1,7,-1,1,-1,-1],"stone_axe":[1,2,-1,1,2,-1,1,-1,-1],"backpack":[4,11,4,4,11,4,4,4,4],"bench2":[2,2,2,6,11,6,6,-1,6],"shovel":[-1,7,-1,-1,1,-1,-1,1,-1],"spiked_club":[-1,23,6,23,6,23,1,23,-1],"wood_pickaxe":[7,7,7,-1,1,-1,-1,1,-1],"stone_pickaxe":[2,2,2,-1,1,-1,-1,1,-1],"carpentry_bench":[7,7,7,7,10,7,6,7,6]}
const WOOD_AXE := 9
const STONE_AXE := 10
const TOOL_MAX_DURABILITY := {0:100,8:40,9:60,10:150,20:70,24:110,25:80,26:200}
var tool_durability: Dictionary = {} # Item -> durabilidade individual de cada unidade
const VINE := 11
const ROPE := 12
const BENCH_PATTERN := [7,7,1,1]
const FIRE_PATTERN := [1,1,2,-1] # Mantido ate validar visualmente a nova referencia da fogueira.
const BENCH_ITEM := 13
const FIRE_ITEM := 14
const BACKPACK_ITEM := 15
const WALL_ITEM := 16
const DOORWAY_ITEM := 17
const WINDOW_ITEM := 18
const BENCH2_ITEM := 19
const SHOVEL_ITEM := 20
const SAPLING_ITEM := 21
const FLOOR_ITEM := 22
const WOLF_TOOTH := 23
const SPIKED_CLUB := 24
const WOOD_PICKAXE := 25
const STONE_PICKAXE := 26
const CHEST_ITEM := 29
const CARPENTRY_ITEM := 33
const STAIR_ITEMS := [30,31,32]
const STAIR_KINDS := ["stairs_straight","stairs_l","ladder"]
const CHEST_SIZE := 16
const CHEST_STACK_LIMIT := 64
var chest_storage: Dictionary = {}
var open_chest_id := ""
var chest_selected_item := -1
var chest_pending := false
var pending_chest_id := ""
const BUILD_MAX_LEVEL := 3
const STARTER_CABIN_ID := "starter-cabin"
const STARTER_CABIN_CENTER := Vector2(0.0,-15.0)
const WALL_SIZE := CELL * 3.0
const HOTBAR_SIZE := 9
const NPC_PATROL_RADIUS := 8.0 # Limite da patrulha em metros, medido a partir da fogueira.
const NPC_MODEL_PATH := "res://modelos/goblin_npc.glb"
const NPC_RIG_SCRIPT := preload("res://npc_goblin_skirmisher.gd")
const GOBLIN_SKIN_TEST_SCENE: PackedScene = preload("res://experimentos/goblin_skin_teste.tscn")
# O script independente cria malha com pesos, Skeleton3D e animacao articulada.
const BUILD_TAG := "Árvores regenerativas · pisos e tetos · multiplayer LAN"
const BACKPACK_SIZE := 12
const BACKPACK_STACK_LIMIT := 64
var backpack_equipped := false
var sword_equipped := false
var shield_equipped := false
var backpack_slots: Array[Vector2i] = []
var backpack_selected_item := -1
var backpack_visual: Node3D
var hotbar_manual := false
var craft_mode := "basic"
var station_level := 1
var craft_cells: Array[Vector2i] = []
var craft_material := -1
const SOLID := 1
const TARGET := 2
const NET_PORT := 24650
const NET_PROTOCOL := 11 # Protocolo multiplayer com chunks por jogador e acoes validadas no servidor
const NET_SHARED_KINDS := ITEM_KINDS + ["block","hut","meat_wolf","meat_rabbit","vine_bush","tomato_plant","tomato_crop"] # Inclui armas e ferramentas que antes ficavam invisiveis aos outros jogadores
var stock := [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
var reserve := [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
var removed: Dictionary = {}
var placed: Array = []
var construction_ghost: Node3D
var construction_preview: Dictionary = {}
var build_level := 0 # 0=terreo; 1=segundo; 2=terceiro; 3=teto terceiro
var build_rotation := 0 # incrementos de 90 graus
var objects: Dictionary = {}
var chunks: Dictionary = {}
var mobs: Array[CharacterBody3D] = []
var villagers: Array[CharacterBody3D] = [] # Bruma e Talo: NPCs amigáveis que passeiam pela clareira.
var materials: Dictionary = {}
var surface_textures: Dictionary = {}
var wolf_face_materials: Dictionary = {}
var roaming_wolf: CharacterBody3D
var wolf_spawn_timer := 12.0
var rock_mesh: ArrayMesh
var sphere_mesh := SphereMesh.new()
var cube_mesh := BoxMesh.new()
var sculpt_sphere := SphereMesh.new()
var sculpt_head: ArrayMesh
var protagonist_face: ShaderMaterial
var player: CharacterBody3D
var camera: Camera3D
var player_model: Node3D
var third_person := false
var eye_height := 1.49
var spear: Node3D
var spear_tip: MeshInstance3D
var axe: Node3D
var wood_axe_head: Node3D
var stone_axe_head: Node3D
var shovel_head: Node3D
var spiked_club_head: Node3D
var wood_pickaxe_head: Node3D
var stone_pickaxe_head: Node3D
var crosshair: Label
var hud: Label
var hint: Label
var hotbar: HBoxContainer
const ITEM_ICONS := [preload("res://icones/0.png"),preload("res://icones/1.png"),preload("res://icones/2.png"),preload("res://icones/3.png"),preload("res://icones/4.png"),preload("res://icones/5.png"),preload("res://icones/6.png"),preload("res://icones/7.png"),preload("res://icones/8.png"),preload("res://icones/machado_madeira.svg"),preload("res://icones/10.png"),preload("res://icones/11.png"),preload("res://icones/12.png"),preload("res://icones/13.png"),preload("res://icones/14.png"),preload("res://icones/15.png"),preload("res://icones/16.png"),preload("res://icones/17.png"),preload("res://icones/18.png"),preload("res://icones/19.png"),preload("res://icones/20.svg"),preload("res://icones/21.svg"),preload("res://icones/22.svg"),preload("res://icones/23.svg"),preload("res://icones/24.svg"),preload("res://icones/25.svg"),preload("res://icones/26.svg"),preload("res://icones/27.svg"),preload("res://icones/28.svg"),preload("res://icones/29.svg"),preload("res://icones/stairs_straight.svg"),preload("res://icones/stairs_l.svg"),preload("res://icones/ladder.svg"),preload("res://icones/carpentry_bench.svg")]
var bar_items := [-1,-1,-1,-1,-1,-1,-1,-1,-1]
var inventory_slots: Array[int] = [] # A ordem visual pode ser alterada sem perder nenhum item.
var stone_axe_sprite: Sprite3D
var hotbar_icons: Array[TextureRect] = []
var hotbar_slots: Array[Label] = []
var hotbar_frames: Array[PanelContainer] = []
var hotbar_counts: Array[Label] = []
var hotbar_durability_bars: Array[ProgressBar] = []
var slot_idle: StyleBoxFlat
var slot_active: StyleBoxFlat
var next_interaction_hint := 0.0
var interaction_hint := "E Inventário  ·  Esc Menu"
var life_bar: ProgressBar
var stamina_bar: ProgressBar
var life_text: Label
var stamina_text: Label
var stamina := 100.0
var exhausted := false
var recovery_delay := 0.0
# A reserva de ar e independente da energia usada para correr.
const BREATH_UNDERWATER_SECONDS := 12.0
const BREATH_RECOVERY_SECONDS := 7.0
const BREATH_RECOVERY_PAUSE := 0.8
var breath := 100.0
var breath_recovery_delay := 0.0
var drowning_damage_clock := 0.0
const WALK_SPEED := 4.4
const RUN_SPEED := 6.7
const RABBIT_ESCAPE_SPEED := 3.45
var panel: PanelContainer
var menu: VBoxContainer
var medieval_menu: Control
var updater
var gameplay_overlays: Array[Control] = []
var address: LineEdit
var selected := 0
var health := 100
var bench := false
var hut := false
var won := false
var inventory := false
var moving := false
var jump := false
var elapsed := 0.0
var next_attack := 0.0
var next_hurt := 0.0
var next_save := 0.0
var next_net := 0.0
var feedback := ""
var feedback_until := 0.0
var remotes: Dictionary = {}
var net_role := "solo" # solo / host / client
var net_address := ""
var last_connected_lan_ip := ""
var net_connected := false
var net_world_ready := false
var net_world_backup: Dictionary = {}
var net_apply_in_progress := false
var net_session_message := ""
var net_entities_clock := 0.0
var net_last_hurt_by_peer: Dictionary = {}
var world_storage = WORLD_SLOTS.new()
var world_uid := ""
var net_remote_world_uid := ""
var net_offline_inventory_backup: Dictionary = {}

func _ready() -> void:
	# Saves antigos tinham 20 itens; ferramentas novas nao podem acessar indices
	# inexistentes. Sempre complete estoques antes de carregar inventario.
	while stock.size()<ITEMS.size():
		stock.append(0)
	while reserve.size()<ITEMS.size():
		reserve.append(0)
	inventory_slots.resize(ITEMS.size())
	inventory_slots.fill(-1)
	backpack_slots.resize(BACKPACK_SIZE)
	backpack_slots.fill(Vector2i(-1,0))
	setup_world()
	configure_movement_inputs()
	load_last_lan_ip()
	world_storage.initialize()
	load_game()
	if world_uid.is_empty():
		world_uid = Crypto.new().generate_random_bytes(16).hex_encode()
	make_player()
	make_ui()
	updater = GAME_UPDATER.new()
	add_child(updater)
	updater.status_changed.connect(_refresh_update_status)
	updater.install_ready.connect(_install_verified_update)
	village()
	load_chunks()
	show_menu()
	# Ao escolher outro mapa no menu Jogar, abrir a aventura depois
	# que a cena e o save selecionado terminarem de carregar.
	if get_tree().has_meta(PLAY_AFTER_WORLD_CHANGE):
		var requested_world: String = str(get_tree().get_meta(PLAY_AFTER_WORLD_CHANGE))
		get_tree().remove_meta(PLAY_AFTER_WORLD_CHANGE)
		if requested_world==str(world_storage.active_id):
			call_deferred("begin")
	multiplayer.peer_connected.connect(net_peer_connected)
	multiplayer.peer_disconnected.connect(net_peer_disconnected)
	multiplayer.connected_to_server.connect(net_connected_to_server)
	multiplayer.server_disconnected.connect(disconnected)
	multiplayer.connection_failed.connect(net_connection_failed)

func configure_movement_inputs() -> void:
	# Acoes configuradas no inicio: layouts de teclado diferentes e setas.
	# Nao depende exclusivamente de is_physical_key_pressed (WASD).
	var bindings := {
		"goblin_esquerda": [KEY_A,KEY_LEFT],
		"goblin_direita": [KEY_D,KEY_RIGHT],
		"goblin_frente": [KEY_W,KEY_UP],
		"goblin_tras": [KEY_S,KEY_DOWN]
	}
	for action: String in bindings.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in bindings[action]:
			var physical := InputEventKey.new()
			physical.physical_keycode = key
			if not InputMap.action_has_event(action,physical):
				InputMap.action_add_event(action,physical)
			var logical := InputEventKey.new()
			logical.keycode = key
			if not InputMap.action_has_event(action,logical):
				InputMap.action_add_event(action,logical)

func movement_axis() -> Vector2:
	var direction := Input.get_vector("goblin_esquerda","goblin_direita","goblin_frente","goblin_tras")
	if not direction.is_zero_approx():
		return direction
	# Reserva para teclados cuja entrada chega so como tecla logica.
	var x := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var y := float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	return Vector2(x,y).normalized()

func _input(event: InputEvent) -> void:
	var keyboard := event as InputEventKey
	if keyboard == null or not keyboard.pressed or keyboard.echo:
		return
	var key: int = keyboard.physical_keycode
	if key == KEY_NONE:
		key = keyboard.keycode
	if key==KEY_F10 and moving:
		# Recuperacao manual se um save antigo prender o jogador no relevo.
		respawn()
		save_game()
		get_viewport().set_input_as_handled()
		return
	# A tela inicial usa botoes com foco de teclado; teclas de movimento
	# nao devem abrir o jogo enquanto o jogador navega pelos menus.

func character_texture(family: String) -> ImageTexture:
	if surface_textures.has(family):
		return surface_textures[family]
	const SIZE := 128
	var image := Image.create_empty(SIZE,SIZE,false,Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = 507
	noise.frequency = .17
	for y in range(SIZE):
		for x in range(SIZE):
			var detail := noise.get_noise_2d(x,y)
			var broad := noise.get_noise_2d(x*.19+13,y*.19-11)
			var grain := noise.get_noise_2d(x*2.5,y*2.5)
			var value := .87+broad*.10+detail*.075+grain*.045
			if family=="fur":
				var strand := noise.get_noise_2d(x*5.5,y*.53+x*.13)
				value = .84+broad*.16+strand*.18+detail*.06
			elif family=="leather":
				value = .85+broad*.16+detail*.12+grain*.069
			image.set_pixel(x,y,Color(value,value,value*.984))
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	surface_textures[family] = texture
	return texture

func material(key: String, color: Color) -> StandardMaterial3D:
	if not materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = .87
		var family := ""
		if key.begins_with("sculpt_skin") or key.begins_with("goblin_cheek") or key.begins_with("goblin_brow") or key.begins_with("goblin_ear") or key=="goblin_nose":
			family = "skin"
			m.roughness = .64
		elif key.begins_with("goblin_boot") or key.begins_with("goblin_cloth") or key in ["goblin_strap","goblin_belt","goblin_waist"]:
			family = "leather"
			m.roughness = .75
		elif key.begins_with("bruma_hair") or key=="bruma_braid_light" or ((key.begins_with("wolf_") or key.begins_with("rabbit_")) and not (key.ends_with("iris") or key.ends_with("nose") or key.ends_with("inner"))):
			family = "fur"
		elif key.ends_with("iris") or key.ends_with("pupil") or key=="goblin_ivory":
			m.roughness = .27
		elif key=="goblin_brass":
			m.metallic = .38
			m.roughness = .37
		if not family.is_empty():
			m.albedo_texture = character_texture(family)
			m.uv1_triplanar = true
			m.uv1_triplanar_sharpness = 3.0
			m.uv1_scale = Vector3.ONE*(2.3 if family=="fur" else 1.4)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		materials[key] = m
	return materials[key]

func setup_world() -> void:
	sculpt_sphere.radial_segments = 24
	sculpt_sphere.rings = 16
	sphere_mesh.radial_segments = 12
	sphere_mesh.rings = 8
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#43738a")
	sky_material.sky_horizon_color = Color("#c3c9a1")
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c3d5d9")
	environment.ambient_light_energy = .52
	environment.fog_enabled = true
	environment.fog_light_color = Color("#98ada0")
	environment.fog_density = 0.008
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-47,-32,0)
	sun.light_color = Color("#fff0d6")
	sun.light_energy = .81
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 38
	add_child(sun)
	# Discos celestes visiveis diretamente no ceu, alem dos reflexos.
	sky_material.sun_angle_max = 5.0
	sky_material.sun_curve = 0.18
	environment.fog_sky_affect = 0.12
	npc_sun = sun
	npc_environment = environment
	npc_sky = sky_material
	npc_moon = DirectionalLight3D.new()
	npc_moon.name = "Lua"
	npc_moon.light_color = Color("#b9d3ff")
	npc_moon.light_energy = 0.0
	npc_moon.shadow_enabled = false
	add_child(npc_moon)
	update_npc_daylight(0.0)
	var grass := material("grass", Color("#f5f5ee"))
	grass.albedo_texture = preload("res://grass.png")
	# Renderizar ambas as faces: evita o terreno desaparecer quando a camera
	# aproxima-se da margem ou de uma encosta.
	grass.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var rock := material("rock", Color.WHITE)
	rock.albedo_texture = preload("res://stone.png")
	rock.uv1_triplanar = true
	rock.uv1_triplanar_sharpness = 3.5
	rock.uv1_scale = Vector3.ONE*1.45
	rock.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# Casca fotografica da referencia do jogador, reaplicada em troncos, tocos e raizes.
	var bark := material("tree_bark",Color.WHITE)
	bark.albedo_texture = preload("res://tree_bark_texture.gd").make_texture()
	bark.uv1_triplanar = true
	bark.uv1_triplanar_sharpness = 3.5
	bark.uv1_scale = Vector3(2.0,1.6,2.0)
	bark.roughness = .96
	bark.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	rock_mesh = make_rock()

func make_rock() -> ArrayMesh:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in range(3):
		for sign_value in [-1.0,1.0]:
			for j in range(5):
				for i in range(5):
					var u := float(i)/5
					var v := float(j)/5
					var corners := [Vector2(u,v),Vector2(u+.2,v),Vector2(u+.2,v+.2),Vector2(u,v+.2)]
					var order := [0,2,1,0,3,2] if sign_value > 0 else [0,1,2,0,2,3]
					for index in order:
						var uv: Vector2 = corners[index]
						var p := Vector3.ZERO
						p[axis] = sign_value
						p[(axis+1)%3] = uv.x*2-1
						p[(axis+2)%3] = uv.y*2-1
						var divisor := maxf(1.,maxf((p.x+.58*p.z+.35*p.y)/1.34,(-p.x-.75*p.z+.4*p.y)/1.39))
						p /= divisor
						p.x = p.x*(.92-.06*p.y)+.04*p.y
						p.z *= .94+.035*p.x
						mesh.set_uv(uv)
						mesh.add_vertex(p*CELL/2.)
	mesh.generate_normals()
	return mesh.commit()

func mesh_part(parent: Node3D, geometry: Mesh, pos: Vector3, scale_value: Vector3, mat: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = geometry
	part.material_override = mat
	part.position = pos
	part.scale = scale_value
	parent.add_child(part)
	return part

func ball(parent: Node3D, pos: Vector3, dimensions: Vector3, key: String, color: Color) -> void:
	mesh_part(parent,sphere_mesh,pos,dimensions,material(key,color))

func box(parent: Node3D, pos: Vector3, dimensions: Vector3, key: String, color: Color) -> MeshInstance3D:
	return mesh_part(parent,cube_mesh,pos,dimensions,material(key,color))

func cylinder(parent: Node3D, pos: Vector3, radius: float, tall: float, key: String, color: Color) -> MeshInstance3D:
	var geometry := CylinderMesh.new()
	geometry.top_radius = radius*.86
	geometry.bottom_radius = radius
	geometry.height = tall
	geometry.radial_segments = 10
	return mesh_part(parent,geometry,pos,Vector3.ONE,material(key,color))

func collider(body: CollisionObject3D, size: Vector3, offset: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	# Nome explicito: nos criados por codigo recebem nome automatico @CollisionShape3D@... .
	# As arvores precisam encontra-lo novamente para ajustar a colisao a cada estagio.
	col.name = "CollisionShape3D"
	col.shape = shape
	col.position = offset
	body.add_child(col)

func make_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Jogador"
	player.collision_layer = 4
	player.collision_mask = SOLID
	player.floor_snap_length = .25
	add_child(player)
	var spawn: Array = get_meta("spawn", [0,1,0])
	player.position = Vector3(float(spawn[0]),float(spawn[1]),float(spawn[2]))
	# Protege saves antigos: novo relevo nao pode fazer o jogador nascer soterrado.
	player.position.y = maxf(player.position.y,ground(player.position.x,player.position.z)+.65)
	var shape := CapsuleShape3D.new()
	shape.radius = .27
	shape.height = 1.64
	var col := CollisionShape3D.new()
	col.name = "Corpo"
	col.shape = shape
	col.position.y = .82
	player.add_child(col)
	camera = Camera3D.new()
	camera.position.y = 1.49
	camera.far = 125
	camera.current = true
	player.add_child(camera)
	player_model = Node3D.new()
	player_model.name = "Protagonista"
	player.add_child(player_model)
	player_model.rotation.y = PI
	goblin_npc(player_model,Color("#895938"),"player")
	apply_player_equipment()
	# Modelo 3D medieval detalhado, substitui os blocos antigos da mochila.
	backpack_visual = preload("res://backpack_model.gd").new()
	backpack_visual.name = "MochilaVestida"
	player_model.add_child(backpack_visual)
	var player_rig := player_model.get_node_or_null("GoblinRig")
	if player_rig != null and player_rig.has_method("attach_backpack"):
		if not bool(player_rig.call("attach_backpack",backpack_visual)):
			push_warning("Mochila sem osso de tronco; verifique o rig do personagem.")
	backpack_visual.visible = backpack_equipped
	player_model.hide()
	spear = Node3D.new()
	camera.add_child(spear)
	spear.position = Vector3(.40,-.46,-.77)
	spear.rotation_degrees = Vector3(-34,0,-20)
	cylinder(spear,Vector3.ZERO,.022,1.05,"wood",Color("#855b36"))
	for i in range(5):
		cylinder(spear,Vector3(0,.35+i*.018,0),.028,.012,"rope",Color("#cfb17e"))
	var tip := CylinderMesh.new()
	tip.top_radius = 0
	tip.bottom_radius = .075
	tip.height = .23
	tip.radial_segments = 4
	spear_tip = mesh_part(spear,tip,Vector3(0,.54,0),Vector3(1,1,.37),materials["rock"])
	axe = Node3D.new()
	camera.add_child(axe)
	axe.position = Vector3(.40,-.43,-.76)
	axe.rotation_degrees = Vector3(-25,0,-20)
	var axe_handle := cylinder(axe,Vector3.ZERO,.035,.74,"wood",Color("#855b36"))
	axe_handle.name = "CaboMachadoMadeira"
	wood_axe_head = Node3D.new()
	axe.add_child(wood_axe_head)
	preload("res://wood_axe_model.gd").build(wood_axe_head)
	stone_axe_head = Node3D.new()
	axe.add_child(stone_axe_head)
	make_stone_axe_head(stone_axe_head)
	shovel_head = Node3D.new()
	shovel_head.name = "CabecaPa"
	axe.add_child(shovel_head)
	preload("res://wood_shovel_model.gd").build(shovel_head)
	shovel_head.hide()
	spiked_club_head = Node3D.new()
	spiked_club_head.name = "PorreteEspinhos"
	axe.add_child(spiked_club_head)
	preload("res://spiked_club_model.gd").build(spiked_club_head)
	spiked_club_head.hide()
	wood_pickaxe_head = Node3D.new()
	wood_pickaxe_head.name = "PicaretaMadeira"
	axe.add_child(wood_pickaxe_head)
	preload("res://pickaxe_model.gd").build(wood_pickaxe_head,false)
	wood_pickaxe_head.hide()
	stone_pickaxe_head = Node3D.new()
	stone_pickaxe_head.name = "PicaretaPedra"
	axe.add_child(stone_pickaxe_head)
	preload("res://pickaxe_model.gd").build(stone_pickaxe_head,true)
	stone_pickaxe_head.hide()
	stone_axe_sprite = Sprite3D.new()
	stone_axe_sprite.name = "MachadoPedraAprovado"
	stone_axe_sprite.texture = preload("res://icones/machado_pedra_equipado.png")
	stone_axe_sprite.pixel_size = 0.00075
	stone_axe_sprite.position = Vector3(-.06,.13,.08)
	stone_axe_sprite.shaded = false
	stone_axe_sprite.double_sided = true
	stone_axe_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	axe.add_child(stone_axe_sprite)
	stone_axe_head.hide()
	stone_axe_sprite.hide()

# Malha de machado: silhueta curva com fio fino na extremidade, nao um bloco.
# Compartilhada por madeira e pedra para garantir formato IDENTICO.
func axe_blade_mesh() -> ArrayMesh:
	var outline := PackedVector2Array([
		Vector2(-.055,.205), Vector2(.035,.175), Vector2(.150,.125),
		Vector2(.275,.105), Vector2(.385,.095), Vector2(.455,.110),
		Vector2(.422,.225), Vector2(.408,.340), Vector2(.448,.455),
		Vector2(.365,.465), Vector2(.240,.430), Vector2(.100,.395),
		Vector2(-.045,.380)
	])
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Extrusao espessa junto ao cabo e mais fina no fio (lado direito).
	var center := Vector2(.15,.28)
	for i in range(outline.size()):
		var j := (i+1)%outline.size()
		var a := outline[i]
		var b := outline[j]
		var za := lerpf(.065,.012,clampf((a.x-.10)/.35,0.,1.))
		var zb := lerpf(.065,.012,clampf((b.x-.10)/.35,0.,1.))
		for side in [-1.,1.]:
			var p0 := Vector3(center.x,center.y,side*.078)
			var p1 := Vector3(a.x,a.y,side*za)
			var p2 := Vector3(b.x,b.y,side*zb)
			if side>0.:
				mesh.set_uv(Vector2(.5,.5))
				mesh.add_vertex(p0)
				mesh.set_uv(Vector2(a.x,a.y))
				mesh.add_vertex(p1)
				mesh.set_uv(Vector2(b.x,b.y))
				mesh.add_vertex(p2)
			else:
				mesh.set_uv(Vector2(.5,.5))
				mesh.add_vertex(p0)
				mesh.set_uv(Vector2(b.x,b.y))
				mesh.add_vertex(p2)
				mesh.set_uv(Vector2(a.x,a.y))
				mesh.add_vertex(p1)
		var v0 := Vector3(a.x,a.y,-za)
		var v1 := Vector3(b.x,b.y,-zb)
		var v2 := Vector3(a.x,a.y,za)
		var v3 := Vector3(b.x,b.y,zb)
		for pt in [v0,v1,v2,v1,v3,v2]:
			mesh.set_uv(Vector2(pt.x,pt.y))
			mesh.add_vertex(pt)
	mesh.generate_normals()
	return mesh.commit()

func make_axe_head(parent: Node3D, wooden: bool) -> void:
	var blade_mat: Material = material("wood_axe_blade_v2",Color("#ae743c")) if wooden else materials["rock"]
	mesh_part(parent,axe_blade_mesh(),Vector3.ZERO,Vector3.ONE,blade_mat)
	# Lascas/fibras na madeira e marcas de pedra sem modificar a silhueta.
	if wooden:
		for i in range(3):
			var grain := box(parent,Vector3(.13+i*.08,.245+i*.018,.066),Vector3(.075,.010,.005),"wood_axe_grain",Color("#704622"))
			grain.rotation.z = -.24
	# Amarracao frontal e traseira no encaixe do cabo.
	for i in range(4):
		var binding := cylinder(parent,Vector3(.012,.235+i*.031,0),.061,.014,"axe_binding",Color("#d4b282"))
		binding.rotation.z = .13

func make_wood_axe_head(parent: Node3D) -> void:
	make_axe_head(parent,true)

func make_stone_axe_head(parent: Node3D) -> void:
	make_axe_head(parent,false)

func ground(x: float,z: float) -> float:
	return TERRAIN.height_at(x,z)

func chunk_from_position(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x/CHUNK),floori(pos.z/CHUNK))

func load_chunks() -> void:
	# Cada maquina desenha sua vizinhanca; o anfitriao mantem carregadas
	# TODAS as vizinhancas ocupadas por jogadores, mesmo distantes entre si.
	var centers: Array[Vector2i] = [chunk_from_position(player.global_position)]
	if net_role=="host":
		for peer_id in remotes.keys():
			var avatar: Node3D = remotes[peer_id]
			if not is_instance_valid(avatar):
				continue
			var remote_pos: Vector3 = avatar.get_meta("destination",avatar.global_position)
			var remote_center := chunk_from_position(remote_pos)
			if not centers.has(remote_center):
				centers.append(remote_center)
	var desired: Dictionary = {}
	for center_index in range(centers.size()):
		var center: Vector2i = centers[center_index]
		# O host conserva cinco por cinco ao redor de si; para cada visitante,
		# tres por tres bastam para validar acoes sem renderizar o mundo inteiro.
		var radius := 2 if center_index==0 else 1
		for z in range(center.y-radius,center.y+radius+1):
			for x in range(center.x-radius,center.x+radius+1):
				desired[Vector2i(x,z)] = true
	for key: Vector2i in chunks.keys():
		if desired.has(key):
			continue
		var chunk: Node3D = chunks[key]
		for child in chunk.get_children():
			objects.erase(child.get_meta("id",""))
		chunk.queue_free()
		chunks.erase(key)
	for key: Vector2i in desired.keys():
		if not chunks.has(key):
			create_chunk(key)

func create_chunk(key: Vector2i) -> void:
	var chunk := Node3D.new()
	add_child(chunk)
	chunks[key] = chunk
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	# A malha visivel e a colisao HeightMap usam a MESMA grade de 1 metro.
	# Antes: malha 2 m x colisao 1 m; a camera parecia atravessar encostas.
	for z in range(CHUNK):
		for x in range(CHUNK):
			var left := float(key.x*CHUNK+x)
			var near := float(key.y*CHUNK+z)
			# Godot usa frente horaria: inversao dos indices fazia as normais
			# apontarem para -Y e ocultava o chao visto de cima.
			for corner in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var px: float = left+corner.x
				var pz: float = near+corner.y
				mesh.set_uv(Vector2(px,pz)/2.)
				mesh.add_vertex(Vector3(px,ground(px,pz),pz))
	mesh.generate_normals()
	var geometry := mesh.commit()
	var land := mesh_part(chunk,geometry,Vector3.ZERO,Vector3.ONE,materials["grass"])
	land.name = "TerrenoVisual"
	# Colisao independente da malha visual. O metodo create_trimesh_collision()
	# nao estava produzindo superficie fisica detectavel no teste de caminhada.
	# HeightMapShape3D fornece solo continuo, sem costas de triangulos abertas.
	var floor_body := StaticBody3D.new()
	floor_body.name = "TerrenoFisico"
	floor_body.collision_layer = SOLID
	floor_body.collision_mask = 0
	floor_body.position = Vector3(float(key.x*CHUNK)+float(CHUNK)*.5,0.0,float(key.y*CHUNK)+float(CHUNK)*.5)
	chunk.add_child(floor_body)
	var height_shape := HeightMapShape3D.new()
	height_shape.map_width = CHUNK+1
	height_shape.map_depth = CHUNK+1
	var heights := PackedFloat32Array()
	heights.resize((CHUNK+1)*(CHUNK+1))
	for zi in range(CHUNK+1):
		for xi in range(CHUNK+1):
			heights[zi*(CHUNK+1)+xi] = ground(float(key.x*CHUNK+xi),float(key.y*CHUNK+zi))
	height_shape.map_data = heights
	var floor_collision := CollisionShape3D.new()
	floor_collision.name = "ColisaoTerreno"
	floor_collision.shape = height_shape
	floor_body.add_child(floor_collision)
	create_river_chunk(chunk,key)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	for i in range(15):
		var x := key.x*CHUNK+rng.randf_range(1,15)
		var z := key.y*CHUNK+rng.randf_range(1,15)
		if Vector2(x,z).length()<5 or Vector2(x-STARTER_CABIN_CENTER.x,z-STARTER_CABIN_CENTER.y).length()<5.8 or TERRAIN.is_river(x,z):
			continue
		var kind := "tree" if i<6 else "stone" if i<9 else "stick" if i<12 else "rabbit" if i==12 else "tomato_plant"
		var id := "%s:%s:%s" % [key.x,key.y,i]
		if kind=="tree" and cleared_stumps.has(id):
			continue
		var at := Vector3(x,ground(x,z),z)
		# Compatibilidade: antigas arvores cortadas ficavam em "removed".
		# Transforma-as em tocos regenerativos sem reaparecer adultas de uma vez.
		if kind == "tree" and removed.has(id):
			removed.erase(id)
			if not tree_regrowth.has(id):
				tree_regrowth[id] = Time.get_unix_time_from_system()
		if kind == "rabbit":
			if not removed.has(id) and net_role!="client":
				creature(kind,id,at,chunk)
		elif not removed.has(id):
			spawn_object(kind,id,at,chunk)

func create_river_chunk(chunk: Node3D, key: Vector2i) -> void:
	var x0 := float(key.x * CHUNK)
	var x1 := x0 + float(CHUNK)
	var z0 := float(key.y * CHUNK)
	var z1 := z0 + float(CHUNK)
	var low := minf(TERRAIN.river_x(z0), TERRAIN.river_x(z1))
	var high := maxf(TERRAIN.river_x(z0), TERRAIN.river_x(z1))
	if high + TERRAIN.RIVER_HALF_WIDTH < x0 or low - TERRAIN.RIVER_HALF_WIDTH > x1:
		return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(8):
		var za := z0 + float(i) * 2.0
		var zb := za + 2.0
		var ca := TERRAIN.river_x(za)
		var cb := TERRAIN.river_x(zb)
		var left_a := Vector3(ca - TERRAIN.RIVER_HALF_WIDTH,TERRAIN.WATER_LEVEL,za)
		var right_a := Vector3(ca + TERRAIN.RIVER_HALF_WIDTH,TERRAIN.WATER_LEVEL,za)
		var left_b := Vector3(cb - TERRAIN.RIVER_HALF_WIDTH,TERRAIN.WATER_LEVEL,zb)
		var right_b := Vector3(cb + TERRAIN.RIVER_HALF_WIDTH,TERRAIN.WATER_LEVEL,zb)
		# Agua com normais voltadas para +Y, mesma orientacao do terreno.
		for point in [left_a,right_a,left_b,right_a,right_b,left_b]:
			surface.set_uv(Vector2(point.x,point.z) * .06)
			surface.add_vertex(point)
	surface.generate_normals()
	var water_material := material("river_water",Color(.15,.43,.59,.77))
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.metallic = .08
	water_material.roughness = .25
	water_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var water := mesh_part(chunk,surface.commit(),Vector3.ZERO,Vector3.ONE,water_material)
	water.name = "Rio_Sinuoso"
	# Superficie visual do rio; a natacao e o folego usam WATER_LEVEL e o relevo deterministico.

func village() -> void:
	if not removed.has(STARTER_CABIN_ID):
		spawn_starter_cabin()
	spawn_friendly_goblin("Bruma",Vector3(-2,0,-4))
	spawn_friendly_goblin("Talo",Vector3(2,0,-5))
	if not removed.has("fire"):
		spawn_object("fire","fire",Vector3(0,0,-6))
	if hut and not won and not removed.has("guardiao"):
		creature("guardian","guardiao",Vector3(3,0,-39),self)
	for entry in placed:
		if str(entry.get("kind",""))=="hut":
			continue
		var p: Array = entry["p"]
		spawn_object(entry["kind"],entry["id"],Vector3(p[0],p[1],p[2]),self,float(entry.get("r",0.0)))

# NPCs são corpos dinâmicos; o antigo objeto fixo impedia que andassem.
func spawn_friendly_goblin(kind: String, at: Vector3) -> void:
	var npc := CharacterBody3D.new()
	npc.name = kind
	npc.collision_layer = SOLID|TARGET
	npc.collision_mask = SOLID|4 # Obstáculos, outros goblins e jogador.
	npc.floor_snap_length = .34
	add_child(npc)
	npc.position = Vector3(at.x,ground(at.x,at.z)+.08,at.z)
	npc.set_meta("kind",kind)
	npc.set_meta("id",kind)
	npc.set_meta("home",npc.position)
	npc.set_meta("ai_state","idle")
	npc.set_meta("ai_until",elapsed+randf_range(.35,1.0))
	npc.set_meta("next_react",elapsed+randf_range(5.0,12.0))
	npc.set_meta("talk_count",0)
	npc.set_meta("next_work",elapsed+randf_range(15.0,35.0))
	var visual := Node3D.new()
	visual.name = "Visual"
	npc.add_child(visual)
	goblin_npc(visual,Color("#9b4b78") if kind=="Bruma" else Color("#866342"), "bruma" if kind=="Bruma" else "talo")
	collider(npc,Vector3(.63,1.47,.55),Vector3.UP*.74)
	objects[kind] = npc
	villagers.append(npc)

func get_campfire_center() -> Vector3:
	# A fogueira original é a referência do acampamento. Uma fogueira construída
	# pode substituí-la quando a original tiver sido removida.
	if objects.has("fire"):
		var original: Node3D = objects["fire"]
		if is_instance_valid(original) and not original.is_queued_for_deletion():
			return original.global_position
	for obj in objects.values():
		if is_instance_valid(obj) and not obj.is_queued_for_deletion() and obj.get_meta("kind","")=="fire":
			return obj.global_position
	return Vector3(0,0,-6)

func choose_goblin_destination(npc: CharacterBody3D) -> void:
	var campfire := get_campfire_center()
	var clearance := SphereShape3D.new()
	clearance.radius = .40
	var space := get_world_3d().direct_space_state
	for attempt in range(18):
		var direction := Vector3.FORWARD.rotated(Vector3.UP,randf()*TAU)
		# Escolhe pontos DENTRO do círculo, não a partir do local onde o NPC está.
		var destination := campfire + direction*randf_range(2.1,NPC_PATROL_RADIUS-1.0)
		destination.y = ground(destination.x,destination.z)+.08
		if destination.distance_to(player.global_position)<1.2:
			continue
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = clearance
		query.transform.origin = destination+Vector3.UP*.70
		query.collision_mask = SOLID|4
		query.exclude = [npc.get_rid()]
		if not space.intersect_shape(query,1).is_empty():
			continue
		# Evita a fogueira também no trajeto em linha reta.
		var line_from := Vector2(npc.position.x,npc.position.z)
		var line_to := Vector2(destination.x,destination.z)
		var center := Vector2(campfire.x,campfire.z)
		var segment := line_to-line_from
		var t := clampf((center-line_from).dot(segment)/maxf(segment.length_squared(),.01),0.0,1.0)
		if center.distance_to(line_from+segment*t)<1.45:
			continue
		npc.set_meta("wander_goal",destination)
		npc.set_meta("ai_state","walk")
		npc.set_meta("ai_until",elapsed+10.0)
		npc.set_meta("walk_speed",randf_range(1.05,1.55))
		return
	npc.set_meta("ai_state","idle")
	npc.set_meta("ai_until",elapsed+randf_range(.7,1.8))

# Rotina de trabalho dos moradores, executada somente pela autoridade do mundo.
var npc_sun: DirectionalLight3D
var npc_moon: DirectionalLight3D
var npc_environment: Environment
var npc_sky: ProceduralSkyMaterial
var npc_world_clock := 0.0
const NPC_DAY_SECONDS := 1200.0
const NPC_NIGHT_SECONDS := 300.0

func npc_is_night() -> bool:
	return fposmod(npc_world_clock,NPC_DAY_SECONDS+NPC_NIGHT_SECONDS)>=NPC_DAY_SECONDS

func update_npc_daylight(dt: float) -> void:
	npc_world_clock += dt
	if npc_sun==null or npc_environment==null or npc_sky==null:
		return
	var phase := fposmod(npc_world_clock,NPC_DAY_SECONDS+NPC_NIGHT_SECONDS)
	var dark := smoothstep(NPC_DAY_SECONDS-25.0,NPC_DAY_SECONDS,phase)*(1.0-smoothstep(NPC_DAY_SECONDS+NPC_NIGHT_SECONDS-25.0,NPC_DAY_SECONDS+NPC_NIGHT_SECONDS,phase))
	var day_progress := clampf(phase/NPC_DAY_SECONDS,0.0,1.0)
	var night_progress := clampf((phase-NPC_DAY_SECONDS)/NPC_NIGHT_SECONDS,0.0,1.0)
	# Cada astro percorre seu arco acima do horizonte na fase correspondente.
	var sun_altitude := lerpf(4.0,70.0,sin(day_progress*PI)) if phase<NPC_DAY_SECONDS else -12.0
	var moon_altitude := lerpf(4.0,65.0,sin(night_progress*PI)) if phase>=NPC_DAY_SECONDS else -12.0
	npc_sun.rotation_degrees = Vector3(-sun_altitude,lerpf(-95.0,95.0,day_progress),0.0)
	npc_sun.light_energy = lerpf(.81,0.0,dark) if phase<NPC_DAY_SECONDS else 0.0
	npc_sun.light_color = Color("#ffc27c").lerp(Color("#fff0d6"),clampf(sun_altitude/40.0,0.0,1.0))
	if is_instance_valid(npc_moon):
		npc_moon.rotation_degrees = Vector3(-moon_altitude,lerpf(85.0,275.0,night_progress),0.0)
		npc_moon.light_energy = .32*dark if phase>=NPC_DAY_SECONDS else 0.0
	npc_environment.ambient_light_energy = lerpf(.52,.23,dark)
	npc_environment.fog_light_color = Color("#98ada0").lerp(Color("#172539"),dark)
	npc_sky.sky_top_color = Color("#43738a").lerp(Color("#071326"),dark)
	npc_sky.sky_horizon_color = Color("#c3c9a1").lerp(Color("#26354b"),dark)

func npc_work_target(npc: CharacterBody3D, camp: Vector3) -> Node3D:
	var best: Node3D
	var best_distance := INF
	for obj in objects.values():
		if not is_instance_valid(obj) or obj.is_queued_for_deletion():
			continue
		var kind := str(obj.get_meta("kind",""))
		if kind in ["log","meat_wolf","wolf_tooth"]:
			if str(obj.get_meta("npc_owner",""))!=str(npc.get_meta("id","")):
				continue
		elif kind=="tomato_crop":
			if not bool(obj.get_meta("ready",false)) or tomato_available(obj)<=0:
				continue
		elif kind=="tomato_plant":
			if tomato_available(obj)<=0:
				continue
		elif kind!="tree":
			continue
		if obj.global_position.distance_to(camp)>NPC_PATROL_RADIUS-1.0 or TERRAIN.is_river(obj.global_position.x,obj.global_position.z):
			continue
		var reserved := false
		for other in villagers:
			if is_instance_valid(other) and other!=npc and str(other.get_meta("work_id",""))==str(obj.get_meta("id","")):
				reserved = true
		if reserved:
			continue
		var d: float = npc.global_position.distance_to(obj.global_position)
		if kind in ["log","meat_wolf","wolf_tooth"]:
			d -= 100.0
		elif kind=="tree" and str(npc.get_meta("id",""))=="Talo":
			d -= 2.0
		elif kind.begins_with("tomato") and str(npc.get_meta("id",""))=="Bruma":
			d -= 2.0
		if d<best_distance:
			best_distance = d
			best = obj
	return best

func npc_finish_work(npc: CharacterBody3D, obj: Node3D) -> void:
	if not is_instance_valid(obj) or obj.is_queued_for_deletion():
		return
	var kind := str(obj.get_meta("kind",""))
	var id := str(obj.get_meta("id",""))
	var pos := obj.global_position
	if kind=="tree":
		var rig := npc.get_node_or_null("Visual/GoblinRig")
		if rig!=null:
			rig.call("play_action","attack")
		obj.set_meta("fall_from",npc.global_position)
		var cuts := int(obj.get_meta("cuts",0))+1
		obj.set_meta("cuts",cuts)
		play_tree_chop_sound(pos+Vector3.UP*.85,WOOD_AXE)
		timber(obj,cuts>=5)
		if net_role=="host":
			net_tree_chopped.rpc(id,cuts,cuts>=5,float(tree_regrowth.get(id,0.0)),npc.global_position)
		if cuts>=5:
			for i in range(3):
				var drop := pos+Vector3((i-1)*.65,0,.39)
				drop.y = ground(drop.x,drop.z)
				store_object("log",drop)
				var entry: Dictionary = placed.back()
				var log_id := str(entry["id"])
				if objects.has(log_id):
					objects[log_id].set_meta("npc_owner",str(npc.get_meta("id","")))
			save_game()
		return
	if kind=="log" and str(obj.get_meta("npc_owner",""))==str(npc.get_meta("id","")):
		remove_object(obj)
		npc.set_meta("carried_wood",int(npc.get_meta("carried_wood",0))+1)
		save_game()
	elif kind in ["meat_wolf","wolf_tooth"] and str(obj.get_meta("npc_owner",""))==str(npc.get_meta("id","")):
		var key := "carried_meat" if kind=="meat_wolf" else "carried_teeth"
		remove_object(obj)
		npc.set_meta(key,int(npc.get_meta(key,0))+1)
		save_game()
	elif kind=="tomato_plant" or (kind=="tomato_crop" and bool(obj.get_meta("ready",false))):
		if take_one_tomato(obj):
			npc.set_meta("carried_tomatoes",int(npc.get_meta("carried_tomatoes",0))+1)
			save_game()

# Depositos dos moradores nao usam o inventario do jogador.
func npc_chest_capacity(id: String, item: int) -> int:
	var capacity := 0
	for cell in normalized_chest_slots(id):
		if int(cell[0])==item or int(cell[0])<0:
			capacity += CHEST_STACK_LIMIT-int(cell[1])
	return capacity

func npc_nearest_chest(npc: CharacterBody3D, camp: Vector3) -> Node3D:
	var best: Node3D
	var nearest := INF
	for obj in objects.values():
		if not is_instance_valid(obj) or obj.is_queued_for_deletion() or obj.get_meta("kind","")!="chest":
			continue
		if obj.global_position.distance_to(camp)>NPC_PATROL_RADIUS-1.0 or absf(obj.global_position.y-ground(obj.global_position.x,obj.global_position.z))>0.8:
			continue
		var id := str(obj.get_meta("id",""))
		if not ((int(npc.get_meta("carried_wood",0))>0 and npc_chest_capacity(id,6)>0) or (int(npc.get_meta("carried_tomatoes",0))>0 and npc_chest_capacity(id,TOMATO_ITEM)>0) or (int(npc.get_meta("carried_meat",0))>0 and npc_chest_capacity(id,3)>0) or (int(npc.get_meta("carried_teeth",0))>0 and npc_chest_capacity(id,WOLF_TOOTH)>0)):
			continue
		var distance: float = npc.global_position.distance_to(obj.global_position)
		if distance<nearest:
			nearest = distance
			best = obj
	return best

func npc_deposit(id: String,item: int,amount: int) -> int:
	var slots := normalized_chest_slots(id)
	var remaining := amount
	for pass_index in range(2):
		for index in range(slots.size()):
			var cell: Array = slots[index]
			if int(cell[0])!=(item if pass_index==0 else -1):
				continue
			var moved := mini(remaining,CHEST_STACK_LIMIT-int(cell[1]))
			if moved>0:
				slots[index] = [item,int(cell[1])+moved]
				remaining -= moved
			if remaining<=0:
				break
		if remaining<=0:
			break
	if remaining<amount:
		chest_storage[id] = slots
		if net_role=="host":
			net_chest_snapshot.rpc(id,slots)
		if open_chest_id==id and not chest_pending:
			show_chest()
	return remaining

func npc_clear_combat_hit(attacker: CharacterBody3D, target: CharacterBody3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(attacker.global_position+Vector3.UP*.55,target.global_position+Vector3.UP*.55,SOLID|TARGET|4,[attacker.get_rid()])
	var contact := get_world_3d().direct_space_state.intersect_ray(query)
	return contact.is_empty() or contact.get("collider",null)==target

func npc_defend(npc: CharacterBody3D, wolf: CharacterBody3D, dt: float) -> Vector3:
	var direction := wolf.global_position-npc.global_position
	direction.y = 0.0
	var distance := direction.length()
	npc.rotation.y = lerp_angle(npc.rotation.y,atan2(direction.x,direction.z),minf(dt*9.0,1.0))
	if distance>1.25:
		return direction.normalized()
	if elapsed>=float(npc.get_meta("defend_at",0.0)) and npc_clear_combat_hit(npc,wolf):
		npc.set_meta("defend_at",elapsed+1.15)
		npc.set_meta("attack_serial",int(npc.get_meta("attack_serial",0))+1)
		var rig := npc.get_node_or_null("Visual/GoblinRig")
		if rig!=null:
			rig.call("play_action","attack")
		var hp := maxi(0,int(wolf.get_meta("hp",5))-1)
		wolf.set_meta("hp",hp)
		if hp<=0:
			var pos := wolf.global_position
			remove_object(wolf)
			store_object("meat_wolf",pos)
			var meat_entry: Dictionary = placed.back()
			objects[str(meat_entry["id"])].set_meta("npc_owner",str(npc.get_meta("id","")))
			if randf()<.5:
				store_object("wolf_tooth",pos+Vector3(.36,0,0))
				var tooth_entry: Dictionary = placed.back()
				objects[str(tooth_entry["id"])].set_meta("npc_owner",str(npc.get_meta("id","")))
			npc.set_meta("work_mode","")
			npc.set_meta("work_id","")
			npc.set_meta("next_work",elapsed)
			npc.set_meta("attacker_id","")
			save_game()
	return Vector3.ZERO

func npc_routine(npc: CharacterBody3D, camp: Vector3, dt: float) -> Vector3:
	var night := npc_is_night()
	var task := str(npc.get_meta("work_mode",""))
	var loot := npc_work_target(npc,camp) if task=="" or task=="warm" else null
	if is_instance_valid(loot) and str(loot.get_meta("kind","")) in ["meat_wolf","wolf_tooth","log"]:
		npc.set_meta("work_id",str(loot.get_meta("id","")))
		npc.set_meta("work_mode","work")
		npc.set_meta("work_deadline",elapsed+20.0)
		task = "work"
	if task=="work":
		var active: Node3D = objects.get(str(npc.get_meta("work_id","")),null)
		if is_instance_valid(active) and str(active.get_meta("kind","")) in ["meat_wolf","wolf_tooth","log"]:
			night = false
	if int(npc.get_meta("carried_meat",0))+int(npc.get_meta("carried_teeth",0))>0:
		night = false
		if task=="warm":
			npc.set_meta("work_mode","")
			task = ""
	if night and task!="warm":
		npc.set_meta("work_id","")
		npc.set_meta("work_mode","warm")
		task = "warm"
	elif not night and task=="warm":
		npc.set_meta("work_mode","")
		task = ""
	if task=="deliver":
		var chest := npc_nearest_chest(npc,camp)
		if chest==null:
			npc.set_meta("work_mode","")
			npc.set_meta("next_work",elapsed+15.0)
			return Vector3.ZERO
		var direction := chest.global_position-npc.global_position
		direction.y = 0.0
		if direction.length()>1.25:
			if npc.is_on_wall():
				npc.set_meta("work_mode","")
				npc.set_meta("next_work",elapsed+15.0)
				return Vector3.ZERO
			return direction.normalized()
		var id := str(chest.get_meta("id",""))
		npc.set_meta("carried_wood",npc_deposit(id,6,int(npc.get_meta("carried_wood",0))))
		npc.set_meta("carried_tomatoes",npc_deposit(id,TOMATO_ITEM,int(npc.get_meta("carried_tomatoes",0))))
		npc.set_meta("carried_meat",npc_deposit(id,3,int(npc.get_meta("carried_meat",0))))
		npc.set_meta("carried_teeth",npc_deposit(id,WOLF_TOOTH,int(npc.get_meta("carried_teeth",0))))
		npc.set_meta("work_mode","")
		npc.set_meta("next_work",elapsed+randf_range(25.0,45.0))
		save_game()
		return Vector3.ZERO
	if task=="warm":
		var side := -1.0 if str(npc.get_meta("id",""))=="Bruma" else 1.0
		var spot := camp+Vector3(side*1.9,0,.8)
		var direction := spot-npc.global_position
		direction.y = 0.0
		if direction.length()>.45:
			return direction.normalized() if not npc.is_on_wall() else Vector3.ZERO
		var face := camp-npc.global_position
		npc.rotation.y = lerp_angle(npc.rotation.y,atan2(face.x,face.z),minf(dt*5.0,1.0))
		return Vector3.ZERO
	if task=="" and elapsed>=float(npc.get_meta("next_work",0.0)):
		if int(npc.get_meta("carried_wood",0))+int(npc.get_meta("carried_tomatoes",0))+int(npc.get_meta("carried_meat",0))+int(npc.get_meta("carried_teeth",0))>0:
			npc.set_meta("work_mode","deliver")
			return Vector3.ZERO
		var target := npc_work_target(npc,camp)
		if target==null:
			npc.set_meta("next_work",elapsed+15.0)
			return Vector3.ZERO
		npc.set_meta("work_id",str(target.get_meta("id","")))
		npc.set_meta("work_mode","work")
		npc.set_meta("work_deadline",elapsed+20.0)
		task = "work"
	if task!="work":
		return Vector3.ZERO
	var obj: Node3D = objects.get(str(npc.get_meta("work_id","")),null)
	if not is_instance_valid(obj) or obj.is_queued_for_deletion() or elapsed>float(npc.get_meta("work_deadline",0.0)) or npc.is_on_wall():
		npc.set_meta("work_mode","")
		npc.set_meta("work_id","")
		npc.set_meta("next_work",elapsed+8.0)
		return Vector3.ZERO
	var direction := obj.global_position-npc.global_position
	direction.y = 0.0
	if direction.length()>1.15:
		return direction.normalized()
	npc.rotation.y = lerp_angle(npc.rotation.y,atan2(direction.x,direction.z),minf(dt*5.0,1.0))
	if elapsed>=float(npc.get_meta("work_hit_at",0.0)):
		npc.set_meta("work_hit_at",elapsed+1.4)
		var kind := str(obj.get_meta("kind",""))
		npc_finish_work(npc,obj)
		if kind!="tree" or not is_instance_valid(obj) or obj.get_meta("kind","")!="tree":
			npc.set_meta("work_mode","")
			npc.set_meta("work_id","")
			npc.set_meta("next_work",elapsed+1.5)
	return Vector3.ZERO

func update_villagers(dt: float) -> void:
	var campfire := get_campfire_center()
	for npc in villagers:
		if not is_instance_valid(npc) or npc.is_queued_for_deletion():
			continue
		var delta_home := campfire-npc.global_position
		delta_home.y = 0.0
		var distance_home := delta_home.length()
		var to_player := player.global_position-npc.global_position
		to_player.y = 0.0
		var distance := to_player.length()
		if distance<3.0 and elapsed>=float(npc.get_meta("next_react",0.0)):
			npc.set_meta("look_until",elapsed+randf_range(.8,1.5))
			npc.set_meta("next_react",elapsed+randf_range(11.0,18.0))
		var attentive := elapsed<float(npc.get_meta("look_until",0.0)) and distance<5.0
		var walking := false
		var heading := Vector3.ZERO
		# Prioridade absoluta: NPC que chega ao limite retorna para perto da fogueira.
		var attacker: CharacterBody3D = objects.get(str(npc.get_meta("attacker_id","")),null) as CharacterBody3D
		if is_instance_valid(attacker) and not attacker.is_queued_for_deletion() and attacker.global_position.distance_to(npc.global_position)<6.0 and elapsed>=float(npc.get_meta("recover_until",0.0)):
			heading = npc_defend(npc,attacker,dt)
			walking = not heading.is_zero_approx()
		elif elapsed<float(npc.get_meta("recover_until",0.0)):
			heading = delta_home.normalized() if distance_home>2.0 else Vector3.ZERO
			walking = not heading.is_zero_approx()
		elif distance_home>NPC_PATROL_RADIUS-.85:
			heading = delta_home.normalized()
			walking = true
			npc.set_meta("ai_state","idle")
			npc.set_meta("ai_until",elapsed+1.0)
		elif npc_is_night() or str(npc.get_meta("work_mode",""))!="" or elapsed>=float(npc.get_meta("next_work",0.0)):
			heading = npc_routine(npc,campfire,dt)
			walking = not heading.is_zero_approx()
		elif attentive:
			if distance>.15:
				# Rosto dos goblins aponta para +Z no modelo local.
				npc.rotation.y = lerp_angle(npc.rotation.y,atan2(to_player.x,to_player.z),minf(dt*5.0,1.0))
		elif npc.get_meta("ai_state","idle")=="walk":
			var target: Vector3 = npc.get_meta("wander_goal",npc.global_position)
			var toward := target-npc.global_position
			toward.y = 0.0
			if toward.length()<.45 or elapsed>float(npc.get_meta("ai_until",0.0)) or npc.is_on_wall():
				npc.set_meta("ai_state","idle")
				npc.set_meta("ai_until",elapsed+randf_range(.6,1.8))
			else:
				heading = toward.normalized()
				walking = true
		elif elapsed>=float(npc.get_meta("ai_until",0.0)):
			choose_goblin_destination(npc)
		if walking:
			npc.rotation.y = lerp_angle(npc.rotation.y,atan2(heading.x,heading.z),minf(dt*6.0,1.0))
		var pace: float = float(npc.get_meta("walk_speed",1.3)) if walking else 0.0
		npc.velocity.x = move_toward(npc.velocity.x,heading.x*pace,dt*7.0)
		npc.velocity.z = move_toward(npc.velocity.z,heading.z*pace,dt*7.0)
		if not npc.is_on_floor():
			npc.velocity.y -= 15.0*dt
		else:
			npc.velocity.y = -0.1
		try_character_step(npc,dt)
		npc.move_and_slide()
		if npc.velocity.y<=0.0:
			npc.apply_floor_snap()
		# O limite é aplicado após a física, mesmo quando há empurrões.
		var displacement := Vector2(npc.global_position.x-campfire.x,npc.global_position.z-campfire.z)
		if displacement.length()>NPC_PATROL_RADIUS:
			var border := displacement.normalized()*(NPC_PATROL_RADIUS-.04)
			npc.global_position = Vector3(campfire.x+border.x,npc.global_position.y,campfire.z+border.y)
			npc.velocity.x = 0.0
			npc.velocity.z = 0.0
		var npc_visual: Node3D = npc.get_node("Visual")
		walk_pose(npc_visual,npc.get_real_velocity(),dt,npc.is_on_floor())
		animate_npc_model(npc_visual,npc.get_real_velocity(),dt,npc.is_on_floor())

func speak_to_goblin(npc: Node3D) -> void:
	if player.global_position.distance_to(npc.global_position)>3.6:
		notice("Aproxime-se para conversar.")
		return
	var kind: String = npc.get_meta("kind","")
	var lines: Array[String] = []
	if kind=="Bruma":
		lines = [
			"Bruma: Os cipós perto das árvores servem para fazer cordas.",
			"Bruma: Com couro e cipó você consegue fabricar uma mochila.",
			"Bruma: Fique de olho nos lobos quando se afastar da clareira.",
			"Bruma: Uma bancada ajuda a montar ferramentas e construções."
		]
	else:
		lines = [
			"Talo: Experimente usar um machado para recolher sua bancada.",
			"Talo: Três gravetos formam uma lança de madeira na bancada.",
			"Talo: As paredes de madeira ajudam a montar um abrigo.",
			"Talo: Há muitas pedras e troncos espalhados pela floresta."
		]
	var count: int = int(npc.get_meta("talk_count",0))
	npc.set_meta("talk_count",count+1)
	npc.set_meta("look_until",elapsed+3.3)
	npc.set_meta("next_react",elapsed+13.0)
	notice(lines[count%lines.size()])

func spawn_starter_cabin() -> void:
	if objects.has(STARTER_CABIN_ID):
		return
	var base_y := ground(STARTER_CABIN_CENTER.x,STARTER_CABIN_CENTER.y)
	for dx in [-2.7,0.0,2.7]:
		for dz in [-2.7,0.0,2.7]:
			base_y = maxf(base_y,ground(STARTER_CABIN_CENTER.x+dx,STARTER_CABIN_CENTER.y+dz))
	spawn_object("hut",STARTER_CABIN_ID,Vector3(STARTER_CABIN_CENTER.x,base_y,STARTER_CABIN_CENTER.y))

func spawn_object(kind: String,id: String, pos: Vector3, parent: Node3D = self, yaw: float = 0.0) -> StaticBody3D:
	var o := StaticBody3D.new()
	o.collision_layer = TARGET
	o.set_meta("kind",kind)
	o.set_meta("id",id)
	parent.add_child(o)
	o.position = pos
	o.rotation.y = yaw
	# Drops devem repousar sobre o terreno na posicao final, inclusive em
	# encostas e ao restaurar partidas antigas ou sincronizar multiplayer.
	if kind in ["meat","meat_wolf","meat_rabbit","hide","foot","wolf_tooth"]:
		var floor_pos: Vector3 = o.global_position
		floor_pos.y = maxf(floor_pos.y,ground(floor_pos.x,floor_pos.z) + 0.008)
		o.global_position = floor_pos
	objects[id] = o
	match kind:
		"tree":
			o.collision_layer |= SOLID
			var visual := Node3D.new()
			visual.name = "Visual"
			o.add_child(visual)
			# Base e raizes SAO AS MESMAS antes e depois de cortar.
			# Nao e criado um outro tronco mais grosso quando vira toco.
			var base := Node3D.new()
			base.name = "BaseTronco"
			visual.add_child(base)
			# Base alargada e raizes afuniladas, ligadas dentro do tronco.
			var wood_geo := preload("res://forest_wood_geometry.gd")
			wood_geo.make_trunk(base,materials["tree_bark"],false)
			wood_geo.make_roots(base,materials["tree_bark"],id)
			var growth := Node3D.new()
			growth.name = "Crescimento"
			visual.add_child(growth)
			# Tronco adulto unico desde o solo ate a copa: elimina a emenda
			# visivel entre dois cilindros sobrepostos no ponto de corte.
			wood_geo.make_trunk(growth,materials["tree_bark"],true)
			# Copas detalhadas, galhos e variacao deterministica por ID.
			# O tronco continua sendo a unica colisao da arvore.
			preload("res://forest_tree_visual.gd").decorate(growth,materials["tree_bark"],id)
			var hanging_vines := Node3D.new()
			hanging_vines.name = "Vinhas"
			growth.add_child(hanging_vines)
			var stump := Node3D.new()
			stump.name = "Toco"
			visual.add_child(stump)
			# So o corte transversal aparece; as raizes e base nunca mudam.
			cylinder(stump,Vector3(0,.527,0),.234,.028,"cut_wood",Color("#c6a273"))
			var sprout := Node3D.new()
			sprout.name = "Broto"
			visual.add_child(sprout)
			# Broto de apenas alguns centimetros, sem haste verde alta.
			preload("res://tree_growth_stages.gd").make_bud(sprout,id)
			# Muda e jovem usam modelos proprios, com base local zero no corte.
			var sapling_stage := Node3D.new()
			sapling_stage.name = "Muda"
			visual.add_child(sapling_stage)
			preload("res://tree_growth_stages.gd").make_stage(sapling_stage,materials["tree_bark"],id,false)
			var young_stage := Node3D.new()
			young_stage.name = "Jovem"
			visual.add_child(young_stage)
			preload("res://tree_growth_stages.gd").make_stage(young_stage,materials["tree_bark"],id,true)
			collider(o,Vector3(.43,2.7,.43),Vector3.UP*1.35)
			update_tree_visual(o)
		"stone","block":
			o.collision_layer |= SOLID
			mesh_part(o,rock_mesh,Vector3.UP*CELL/2,Vector3.ONE,materials["rock"])
			collider(o,Vector3.ONE*CELL,Vector3.UP*CELL/2)
		"log":
			var log_mesh := cylinder(o,Vector3(0,.18,0),.17,.61,"tree_bark",Color.WHITE)
			log_mesh.rotation.z = PI/2
			collider(o,Vector3(.68,.39,.43),Vector3.UP*.19)
		"plank":
			box(o,Vector3(0,.04,0),Vector3(.59,.075,.26),"plank",Color("#ac7749"))
			collider(o,Vector3(.61,.21,.29),Vector3.UP*.10)
		"stick":
			# Galho caido com casca texturizada, nos e madeira quebrada.
			preload("res://forest_fallen_stick.gd").build(o,id)
			collider(o,Vector3(.78,.23,.33),Vector3.UP*.115)
		"chest":
			o.collision_layer |= SOLID
			preload("res://chest_model.gd").build(o)
			collider(o,Vector3(1.05,0.78,0.67),Vector3.UP*0.39)
		"carpentry_bench":
			o.collision_layer |= SOLID
			build_carpentry_bench(o)
		"bench","bench2":
			o.collision_layer |= SOLID
			var advanced_workbench := kind=="bench2"
			preload("res://goblin_workbench_model.gd").build(o,advanced_workbench)
			# A colisao cobre o tampo e o rack, sem bloquear area livre ao redor.
			collider(o,Vector3(1.36,1.34,0.92) if advanced_workbench else Vector3(1.16,0.89,0.80),
				Vector3.UP*(0.67 if advanced_workbench else 0.445))
		"hut":
			o.collision_layer |= SOLID
			preload("res://starter_cabin.gd").build(self,o)
		"Bruma","Talo":
			o.collision_layer |= SOLID
			goblin_npc(o,Color("#9b4b78") if kind=="Bruma" else Color("#866342"), "bruma" if kind=="Bruma" else "talo")
			collider(o,Vector3(.63,1.47,.55),Vector3.UP*.74)
		"fire":
			collider(o,Vector3(.77,.41,.77),Vector3.UP*.205)
			for i in range(9):
				var a := i*TAU/9
				var stone := mesh_part(o,rock_mesh,Vector3(cos(a)*.34,.09,sin(a)*.34),
					Vector3(.30+sin(i*2.)*.045,.23,.27),materials["rock"])
				stone.rotation.y = a
			for i in range(3):
				var a := i*TAU/3
				var wood := cylinder(o,Vector3(cos(a)*.07,.09,sin(a)*.07),.061,.46,"fire_charcoal",Color("#382722"))
				wood.rotation = Vector3(PI*.43,a,0)
			var fire := preload("res://fogueira.gd").new()
			fire.name = "FogoAnimado"
			o.add_child(fire)
		"tomato_plant":
			# Vegetacao rasteira com tomates verdes e maduros; so interativa, sem bloquear caminho.
			preload("res://forest_tomato_plant.gd").build(o,id)
			collider(o,Vector3(1.05,.45,1.05),Vector3.UP*.22)
			update_tomato_fruits(o)
		"tomato_crop":
			var crop_visual := Node3D.new()
			crop_visual.name = "Horta"
			o.add_child(crop_visual)
			preload("res://forest_tomato_plant.gd").build(crop_visual,id)
			collider(o,Vector3(1.05,.45,1.05),Vector3.UP*.22)
			update_tomato_crop(o)
			update_tomato_fruits(o)
		"tomato_seed":
			var seed := SphereMesh.new()
			seed.radius = .075
			seed.height = .060
			mesh_part(o,seed,Vector3.UP*.048,Vector3.ONE,material("tomato_seed",Color("#d1bd83")))
			collider(o,Vector3(.20,.12,.20),Vector3.UP*.06)
		"tomato":
			preload("res://forest_tomato_plant.gd").build(o,id,true)
			collider(o,Vector3(.26,.24,.26),Vector3.UP*.12)
		"vine_bush":
			for i in range(5):
				var a := i*TAU/5.
				var leaf_color := Color("#5e7936") if i%2==0 else Color("#3e6131")
				ball(o,Vector3(cos(a)*.23,.22+sin(a)*.09,sin(a)*.23),Vector3(.51,.38,.50),"vine_leaf_%d" % (i%2),leaf_color)
			make_vine(o,Vector3(0,.28,.39))
			make_vine(o,Vector3(0,.28,-.39))
			collider(o,Vector3(.92,.55,.92),Vector3.UP*.27)
		"vine":
			make_vine(o,Vector3.UP*.14)
			collider(o,Vector3(.55,.25,.30),Vector3.UP*.12)
		"wood_wall","wood_doorway","wood_window":
			o.collision_layer |= SOLID
			build_wood_wall(o,kind)
		"stairs_straight","stairs_l","ladder":
			o.collision_layer |= SOLID
			build_stairs(o,kind)
		"wood_floor":
			o.collision_layer |= SOLID
			build_wood_floor(o)
		"backpack":
			box(o,Vector3(0,.23,0),Vector3(.39,.44,.26),"pack_leather",Color("#815337"))
			box(o,Vector3(0,.37,-.14),Vector3(.39,.12,.035),"pack_flap",Color("#5e3d28"))
			collider(o,Vector3(.42,.47,.32),Vector3.UP*.235)
		"rope":
			var coil := TorusMesh.new()
			coil.inner_radius = .09
			coil.outer_radius = .21
			coil.rings = 16
			coil.ring_segments = 8
			mesh_part(o,coil,Vector3.UP*.07,Vector3.ONE,material("rope",Color("#cfb17e")))
			collider(o,Vector3(.45,.17,.45),Vector3.UP*.08)
		"shovel":
			var tool := Node3D.new()
			o.add_child(tool)
			tool.position = Vector3(0,.12,0)
			tool.rotation.z = PI*.5
			preload("res://wood_shovel_model.gd").build(tool)
			collider(o,Vector3(.45,.25,.75),Vector3.UP*.125)
		"sapling":
			# Muda coletavel parece matinho/galhinho caido, nao arvore plantada.
			# Mantem o mesmo ID e tipo para preservar inventarios e saves.
			var sapling_visual := Node3D.new()
			sapling_visual.name = "MudaRasteira"
			o.add_child(sapling_visual)
			preload("res://forest_ground_sapling.gd").build(sapling_visual,id)
			collider(o,Vector3(.82,.22,.82),Vector3.UP*.11)
		"wood_axe","stone_axe":
			var tool := Node3D.new()
			o.add_child(tool)
			tool.position = Vector3(0,.10,0)
			tool.rotation.x = PI/2
			if kind=="wood_axe":
				preload("res://wood_axe_model.gd").build(tool)
			else:
				cylinder(tool,Vector3.ZERO,.035,.74,"wood",Color("#855b36"))
				make_stone_axe_head(tool)
			collider(o,Vector3(.4,.22,.76),Vector3.UP*.11)
		"wood_pickaxe","stone_pickaxe":
			var pickaxe_visual := Node3D.new()
			o.add_child(pickaxe_visual)
			pickaxe_visual.position = Vector3(0,0.14,0)
			pickaxe_visual.rotation.z = PI*0.5
			preload("res://pickaxe_model.gd").build(pickaxe_visual,kind=="stone_pickaxe")
			collider(o,Vector3(0.8,0.3,0.6),Vector3.UP*0.15)
		"wolf_tooth":
			var fang_mesh := CylinderMesh.new()
			fang_mesh.top_radius = 0.0
			fang_mesh.bottom_radius = 0.085
			fang_mesh.height = 0.32
			fang_mesh.radial_segments = 8
			var fang := mesh_part(o,fang_mesh,Vector3(0,0.16,0),Vector3.ONE,material("wolf_tooth_ivory",Color("#e9dcc2")))
			fang.rotation.z = 0.45
			collider(o,Vector3(.32,.32,.28),Vector3.UP*.16)
		"spiked_club":
			var club := Node3D.new()
			o.add_child(club)
			club.position = Vector3(0,.17,0)
			club.rotation.z = PI*.5
			preload("res://spiked_club_model.gd").build(club)
			collider(o,Vector3(.45,.35,.85),Vector3.UP*.17)
		"meat","meat_wolf","meat_rabbit":
			preload("res://raw_meat_model.gd").build(o,kind=="meat_rabbit")
			# Colisao maior que o corte novo, incluindo a parte do osso.
			collider(o,Vector3(.85,.34,.48),Vector3.UP*.17)
		"hide":
			# Pele pequena e fina: cada vertice acompanha a altura do terreno.
			preload("res://rabbit_pelt_model.gd").new().build(o,Callable(self,"ground"))
			collider(o,Vector3(.65,.10,.62),Vector3.UP*.045)
		_:
			var item_colors := {"meat":Color("#a95842"),"hide":Color("#ad7c59"),"foot":Color("#eadcc1"),"spear":Color("#8e744d")}
			ball(o,Vector3.UP*.14,Vector3(.42,.27,.33),kind,item_colors.get(kind,Color.WHITE))
			collider(o,Vector3(.43,.3,.36),Vector3.UP*.15)
	return o

# Cada segmento de parede tem a largura e a altura de 3 blocos de pedra (CELL).
# Abertura de porta: posições 2 e 5 vazias (base e centro da coluna central).
# Abertura de janela: posição 5 vazia (centro da grade).
func build_wood_wall(parent: StaticBody3D, kind: String) -> void:
	var plank_tone := Color("#a47a50")
	for row in range(3):
		for column in range(3):
			var opening := column==1 and ((kind=="wood_doorway" and row in [0,1]) or (kind=="wood_window" and row==1))
			if opening:
				continue
			if kind=="wood_doorway" and row==2 and column==1:
				# Porta com 2,15 m livres: o antigo cabecalho comecava em
				# 1,70 m e prendia a cabeca do jogador em pisos elevados.
				box(parent,Vector3(0,WALL_SIZE-.20,0),Vector3(CELL*1.015,.40,.15),
					"door_top_board",Color("#a47a50"))
				collider(parent,Vector3(CELL*.99,.40,.18),Vector3(0,WALL_SIZE-.20,0))
				continue
			var x := (float(column)-1.0)*CELL
			var y := (float(row)+0.5)*CELL
			var tone := plank_tone.darkened(.055 if (row+column)%2==0 else .0)
			# Duas tábuas horizontais por bloco, com junta de madeira antiga.
			for slat in range(2):
				var dy := (-.25 if slat==0 else .25)*CELL
				box(parent,Vector3(x,y+dy,0),Vector3(CELL*1.015,CELL*.51,.15),
					"wall_board_%d_%d" % [row,column],tone)
			box(parent,Vector3(x+CELL*.33,y,.083),Vector3(.025,CELL*.92,.018),
				"wall_grain",Color("#6f4a2f"))
			collider(parent,Vector3(CELL*.99,CELL*.99,.18),Vector3(x,y,0))
	# Caixilho da abertura: madeira visível, sem fechar o buraco.
	if kind!="wood_wall":
		var window := kind=="wood_window"
		var low := CELL if window else 0.0
		var high := WALL_SIZE-.40 if kind=="wood_doorway" else CELL*2.0
		var jamb_height := high-low
		for side in [-1.0,1.0]:
			box(parent,Vector3(side*CELL*.5,low+jamb_height*.5,.105),
				Vector3(.075,jamb_height,.065),"wall_frame",Color("#60402a"))
		if window:
			for edge in [CELL,2.0*CELL]:
				box(parent,Vector3(0,edge,.105),Vector3(CELL,.075,.07),
					"wall_frame",Color("#60402a"))
		else:
			box(parent,Vector3(0,high,.105),Vector3(CELL,.095,.075),
				"wall_frame",Color("#60402a"))
	# A base de cada parede acompanha o relevo. Em saves antigos,
	# pilares sustentam as partes que antes ficavam suspensas.
	add_wall_foundations(parent)
	if kind=="wood_doorway":
		build_door_transitions(parent)

func build_carpentry_bench(parent: StaticBody3D) -> void:
	# Mesa robusta com tampo de tabuas, prateleira, morsa e serrote.
	for x in [-.64,.64]:
		for z in [-.32,.32]:
			box(parent,Vector3(float(x),.48,float(z)),Vector3(.14,.96,.14),"carpentry_leg",Color("#805431"))
	for i in range(5):
		box(parent,Vector3(0,.99,(float(i)-2.0)*.17),Vector3(1.58,.12,.165),"carpentry_top_%d" % i,Color("#b18a5b").darkened(float(i%3)*.06))
	box(parent,Vector3(0,.27,0),Vector3(1.39,.10,.62),"carpentry_shelf",Color("#95653d"))
	for z in [-.32,.32]:
		box(parent,Vector3(0,.54,float(z)),Vector3(1.36,.13,.11),"carpentry_brace",Color("#77502e"))
	for x in [-.66,-.40]:
		box(parent,Vector3(float(x),1.11,.39),Vector3(.14,.17,.24),"carpentry_vise",Color("#68462b"))
	var screw := cylinder(parent,Vector3(-.53,1.08,.51),.027,.38,"carpentry_iron",Color("#60636a"))
	screw.rotation.z = PI*.5
	box(parent,Vector3(.29,1.065,-.09),Vector3(.52,.025,.17),"carpentry_saw_blade",Color("#91969a"))
	for i in range(10):
		box(parent,Vector3(.06+float(i)*.046,1.068,.005),Vector3(.026,.027,.032),"carpentry_saw_tooth",Color("#70767a"))
	box(parent,Vector3(.61,1.085,-.09),Vector3(.15,.055,.18),"carpentry_saw_handle",Color("#704726"))
	var hammer := box(parent,Vector3(.10,1.075,.21),Vector3(.31,.045,.045),"carpentry_hammer_handle",Color("#885a35"))
	hammer.rotation.y = .30
	box(parent,Vector3(.24,1.09,.17),Vector3(.10,.07,.15),"carpentry_hammer_head",Color("#5b6064"))
	for i in range(3):
		box(parent,Vector3(.15,.37+float(i)*.05,-.03),Vector3(.86,.045,.24),"carpentry_stock",Color("#ba9261"))
	collider(parent,Vector3(1.58,1.07,.86),Vector3.UP*.535)

func stair_board(parent: StaticBody3D, at: Vector3, size: Vector3, solid: bool = true) -> void:
	box(parent,at,size,"stair_rustic_wood",Color("#9d7045"))
	if solid:
		collider(parent,size,at)

func build_stairs(parent: StaticBody3D, kind: String) -> void:
	var rise := WALL_SIZE/12.0
	if kind=="ladder":
		for x in [-.38,.38]:
			stair_board(parent,Vector3(float(x),WALL_SIZE*.5,0),Vector3(.10,WALL_SIZE+.15,.12),false)
		for i in range(11):
			stair_board(parent,Vector3(0,.15+float(i)*.23,0),Vector3(.83,.065,.12),false)
		# A escada vertical e detectada por proximidade, sem bloquear o corpo.
		collider(parent,Vector3(.86,WALL_SIZE,.08),Vector3(0,WALL_SIZE*.5,-.08))
		parent.collision_layer = TARGET
		return
	for i in range(12):
		var height := float(i+1)*rise
		var at := Vector3(0,height-.055,-float(i)*.255)
		var size := Vector3(1.0,.11,.26)
		if kind=="stairs_l" and i>=6:
			at = Vector3(float(i-5)*.255,height-.055,-1.275)
			size = Vector3(.26,.11,1.0)
		if kind=="stairs_l" and i==5:
			size = Vector3(1.0,.11,1.0)
		stair_board(parent,at,size)
		for side in [-1.0,1.0]:
			var offset := Vector3(float(side)*.43,0,0) if kind=="stairs_straight" or i<6 else Vector3(0,0,float(side)*.43)
			stair_board(parent,at+offset+Vector3.DOWN*.13,Vector3(.12,.25,.26),false)

func build_wood_floor(parent: StaticBody3D) -> void:
	# Base continua impede que apareca grama entre placas e sob as juntas.
	# A mesma peca funciona como piso no terreo e laje/teto nos andares.
	var base := box(parent,Vector3(0,-.005,0),Vector3(WALL_SIZE+.035,.14,WALL_SIZE+.035),
		"floor_solid",Color("#86623e"))
	base.name = "PainelContinuo"
	for row in range(3):
		var z := (float(row)-1.0)*CELL
		box(parent,Vector3(0,.084,z),Vector3(WALL_SIZE+.035,.038,CELL-.015),
			"floor_planks_%d" % row,Color("#b58a57").darkened(.045*float(row%2)))
		for column in range(3):
			var x := (float(column)-1.0)*CELL
			box(parent,Vector3(x,.108,z+CELL*.34),Vector3(CELL*.68,.012,.016),
				"floor_seam",Color("#684328"))
	for x in [-WALL_SIZE*.39,0.0,WALL_SIZE*.39]:
		box(parent,Vector3(x,-.15,0),Vector3(.14,.19,WALL_SIZE+.03),
			"floor_joist",Color("#704c31"))
	collider(parent,Vector3(WALL_SIZE+.025,.22,WALL_SIZE+.025),Vector3(0,.005,0))


func add_wall_foundations(parent: StaticBody3D) -> void:
	# Compatibilidade com paredes ja construidas: nao deslocar o save,
	# preencher com pilares os vaos deixados pelo terreno irregular.
	# Paredes nos pavimentos superiores sao apoiadas pelo piso, nao por estacas.
	for x in [-WALL_SIZE*.45,-WALL_SIZE*.15,WALL_SIZE*.15,WALL_SIZE*.45]:
		var world := parent.to_global(Vector3(x,0,0))
		var gap := parent.global_position.y - ground(world.x,world.z)
		if gap <= .13 or gap > WALL_SIZE*.92:
			continue
		var post := box(parent,Vector3(x,-gap*.5,0),Vector3(.17,gap+.11,.18),
			"wall_foundation",Color("#79563b"))
		post.rotation.y = 0.0
		# Volume fisico abaixo da parede para impedir atravessar as estacas.
		collider(parent,Vector3(.17,gap+.11,.18),Vector3(x,-gap*.5,0))


func floor_height_near_door(door: StaticBody3D) -> float:
	# Prioriza a altura dos paineis ja construidos no mesmo comodo,
	# inclusive saves antigos que nao guardavam o campo level.
	var top := door.global_position.y + .09
	var best := WALL_SIZE*1.15
	for entry in placed:
		if str(entry.get("kind",""))!="wood_floor" or int(entry.get("level",0))!=0:
			continue
		var p: Array = entry["p"]
		var center := Vector2(float(p[0]),float(p[2]))
		var distance := center.distance_to(Vector2(door.global_position.x,door.global_position.z))
		if distance<best:
			best = distance
			top = float(p[1]) + .12
	return top


func build_door_transitions(door: StaticBody3D) -> void:
	for part in door.get_children():
		if part.name.begins_with("RampaPorta") or part.name.begins_with("ColisaoRampaPorta") or part.name.begins_with("LimiarPorta"):
			if part is CollisionShape3D:
				part.set_deferred("disabled",true)
			part.queue_free()

func refresh_door_transitions(at: Vector3) -> void:
	for obj in objects.values():
		if not is_instance_valid(obj) or not (obj is StaticBody3D):
			continue
		if str(obj.get_meta("kind",""))!="wood_doorway":
			continue
		if Vector2(obj.global_position.x-at.x,obj.global_position.z-at.z).length()>WALL_SIZE*2.6:
			continue
		build_door_transitions(obj)


func make_vine(parent: Node3D, offset: Vector3) -> void:
	for i in range(4):
		var stem := cylinder(parent,offset+Vector3((i-1.5)*.11,sin(i*1.12)*.08,0),
			.022,.18,"vine_stem",Color("#a6aa59"))
		stem.rotation.z = 1.0+sin(i*1.5)*.72

# Profile rings place the cheekbones, temples and jaw in a single smooth mesh.
func goblin_head() -> ArrayMesh:
	if sculpt_head:
		return sculpt_head
	var rings := [
		Vector4(.952,.006,.011,.040),Vector4(.967,.081,.095,.041),
		Vector4(.999,.140,.132,.039),Vector4(1.053,.182,.161,.036),
		Vector4(1.118,.216,.182,.025),Vector4(1.187,.229,.188,.013),
		Vector4(1.254,.223,.180,.002),Vector4(1.320,.207,.163,-.012),
		Vector4(1.382,.171,.135,-.022),Vector4(1.427,.112,.095,-.026),
		Vector4(1.451,.006,.009,-.030)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SECTIONS := 64
	for row in range(rings.size()-1):
		for i in range(SECTIONS):
			for id in [0,1,2,1,3,2]:
				var profile: Vector4 = rings[row+id/2]
				var angle := TAU*float(i+id%2)/SECTIONS
				var x := cos(angle)*profile.y
				var front := maxf(0.,sin(angle))
				var cheek := exp(-pow((absf(x)-.133)/.066,2)-pow((profile.x-1.122)/.047,2))
				var socket := exp(-pow((absf(x)-.105)/.066,2)-pow((profile.x-1.180)/.052,2))
				var jaw := exp(-pow(x/.139,2)-pow((profile.x-1.013)/.036,2))
				var z := profile.w+sin(angle)*profile.z+pow(front,3)*(.032*cheek-.032*socket+.023*jaw)
				surface.add_vertex(Vector3(x,profile.x,z))
	surface.generate_normals()
	sculpt_head = surface.commit()
	return sculpt_head

func goblin_ear(o: Node3D, side: float, skin: Color) -> void:
	var points := [
		Vector3(.170,1.268,.071),Vector3(.294,1.314,.044),
		Vector3(.507,1.440,-.005),Vector3(.457,1.342,.015),
		Vector3(.377,1.174,.056),Vector3(.302,1.113,.083),
		Vector3(.216,1.121,.096)]
	var bowl := Vector3(.319,1.251,.026)
	var rim := SurfaceTool.new()
	var inset := SurfaceTool.new()
	rim.begin(Mesh.PRIMITIVE_TRIANGLES)
	inset.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size()):
		var a: Vector3 = points[i]
		var b: Vector3 = points[(i+1)%points.size()]
		var inner_a := bowl.lerp(a,.73)
		var inner_b := bowl.lerp(b,.73)
		for raw in [a,inner_b,b,a,inner_a,inner_b]:
			rim.add_vertex(Vector3(raw.x*side,raw.y,raw.z))
		for raw in [inner_a,bowl,inner_b]:
			inset.add_vertex(Vector3(raw.x*side,raw.y,raw.z))
	rim.generate_normals()
	inset.generate_normals()
	var outer := material("goblin_ear_"+skin.to_html(),skin.darkened(.08))
	var inner := material("goblin_ear_inner",Color("#98634d"))
	outer.cull_mode = BaseMaterial3D.CULL_DISABLED
	inner.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_part(o,rim.commit(),Vector3.ZERO,Vector3.ONE,outer)
	mesh_part(o,inset.commit(),Vector3.ZERO,Vector3.ONE,inner)

func sculpt_part(o: Node3D, pos: Vector3, size: Vector3, key: String, color: Color, tilt := 0.0) -> MeshInstance3D:
	var part := mesh_part(o,sculpt_sphere,pos,size,material(key,color))
	part.rotation.z = tilt
	return part

func limb_pivot(parent: Node3D, at: Vector3) -> Node3D:
	var pivot := Node3D.new()
	parent.add_child(pivot)
	pivot.position = at
	return pivot

func move_parts_to_limb(parent: Node3D, pivot: Node3D, start: int) -> void:
	while parent.get_child_count()>start:
		var part := parent.get_child(start) as Node3D
		var local := part.position-pivot.position
		part.reparent(pivot,false)
		part.position = local

func walk_pose(model: Node3D, velocity: Vector3, dt: float, grounded := true) -> void:
	if not model.has_meta("gait"):
		return
	var speed := minf(Vector2(velocity.x,velocity.z).length(),8.)
	var blend := move_toward(float(model.get_meta("gait_weight",0.0)),clampf(speed/3.5,0,1) if grounded else 0.,dt*6.)
	var phase := fposmod(float(model.get_meta("gait_phase",0.0))+speed*dt*4.8,TAU)
	model.set_meta("gait_weight",blend)
	model.set_meta("gait_phase",phase)
	var limbs: Array = model.get_meta("gait")
	var quadruped := bool(model.get_meta("quadruped",false))
	var local := model.global_basis.inverse()*velocity
	var facing := clampf(local.z/maxf(speed,.1),-1,1)
	var lateral := clampf(local.x/maxf(speed,.1),-1,1)
	for i in range(limbs.size()):
		var pivot: Node3D = limbs[i]
		var opposite := i%2==1 if quadruped else i>=2
		var stride := sin(phase+(PI if opposite else 0.))
		var strength := (.43+speed*.037)*blend
		if quadruped:
			pivot.rotation.x = stride*strength
		else:
			pivot.rotation.x = stride*strength*facing*(-.68 if i%2==0 else 1.)
			pivot.rotation.z = -stride*strength*lateral*.42
			var rest: Vector3 = pivot.get_meta("rest")
			pivot.position.y = rest.y
			if i%2==1:
				pivot.position.y += maxf(0.,cos(phase+(PI if i%4==3 else 0.)))*.046*blend

# Mantem IA, colisoes, inventario, multiplayer e saves independentes da aparencia.
# Skirmisher: modelo nativo do Godot, 24 ossos e animacoes incluidas no asset.
func goblin_npc(o: Node3D, _garment: Color, role: String = "player") -> void:
	# Todas as entidades continuam com a mesma logica; apenas o modelo e seu
	# controlador visual passam a usar os 24 ossos nativos do Skirmisher.
	var controller: Node3D = NPC_RIG_SCRIPT.new()
	controller.name = "GoblinRig"
	o.add_child(controller)
	controller.call("set_variant", role)
	if not bool(controller.call("install")):
		push_error("Falha ao carregar modelo Skirmisher no jogo.")
		controller.queue_free()
		return
	o.set_meta("modelo_goblin_npc", true) # Compatibilidade dos metadados antigos.
	o.set_meta("modelo_skirmisher", true)


func animate_npc_model(visual: Node3D, velocity: Vector3, dt: float, grounded: bool) -> void:
	var controller := visual.get_node_or_null("GoblinRig")
	if controller != null:
		controller.call("animate",velocity,dt,grounded)


func goblin(o: Node3D, garment: Color, protagonist := false) -> void:
	var guardian := garment==Color("#784d88")
	var bruma := garment==Color("#9b4b78")
	var skin := Color("#8c9a53") if protagonist else Color("#77706a") if guardian else Color("#889352") if bruma else Color("#65794b")
	var moss := skin.lightened(.09)
	var tone := skin.to_html()
	var leather := Color("#503325")
	var trim := Color("#8c5836")
	var gold := Color("#bc873e")
	var cloth := garment.darkened(.37)
	var key := garment.to_html()
	var head_material: Material = material("sculpt_skin_"+tone,skin)
	if protagonist:
		if not protagonist_face:
			protagonist_face = ShaderMaterial.new()
			protagonist_face.shader = preload("res://protagonista_rosto.gdshader")
			protagonist_face.set_shader_parameter("portrait",preload("res://protagonista.jpg"))
		head_material = protagonist_face
	mesh_part(o,goblin_head(),Vector3.ZERO,Vector3.ONE,head_material)
	sculpt_part(o,Vector3(0,.936,-.026),Vector3(.207,.249,.186),"sculpt_skin_"+tone,skin)
	sculpt_part(o,Vector3(0,.704,-.006),Vector3(.441,.460,.289),"sculpt_skin_"+tone,skin)
	sculpt_part(o,Vector3(0,.505,-.012),Vector3(.413,.263,.276),"goblin_waist",leather)
	sculpt_part(o,Vector3(0,.523,.006),Vector3(.469,.127,.324),"goblin_belt",trim)
	var limbs: Array[Node3D] = []
	for side in [-1.0,1.0]:
		goblin_ear(o,side,skin)
		if not protagonist:
			sculpt_part(o,Vector3(side*.102,1.185,.172),Vector3(.171,.156,.105),"goblin_socket_"+tone,skin.darkened(.27))
			sculpt_part(o,Vector3(side*.101,1.185,.184),Vector3(.122,.091,.093),"goblin_ivory",Color("#e4c89a"))
			sculpt_part(o,Vector3(side*.096,1.185,.226),Vector3(.062,.070,.024),"goblin_iris",Color("#959832"))
			sculpt_part(o,Vector3(side*.096,1.186,.236),Vector3(.033,.047,.011),"goblin_pupil",Color("#211911"))
			sculpt_part(o,Vector3(side*.087,1.199,.243),Vector3(.013,.014,.006),"goblin_glint",Color("#fff1d0"))
			sculpt_part(o,Vector3(side*.101,1.234,.187),Vector3(.167,.056,.075),"goblin_brow_"+tone,moss,side*.30)
			sculpt_part(o,Vector3(side*.116,1.119,.162),Vector3(.126,.064,.063),"goblin_cheek_"+tone,moss,side*.22)
		var arm := limb_pivot(o,Vector3(side*.211,.814,-.01))
		var leg := limb_pivot(o,Vector3(side*.114,.418,-.01))
		limbs.append(arm)
		limbs.append(leg)
		arm.set_meta("rest",arm.position)
		leg.set_meta("rest",leg.position)
		var start := o.get_child_count()
		sculpt_part(o,Vector3(side*.222,.779,-.012),Vector3(.136,.210,.151),"sculpt_skin_"+tone,skin,side*.41)
		sculpt_part(o,Vector3(side*.284,.655,-.003),Vector3(.113,.204,.119),"sculpt_skin_"+tone,skin,side*.42)
		sculpt_part(o,Vector3(side*.325,.544,.012),Vector3(.102,.064,.116),"goblin_brass",gold,side*.35)
		sculpt_part(o,Vector3(side*.344,.470,.019),Vector3(.114,.147,.101),"sculpt_skin_"+tone,skin,side*.22)
		for finger in range(3):
			sculpt_part(o,Vector3(side*(.319+finger*.027),.414+finger*.009,.041),Vector3(.032,.089,.043),"sculpt_skin_"+tone,skin,side*.23)
		move_parts_to_limb(o,arm,start)
		start = o.get_child_count()
		sculpt_part(o,Vector3(side*.113,.306,-.011),Vector3(.151,.274,.167),"sculpt_skin_"+tone,skin)
		sculpt_part(o,Vector3(side*.125,.143,-.013),Vector3(.178,.235,.192),"goblin_boot",leather)
		sculpt_part(o,Vector3(side*.128,.061,.066),Vector3(.195,.120,.318),"goblin_boot_toe",trim)
		sculpt_part(o,Vector3(side*.124,.211,-.012),Vector3(.181,.058,.198),"goblin_boot_toe",trim)
		move_parts_to_limb(o,leg,start)
		sculpt_part(o,Vector3(side*.117,.829,.131),Vector3(.075,.202,.055),"goblin_strap",trim,-side*.72)
		for flap in range(2):
			sculpt_part(o,Vector3(side*(.047+flap*.101),.407+flap*.023,.132-flap*.024),Vector3(.116,.201,.052),"goblin_cloth_"+key,cloth,-side*.15)
	# Opposite sides are half a cycle apart; each arm counters its same-side leg.
	o.set_meta("gait",limbs)
	if not protagonist:
		sculpt_part(o,Vector3(0,1.120,.209),Vector3(.111,.131,.167),"goblin_nose",Color("#9d8556"),-.10)
		for side in [-1.0,1.0]:
			sculpt_part(o,Vector3(side*.044,1.104,.225),Vector3(.071,.052,.078),"goblin_nose",Color("#9d8556"))
			sculpt_part(o,Vector3(side*.038,1.088,.246),Vector3(.028,.012,.017),"goblin_mouth",Color("#413c2b"),side*.14)
			sculpt_part(o,Vector3(side*.063,1.043,.179),Vector3(.095,.020,.038),"goblin_mouth",Color("#413c2b"),side*.16)
		sculpt_part(o,Vector3(0,1.034,.192),Vector3(.083,.019,.034),"goblin_mouth",Color("#413c2b"))
		sculpt_part(o,Vector3(0,1.019,.183),Vector3(.143,.028,.041),"goblin_cheek_"+tone,moss)
	for seam in range(9):
		var x := (seam-4)*.034
		sculpt_part(o,Vector3(x,.543,.154-absf(x)*.31),Vector3(.014,.005,.009),"goblin_thread",Color("#b4875b"),.32)
	if protagonist:
		protagonist_details(o)
	elif not bruma and not guardian:
		sculpt_part(o,Vector3(-.174,1.115,.116),Vector3(.079,.11,.058),"talo_beard",Color("#483529"),-.18)
		sculpt_part(o,Vector3(0,1.020,.154),Vector3(.186,.091,.088),"talo_beard",Color("#483529"))

	sculpt_part(o,Vector3(0,.755,.167),Vector3(.080,.080,.036),"goblin_brass",gold)
	sculpt_part(o,Vector3(0,.523,.163),Vector3(.131,.101,.047),"goblin_brass",gold)
	sculpt_part(o,Vector3(0,.523,.188),Vector3(.072,.056,.019),"goblin_boot",leather)
	if bruma:
		var hair := Color("#352719")
		var braid_highlight := Color("#513827")
		sculpt_part(o,Vector3(0,1.398,-.097),Vector3(.357,.156,.253),"bruma_hair",hair)
		sculpt_part(o,Vector3(-.077,1.382,.027),Vector3(.195,.084,.188),"bruma_hair",hair,-.30)
		sculpt_part(o,Vector3(.084,1.400,.020),Vector3(.188,.082,.173),"bruma_braid_light",braid_highlight,.32)
		for side in [-1.0,1.0]:
			for link in range(5):
				var alt := -1.0 if link%2 else 1.0
				var dx: float = side*(.193+.011*link+.013*alt)
				sculpt_part(o,Vector3(dx,1.355-link*.070,-.111+.042*link),
					Vector3(.095-link*.007,.117,.098-link*.007),
					"bruma_hair" if alt<0 else "bruma_braid_light",
					hair if alt<0 else braid_highlight,alt*.33)
			sculpt_part(o,Vector3(side*.237,1.040,.076),Vector3(.061,.031,.063),"goblin_brass",gold)
			var ring := TorusMesh.new()
			ring.inner_radius = .020
			ring.outer_radius = .031
			ring.rings = 16
			ring.ring_segments = 8
			var earring := mesh_part(o,ring,Vector3(side*.312,1.114,.091),Vector3.ONE,material("goblin_brass",gold))
			earring.rotation.x = PI/2
		sculpt_part(o,Vector3(0,.748,.193),Vector3(.039,.048,.018),"bruma_gem",Color("#783d64"))

func protagonist_details(o: Node3D) -> void:
	var horn := CylinderMesh.new()
	horn.top_radius = .002
	horn.bottom_radius = .046
	horn.height = .115
	horn.radial_segments = 18
	mesh_part(o,horn,Vector3(0,1.496,-.027),Vector3.ONE,material("goblin_brass",Color("#c9a759")))
	for side in [-1.0,1.0]:
		var pad := box(o,Vector3(side*.187,.883,.107),Vector3(.12,.105,.065),"goblin_strap",Color("#8c5836"))
		pad.rotation.z = -side*.37
		sculpt_part(o,Vector3(side*.183,.886,.147),Vector3(.040,.040,.019),"goblin_brass",Color("#bc873e"))
	var bag := sculpt_part(o,Vector3(-.172,.451,.135),Vector3(.135,.173,.115),"goblin_boot",Color("#503325"),-.17)
	sculpt_part(o,bag.position+Vector3(0,.047,.05),Vector3(.117,.073,.052),"goblin_belt",Color("#8c5836"),-.17)
	sculpt_part(o,bag.position+Vector3(0,.030,.075),Vector3(.026,.026,.014),"goblin_brass",Color("#bc873e"))

func creature(kind: String, id: String, at: Vector3, parent: Node3D) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.collision_layer = TARGET
	body.collision_mask = SOLID
	body.floor_snap_length = .38
	parent.add_child(body)
	# Os mapas antigos criavam o guardiao em y=0 mesmo com o solo mais alto.
	# Posicione todos os animais e inimigos na altitude real da malha fisica.
	# A pequena folga deixa o corpo assentar sem atravessar o HeightMap.
	body.position = Vector3(at.x,ground(at.x,at.z)+.06,at.z)
	body.set_meta("kind",kind)
	body.set_meta("id",id)
	objects[id] = body
	body.set_meta("hp",2 if kind=="rabbit" else 5 if kind=="wolf" else 9)
	mobs.append(body)
	var visual := Node3D.new()
	visual.name = "Visual"
	body.add_child(visual)
	if kind=="guardian":
		goblin_npc(visual,Color("#784d88"),"guardiao")
		collider(body,Vector3(.8,1.5,.6),Vector3.UP*.75)
		return body
	var rabbit := kind=="rabbit"
	visual.scale = Vector3.ONE*(.64 if rabbit else 1.13)
	animal_model(visual,rabbit)
	collider(body,Vector3(.53,.80,1.26)*visual.scale,Vector3(0,.40,-.09)*visual.scale)
	return body

func wolf_face(o: Node3D, key: String, center: Vector3, dimensions: Vector3, fur: Color) -> void:
	if not wolf_face_materials.has(key):
		var skin := ShaderMaterial.new()
		skin.shader = preload("res://lobo_rosto.gdshader")
		skin.set_shader_parameter("reference_photo",preload("res://lobo-referencia.jpg"))
		skin.set_shader_parameter("part_center",center)
		skin.set_shader_parameter("part_size",dimensions)
		skin.set_shader_parameter("fur",fur)
		wolf_face_materials[key] = skin
	mesh_part(o,sculpt_sphere,center,dimensions,wolf_face_materials[key])

func wolf_armor(o: Node3D, side: float) -> void:
	var leather := Color("#64392d")
	var trim := Color("#96603d")
	var metal := Color("#c89748")
	sculpt_part(o,Vector3(side*.190,.529,-.221),Vector3(.244,.233,.293),"goblin_belt",trim,-side*.41)
	sculpt_part(o,Vector3(side*.197,.553,-.225),Vector3(.213,.193,.252),"goblin_boot",leather,-side*.41)
	sculpt_part(o,Vector3(side*.127,.386,-.408),Vector3(.084,.255,.071),"goblin_strap",trim,-side*.69)
	sculpt_part(o,Vector3(side*.242,.320,.104),Vector3(.092,.174,.184),"goblin_boot",leather)
	sculpt_part(o,Vector3(side*.273,.355,.099),Vector3(.048,.101,.166),"goblin_belt",trim)
	sculpt_part(o,Vector3(side*.292,.330,.104),Vector3(.021,.034,.038),"goblin_brass",metal)
	for j in range(3):
		sculpt_part(o,Vector3(side*(.234+j*.021),.491+j*.029,-.348+j*.054),
			Vector3(.029,.033,.022),"goblin_brass",metal)

func animal_model(o: Node3D, rabbit: bool) -> void:
	var fur := Color("#a47a50") if rabbit else Color("#545565")
	var shade := Color("#795238") if rabbit else Color("#353846")
	var cream := Color("#e3c6a1") if rabbit else Color("#bdb4a7")
	var prefix := "rabbit_" if rabbit else "wolf_"
	sculpt_part(o,Vector3(0,.37,.08),Vector3(.51,.52,.87),prefix+"fur",fur)
	sculpt_part(o,Vector3(0,.315,-.21),Vector3(.40,.42,.37),prefix+"cream",cream)
	if rabbit:
		sculpt_part(o,Vector3(0,.49,-.36),Vector3(.44,.43,.43),prefix+"fur",fur)
		sculpt_part(o,Vector3(0,.375,-.53),Vector3(.29,.16,.24 if rabbit else .39),prefix+"cream",cream)
		sculpt_part(o,Vector3(0,.441,-.661 if rabbit else -.742),Vector3(.10 if rabbit else .15,.071,.079),prefix+"nose",Color("#8f514e") if rabbit else Color("#262329"))
		sculpt_part(o,Vector3(0,.35,-.58),Vector3(.188,.033,.15),prefix+"dark",shade)
	else:
		wolf_face(o,"head",Vector3(0,.535,-.379),Vector3(.475,.454,.44),fur)
		wolf_face(o,"snout",Vector3(0,.421,-.551),Vector3(.316,.231,.348),cream)
		for j in range(5):
			var offset := float(j-2)
			sculpt_part(o,Vector3(offset*.071,.676+(.05-absf(offset)*.019),-.328),
				Vector3(.118,.229,.163),"wolf_fur",fur,offset*-.30)
	var limbs: Array[Node3D] = []
	for side in [-1.0,1.0]:
		var back := limb_pivot(o,Vector3(side*.15,.30,.28))
		var front := limb_pivot(o,Vector3(side*.156,.26,-.27))
		limbs.append(back)
		limbs.append(front)
		var start := o.get_child_count()
		sculpt_part(o,Vector3(side*.15,.19,.29),Vector3(.24 if rabbit else .165,.34,.31 if rabbit else .18),prefix+"fur",fur,side*.20)
		sculpt_part(o,Vector3(side*.166,.045,.22),Vector3(.142,.087,.27 if rabbit else .18),prefix+"dark",shade)
		if not rabbit:
			sculpt_part(o,Vector3(side*.16,.123,.218),Vector3(.147,.089,.135),"goblin_belt",Color("#96603d"))
			sculpt_part(o,Vector3(side*.161,.119,.218-.064),Vector3(.032,.032,.019),"goblin_brass",Color("#c89748"))
		move_parts_to_limb(o,back,start)
		start = o.get_child_count()
		sculpt_part(o,Vector3(side*.156,.097,-.26),Vector3(.108,.21,.113),prefix+"dark",shade)
		sculpt_part(o,Vector3(side*.155,.043,-.317),Vector3(.139,.083,.20),prefix+"cream",cream)
		if not rabbit:
			sculpt_part(o,Vector3(side*.16,.123,-.275),Vector3(.147,.089,.135),"goblin_belt",Color("#96603d"))
			sculpt_part(o,Vector3(side*.161,.119,-.275-.064),Vector3(.032,.032,.019),"goblin_brass",Color("#c89748"))
		move_parts_to_limb(o,front,start)
		if rabbit:
			sculpt_part(o,Vector3(side*.125,.54,-.514),Vector3(.157,.142,.096),prefix+"dark",shade)
			sculpt_part(o,Vector3(side*.125,.537,-.555),Vector3(.100,.096,.052),prefix+"iris",Color("#65392b") if rabbit else Color("#cf9b4e"))
			sculpt_part(o,Vector3(side*.119,.539,-.580),Vector3(.047,.061,.021),"fauna_pupil",Color("#211a21"))
			sculpt_part(o,Vector3(side*.110,.555,-.592),Vector3(.019,.020,.010),"fauna_glint",Color("#fff4dc"))
		if rabbit:
			sculpt_part(o,Vector3(side*.137,.737,-.30),Vector3(.104,.343,.112),prefix+"fur",fur,-side*.24)
			sculpt_part(o,Vector3(side*.146,.756,-.347),Vector3(.057,.256,.034),"rabbit_inner",Color("#be8179"),-side*.24)
			sculpt_part(o,Vector3(side*.099,.418,-.603),Vector3(.118,.098,.122),prefix+"cream",cream)
		else:
			var pointed := CylinderMesh.new()
			pointed.top_radius = .005
			pointed.bottom_radius = .093
			pointed.height = .229
			pointed.radial_segments = 10
			var ear := mesh_part(o,pointed,Vector3(side*.153,.733,-.305),Vector3(1,1,.74),material(prefix+"dark",shade))
			ear.rotation.z = -side*.28
			sculpt_part(o,Vector3(side*.157,.705,-.359),Vector3(.089,.131,.043),"wolf_inner",Color("#806e72"),-side*.27)
			for tuft in range(4):
				sculpt_part(o,Vector3(side*(.18+tuft*.011),.505-tuft*.047,-.432+tuft*.028),
					Vector3(.194,.093,.204),"wolf_cream",cream,side*(.27+tuft*.15))
			wolf_armor(o,side)
	if not rabbit:
		sculpt_part(o,Vector3(0,.333,-.405),Vector3(.131,.132,.036),"goblin_brass",Color("#c89748"))
		sculpt_part(o,Vector3(0,.333,-.427),Vector3(.089,.089,.019),"goblin_boot",Color("#64392d"))
		sculpt_part(o,Vector3(0,.333,-.439),Vector3(.039,.049,.013),"goblin_brass",Color("#c89748"))
	o.set_meta("gait",[limbs[0],limbs[1],limbs[3],limbs[2]])
	o.set_meta("quadruped",true)
	if rabbit:
		sculpt_part(o,Vector3(0,.374,.493),Vector3(.233,.239,.233),prefix+"cream",cream)
	else:
		var tail := sculpt_part(o,Vector3(0,.315,.595),Vector3(.231,.244,.56),prefix+"fur",fur)
		tail.rotation.x = -.4

func impact(pos: Vector3, normal: Vector3, wood: bool) -> void:
	var effect := Node3D.new()
	add_child(effect)
	effect.global_position = pos+normal*.035
	var tones := [Color("#b77a46"),Color("#e9bd7a"),Color("#765031")] if wood else [Color("#fff3c9"),Color("#d99158"),Color("#f8bd7d")]
	var tween := effect.create_tween().set_parallel(true)
	for i in range(9):
		var size := randf_range(.020,.049)
		var chip := box(effect,Vector3.ZERO,Vector3(size*.7,size*.6,size*2.2),"impact_%s_%s" % [wood,i%3],tones[i%3])
		var scatter := Vector3(randf_range(-.5,.5),randf_range(.08,.62),randf_range(-.5,.5))+normal*.30
		var duration := randf_range(.17,.35)
		tween.tween_property(chip,"position",scatter,duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(chip,"rotation",Vector3(randf()*6,randf()*6,randf()*6),duration)
		tween.tween_property(chip,"scale",Vector3.ZERO,duration).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(effect.queue_free)

var cached_tree_chop_sound: AudioStreamWAV

func play_tree_chop_sound(pos: Vector3, tool: int) -> void:
	# Um golpe seco de madeira por acerto, com variacao leve entre golpes.
	if cached_tree_chop_sound == null:
		cached_tree_chop_sound = preload("res://tree_chop_sound.gd").make_stream()
	var sound := AudioStreamPlayer3D.new()
	sound.name = "SomMachadoNaMadeira"
	add_child(sound)
	sound.global_position = pos
	sound.stream = cached_tree_chop_sound
	sound.unit_size = 8.0
	sound.max_distance = 34.0
	sound.volume_db = -1.5
	sound.pitch_scale = randf_range(0.92,1.08) * (1.07 if tool == STONE_AXE else 0.97)
	sound.finished.connect(sound.queue_free)
	sound.play()

func play_tree_fall_sound(pos: Vector3) -> void:
	# Som original de madeira rangendo + impacto + folhas.
	# Stream WAV procedimental: dispensamos arquivos externos/licencas de audio.
	var player_sound := AudioStreamPlayer3D.new()
	player_sound.name = "SomQuedaArvore"
	add_child(player_sound)
	player_sound.global_position = pos + Vector3.UP
	player_sound.stream = preload("res://tree_fall_sound.gd").make_stream()
	player_sound.unit_size = 7.0
	player_sound.max_distance = 45.0
	player_sound.volume_db = -3.0
	player_sound.finished.connect(player_sound.queue_free)
	player_sound.play()


func stagger(body: Node3D, world_direction: Vector3) -> void:
	var visual := body.get_node("Visual") as Node3D
	if visual.has_meta("reaction"):
		visual.get_meta("reaction").kill()
	var direction := body.global_basis.inverse()*world_direction
	visual.position = Vector3.ZERO
	visual.rotation.x = 0
	var tween := visual.create_tween()
	visual.set_meta("reaction",tween)
	tween.tween_property(visual,"position",direction*.17+Vector3.UP*.045,.06)
	tween.parallel().tween_property(visual,"rotation:x",-.19,.06)
	tween.tween_property(visual,"position",Vector3.ZERO,.18).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(visual,"rotation:x",0.,.18)

func update_tree_visual(tree: Node3D) -> void:
	if not is_instance_valid(tree):
		return
	var id: String = str(tree.get_meta("id",""))
	var growth := tree.get_node("Visual/Crescimento") as Node3D
	var stump_trunk := tree.get_node("Visual/BaseTronco/TroncoToco") as MeshInstance3D
	var stump := tree.get_node("Visual/Toco") as Node3D
	var sprout := tree.get_node("Visual/Broto") as Node3D
	var sapling_stage := tree.get_node("Visual/Muda") as Node3D
	var young_stage := tree.get_node("Visual/Jovem") as Node3D
	var collision := tree.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null or not (collision.shape is BoxShape3D):
		push_error("Colisao ausente ou invalida na arvore: " + id)
		return
	var shape := collision.shape as BoxShape3D
	# Esconde sempre todos os modelos antes de escolher a fase.
	growth.visible = false
	sprout.visible = false
	sapling_stage.visible = false
	young_stage.visible = false
	if not tree_regrowth.has(id):
		tree.set_meta("kind","tree")
		tree.collision_layer = SOLID|TARGET
		stump.visible = false
		stump_trunk.visible = false
		growth.visible = true
		update_tree_vines(tree)
		growth.position = Vector3.ZERO
		growth.scale = Vector3.ONE
		sprout.position = Vector3.ZERO
		sprout.scale = Vector3.ONE
		shape.size = Vector3(.43,2.7,.43)
		collision.position.y = 1.35
		return
	var age := maxf(0.0,float(Time.get_unix_time_from_system())-float(tree_regrowth[id]))
	var progress := clampf((age-TREE_BUD_DELAY)/TREE_GROW_SECONDS,0.0,1.0)
	if progress >= 1.0:
		tree_regrowth.erase(id)
		update_tree_visual(tree)
		return
	tree.set_meta("kind","stump")
	tree.collision_layer = SOLID|TARGET
	# Ate a fase jovem o toco continua com o mesmo tronco e raizes.
	stump_trunk.visible = progress < 0.75
	var height := 0.54
	if progress < 0.12:
		stump.visible = true
	elif progress < 0.25:
		stump.visible = true
		sprout.visible = true
		var t := inverse_lerp(0.12,0.25,progress)
		var factor := lerpf(0.55,1.0,t)
		sprout.scale = Vector3.ONE*factor
		# O novo broto nasce na origem local; sua base permanece em Y=.52.
		sprout.position = Vector3.UP*.505
		height = .505+.22*factor
	elif progress < 0.45:
		stump.visible = false
		sapling_stage.visible = true
		var t := inverse_lerp(0.25,0.45,progress)
		var factor := lerpf(0.70,1.0,t)
		sapling_stage.scale = Vector3.ONE*factor
		# A base do toco termina em Y=.44. Embutir o tronco jovem
		# 8 cm dentro dele elimina a abertura entre as duas malhas.
		sapling_stage.position = Vector3.UP*.36
		height = .36+0.67*factor
	elif progress < 0.75:
		stump.visible = false
		young_stage.visible = true
		var t := inverse_lerp(0.45,0.75,progress)
		var factor := lerpf(0.67,1.0,t)
		young_stage.scale = Vector3.ONE*factor
		young_stage.position = Vector3.UP*.36
		height = .36+1.37*factor
	else:
		stump.visible = false
		growth.visible = true
		var t := inverse_lerp(0.75,1.0,progress)
		var factor := lerpf(0.72,1.0,t)
		growth.scale = Vector3.ONE*factor
		growth.position = Vector3.ZERO
		height = 2.20*factor
	# Sem colisor de folhas: apenas o tronco bloqueia o jogador e os NPCs.
	shape.size = Vector3(.43,height,.43)
	collision.position.y = height*.5

# As vinhas sao objetos fisicos individuais e colhiveis, presos ao Crescimento.
# Posicoes por ID garantem a mesma copa e os mesmos modelos no multiplayer.
func update_tree_vines(tree: Node3D) -> void:
	if not is_instance_valid(tree):
		return
	var growth := tree.get_node_or_null("Visual/Crescimento") as Node3D
	if growth == null:
		return
	var holder := growth.get_node_or_null("Vinhas") as Node3D
	if holder == null:
		return
	var id := str(tree.get_meta("id",""))
	if tree_regrowth.has(id):
		for child in holder.get_children():
			child.queue_free()
		return
	if not tree_vines.has(id) and net_role!="client":
		tree_vines[id] = {"count":0,"next":Time.get_unix_time_from_system()+VINE_INTERVAL_SECONDS}
	var state: Dictionary = tree_vines.get(id,{})
	var count := int(state.get("count",0))
	if holder.get_child_count()==count:
		return
	for child in holder.get_children():
		child.free()
	for i in range(count):
		var rng := RandomNumberGenerator.new()
		rng.seed = absi(hash(id+":vinha:"+str(i)))
		var angle := rng.randf_range(0.0,TAU)
		var radial := rng.randf_range(0.40,0.78)
		var vine := StaticBody3D.new()
		vine.name = "Cipo_%d" % i
		vine.collision_layer = TARGET
		vine.collision_mask = 0
		vine.set_meta("kind","tree_vine")
		vine.set_meta("tree_id",id)
		vine.position = Vector3(cos(angle)*radial,rng.randf_range(2.20,2.62),sin(angle)*radial)
		holder.add_child(vine)
		preload("res://forest_hanging_vine.gd").build(vine,hash(id+":vinha:"+str(i)))
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.35
		collision.shape = shape
		collision.position = Vector3(0,-0.52,0)
		vine.add_child(collision)

func update_mature_tree_vines() -> void:
	if net_role=="client":
		return
	var now := Time.get_unix_time_from_system()
	for id in objects.keys():
		var tree: Node3D = objects[id]
		if not is_instance_valid(tree) or str(tree.get_meta("kind",""))!="tree":
			continue
		if not tree_vines.has(id):
			tree_vines[id] = {"count":0,"next":now+VINE_INTERVAL_SECONDS}
		var state: Dictionary = tree_vines[id]
		# Saves antigos guardavam espera de 20 min: limitar espera restante a 5 min.
		if float(state.get("next",now+VINE_INTERVAL_SECONDS)) > now+VINE_INTERVAL_SECONDS:
			state["next"] = now+VINE_INTERVAL_SECONDS
			tree_vines[id] = state
		var maximum := 1 + (absi(hash(id))%2)
		if int(state.get("count",0))<maximum and now>=float(state.get("next",now+VINE_INTERVAL_SECONDS)):
			state["count"] = int(state.get("count",0))+1
			state["next"] = now+VINE_INTERVAL_SECONDS
			tree_vines[id] = state
			update_tree_vines(tree)
			if net_role=="host":
				net_tree_vines_changed.rpc(id,state)
			save_game()

func harvest_tree_vine(vine: Node3D) -> void:
	var id := str(vine.get_meta("tree_id",""))
	if net_role=="client":
		if net_world_ready:
			net_request_harvest_tree_vine.rpc_id(1,id)
		return
	if not tree_vines.has(id) or not objects.has(id):
		return
	var tree: Node3D = objects[id]
	if not is_instance_valid(tree) or str(tree.get_meta("kind",""))!="tree":
		return
	var state: Dictionary = tree_vines[id]
	if int(state.get("count",0))<=0:
		return
	state["count"] = int(state["count"])-1
	state["next"] = Time.get_unix_time_from_system()+VINE_INTERVAL_SECONDS
	tree_vines[id] = state
	stock[VINE] += 1
	item_received(VINE)
	sync_hotbar()
	update_tree_vines(tree)
	if net_role=="host":
		net_tree_vines_changed.rpc(id,state)
	save_game()
	notice("Voce colheu um cipo da copa.")

@rpc("any_peer","call_remote","reliable")
func net_request_harvest_tree_vine(id: String) -> void:
	if net_role!="host" or not objects.has(id) or not tree_vines.has(id):
		return
	var peer := multiplayer.get_remote_sender_id()
	var avatar: Node3D = remotes.get(peer,null)
	var tree: Node3D = objects[id]
	if not is_instance_valid(avatar) or not is_instance_valid(tree):
		return
	if not remote_can_interact(peer,tree.global_position,4.2):
		return
	var state: Dictionary = tree_vines[id]
	if int(state.get("count",0))<1 or str(tree.get_meta("kind",""))!="tree":
		return
	state["count"] = int(state["count"])-1
	state["next"] = Time.get_unix_time_from_system()+VINE_INTERVAL_SECONDS
	tree_vines[id] = state
	update_tree_vines(tree)
	net_tree_vines_changed.rpc(id,state)
	# O inventario pertence ao jogador solicitante; entregar so ao cliente.
	net_tree_vine_reward.rpc_id(peer)
	save_game()

@rpc("authority","call_remote","reliable")
func net_tree_vine_reward() -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1:
		return
	stock[VINE] += 1
	item_received(VINE)
	sync_hotbar()
	notice("Voce colheu um cipo da copa.")

@rpc("authority","call_remote","reliable")
func net_tree_vines_changed(id: String, state: Dictionary) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1:
		return
	tree_vines[id] = state.duplicate(true)
	if objects.has(id):
		update_tree_vines(objects[id])

func update_regrowing_trees() -> void:
	for id: String in tree_regrowth.keys():
		var tree_age := float(Time.get_unix_time_from_system())-float(tree_regrowth[id])
		if tree_age >= TREE_BUD_DELAY+TREE_GROW_SECONDS:
			tree_regrowth.erase(id)
		if objects.has(id):
			var tree: Node3D = objects[id]
			if is_instance_valid(tree):
				update_tree_visual(tree)
	update_mature_tree_vines()

func timber(tree: Node3D, fell: bool) -> void:
	var visual := tree.get_node("Visual") as Node3D
	if visual.has_meta("reaction"):
		visual.get_meta("reaction").kill()
	var attacker_pos: Vector3 = tree.get_meta("fall_from",player.global_position)
	if tree.has_meta("fall_from"):
		tree.remove_meta("fall_from")
	var direction := tree.global_position-attacker_pos
	var axis := Vector3(direction.z,0,-direction.x).normalized()
	if axis.is_zero_approx():
		axis = Vector3.RIGHT
	if fell:
		# O tronco cai e some, mas a arvore original permanece no mapa como toco.
		var original := visual.get_node("Crescimento") as Node3D
		# A arvore gira a partir do ponto de corte na base, e nao do meio
		# do tronco. A extremidade cortada fica encostada no toco.
		var fall_pivot := Node3D.new()
		fall_pivot.name = "QuedaArvore"
		add_child(fall_pivot)
		fall_pivot.global_position = tree.global_position + Vector3.UP * 0.53
		var falling := original.duplicate() as Node3D
		# A copa derrubada nao deve conservar vinhas colhiveis nem colisores extras.
		var old_vines := falling.get_node_or_null("Vinhas")
		if old_vines != null:
			old_vines.free()
		fall_pivot.add_child(falling)
		falling.position = Vector3(0.0, -0.53, 0.0)
		falling.rotation = original.rotation
		play_tree_fall_sound(tree.global_position)
		var id: String = str(tree.get_meta("id",""))
		tree_regrowth[id] = Time.get_unix_time_from_system()
		tree_vines.erase(id)
		tree.set_meta("cuts",0)
		update_tree_visual(tree)
		var fall := fall_pivot.create_tween()
		fall.tween_property(fall_pivot,"quaternion",Quaternion(axis,PI * 0.49),0.78).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fall.tween_interval(1.20)
		fall.tween_property(fall_pivot,"scale",Vector3.ONE * 0.02,0.32).set_trans(Tween.TRANS_SINE)
		fall.tween_callback(fall_pivot.queue_free)
	else:
		var shake := visual.create_tween()
		visual.set_meta("reaction",shake)
		shake.tween_property(visual,"quaternion",Quaternion(axis,.11),.08)
		shake.tween_property(visual,"quaternion",Quaternion(axis,-.055),.10)
		shake.tween_property(visual,"quaternion",Quaternion.IDENTITY,.14)

func make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	layer.add_child(crosshair)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud = Label.new()
	layer.add_child(hud)
	hud.position = Vector2(15,12)
	hud.add_theme_font_size_override("font_size",18)
	hint = Label.new()
	layer.add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -33
	var bottom := CenterContainer.new()
	layer.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -155
	bottom.offset_bottom = -34
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stack := VBoxContainer.new()
	bottom.add_child(stack)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var meters := HBoxContainer.new()
	stack.add_child(meters)
	meters.alignment = BoxContainer.ALIGNMENT_CENTER
	meters.add_theme_constant_override("separation",18)
	life_text = Label.new()
	stamina_text = Label.new()
	life_bar = make_meter(meters,life_text,Color("#cf574d"))
	stamina_bar = make_meter(meters,stamina_text,Color("#d4b85e"))
	hotbar = HBoxContainer.new()
	hotbar.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(hotbar)
	hotbar.add_theme_constant_override("separation",5)
	slot_idle = hotbar_style(Color("#222921e6"),Color("#77735c"),1)
	slot_active = hotbar_style(Color("#443825f1"),Color("#edc47a"),2)
	for i in range(HOTBAR_SIZE):
		var frame := PanelContainer.new()
		frame.custom_minimum_size = Vector2(66,70)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hotbar.add_child(frame)
		hotbar_frames.append(frame)
		var content := VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("separation",1)
		frame.add_child(content)
		var row := HBoxContainer.new()
		content.add_child(row)
		var key := Label.new()
		key.text = str(i+1)
		key.add_theme_font_size_override("font_size",11)
		key.modulate = Color("#dccda9")
		row.add_child(key)
		var count := Label.new()
		count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.add_theme_font_size_override("font_size",14)
		row.add_child(count)
		hotbar_counts.append(count)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(30,30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		content.add_child(icon)
		hotbar_icons.append(icon)
		var item := Label.new()
		item.text = ITEMS[i]
		item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item.add_theme_font_size_override("font_size",12)
		content.add_child(item)
		hotbar_slots.append(item)
		var durability_bar := ProgressBar.new()
		durability_bar.custom_minimum_size = Vector2(54,5)
		durability_bar.show_percentage = false
		durability_bar.max_value = 100
		durability_bar.visible = false
		content.add_child(durability_bar)
		hotbar_durability_bars.append(durability_bar)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel = PanelContainer.new()
	layer.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -245
	panel.offset_right = 245
	panel.offset_top = -190
	panel.offset_bottom = 170
	var panel_scroll := ScrollContainer.new()
	panel_scroll.name = "PanelScroll"
	panel_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(panel_scroll)
	menu = VBoxContainer.new()
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_scroll.add_child(menu)
	get_viewport().size_changed.connect(func(): center_panel.call_deferred())
	gameplay_overlays = [crosshair,hud,hint,bottom]
	medieval_menu = MEDIEVAL_MENU.new()
	layer.add_child(medieval_menu)
	medieval_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	medieval_menu.hide()
	panel.hide()

func hotbar_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(7)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.shadow_color = Color("#80000000")
	style.shadow_size = 3
	return style

func make_meter(container: HBoxContainer, caption: Label, color: Color) -> ProgressBar:
	var column := VBoxContainer.new()
	container.add_child(column)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(158,8)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#242921")
	background.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill",fill)
	bar.add_theme_stylebox_override("background",background)
	column.add_child(bar)
	return bar

func sync_inventory_slots() -> void:
	# Um slot de inventário guarda uma pilha de um tipo de item.
	# Tipos sem unidades são liberados; a ordem escolhida pelo jogador permanece.
	for index in range(inventory_slots.size()):
		var item: int = inventory_slots[index]
		if item>=ITEMS.size() or (item>=0 and stock[item]-(1 if item==BACKPACK_ITEM and backpack_equipped else 0)<=0 and reserve[item]<=0):
			inventory_slots[index] = -1
	for item in range(ITEMS.size()):
		if (stock[item]-(1 if item==BACKPACK_ITEM and backpack_equipped else 0)>0 or reserve[item]>0) and not inventory_slots.has(item):
			var free := inventory_slots.find(-1)
			if free>=0:
				inventory_slots[free] = item

func sync_tool_durability() -> void:
	for kind in TOOL_MAX_DURABILITY:
		var item: int = int(kind)
		var count: int = maxi(0,stock[item])+maxi(0,reserve[item])
		for slot in backpack_slots:
			if slot.x==item:
				count += slot.y
		for chest_id in chest_storage:
			for stored in normalized_chest_slots(str(chest_id)):
				if int(stored[0])==item:
					count += int(stored[1])
		var values: Array = tool_durability.get(str(item),[])
		while values.size()<count:
			values.append(int(TOOL_MAX_DURABILITY[item]))
		while values.size()>count:
			values.pop_back()
		tool_durability[str(item)] = values

func tool_remaining(item: int) -> int:
	if not TOOL_MAX_DURABILITY.has(item):
		return -1
	sync_tool_durability()
	var values: Array = tool_durability.get(str(item),[])
	return int(values[0]) if not values.is_empty() else 0

func use_tool(item: int) -> void:
	if not TOOL_MAX_DURABILITY.has(item) or stock[item]<=0:
		return
	sync_tool_durability()
	var values: Array = tool_durability[str(item)]
	if values.is_empty():
		return
	values[0] = maxi(0,int(values[0])-1)
	if int(values[0])==0:
		values.pop_front()
		stock[item] -= 1
		sync_hotbar()
		notice("%s quebrou! Fabrique outra ferramenta." % ITEMS[item])
	tool_durability[str(item)] = values
	save_game()

func item_received(item: int) -> void:
	# Coleta/fabricação: primeiro espaço vazio dos 9 atalhos, mesmo com ordem manual.
	if item<0 or item>=ITEMS.size():
		return
	sync_inventory_slots()
	if stock[item]>0 and not bar_items.has(item):
		var free := bar_items.find(-1)
		if free>=0:
			bar_items[free] = item

func sync_hotbar() -> void:
	for i in range(bar_items.size()):
		var item: int = bar_items[i]
		if item>=0 and stock[item]<=0:
			bar_items[i] = -1
	if not hotbar_manual:
		for item in range(ITEMS.size()):
			if stock[item]>0 and not bar_items.has(item):
				var slot := bar_items.find(-1)
				if slot>=0:
					bar_items[slot] = item

func update_player_hud() -> void:
	sync_hotbar()
	life_bar.value = health
	var showing_breath := player_in_water() or breath < 99.99
	stamina_bar.value = breath if showing_breath else stamina
	var meter_fill := stamina_bar.get_theme_stylebox("fill") as StyleBoxFlat
	meter_fill.bg_color = Color("#328fcb") if showing_breath else Color("#d4b85e")
	life_text.text = "Vida %d/100" % health
	if showing_breath:
		stamina_text.text = "Fôlego (água) %d/100" % roundi(breath) if player_head_submerged() else "Recuperando ar %d/100" % roundi(breath) if breath < 99.99 else "Fôlego (água) 100/100"
	else:
		stamina_text.text = "Recuperando o fôlego" if exhausted else "Fôlego %d/100" % roundi(stamina)
	for i in range(HOTBAR_SIZE):
		var active := i==selected
		var style := slot_active if active else slot_idle
		if hotbar_frames[i].get_theme_stylebox("panel")!=style:
			hotbar_frames[i].add_theme_stylebox_override("panel",style)
		var item: int = bar_items[i]
		hotbar_icons[i].texture = ITEM_ICONS[item] if item>=0 else null
		hotbar_slots[i].text = ""
		hotbar_frames[i].tooltip_text = (ITEMS[item] + (" · Durabilidade %d/%d" % [tool_remaining(item),int(TOOL_MAX_DURABILITY[item])] if TOOL_MAX_DURABILITY.has(item) else "")) if item>=0 else "Atalho vazio"
		hotbar_counts[i].text = "×%d" % stock[item] if item>=0 else ""
		hotbar_durability_bars[i].visible = item>=0 and TOOL_MAX_DURABILITY.has(item)
		if item>=0 and TOOL_MAX_DURABILITY.has(item):
			hotbar_durability_bars[i].value = 100.0*tool_remaining(item)/float(TOOL_MAX_DURABILITY[item])
		hotbar_slots[i].modulate = Color("#ffe29c") if active else Color.WHITE

func sprint_step(wants_run: bool,dt: float) -> bool:
	recovery_delay = maxf(0.0,recovery_delay-dt)
	if wants_run and not exhausted:
		stamina = maxf(0.,stamina-dt*18.)
		recovery_delay = .70
		if stamina>0.0:
			return true
		exhausted = true
	elif recovery_delay<=0.0:
		stamina = minf(100.,stamina+dt*23.)
		if stamina>=32.0:
			exhausted = false
	return false

func player_in_water() -> bool:
	# So conta como entrada na agua quando ela alcanca parte do corpo.
	return TERRAIN.is_river(player.position.x,player.position.z) and player.position.y + 0.65 < TERRAIN.WATER_LEVEL

func player_head_submerged() -> bool:
	# A respiracao so diminui com a cabeca abaixo da superficie.
	return TERRAIN.is_river(player.position.x,player.position.z) and player.position.y + eye_height < TERRAIN.WATER_LEVEL - 0.08

func update_breath(dt: float) -> void:
	if player_head_submerged():
		breath = maxf(0.0,breath - dt * 100.0 / BREATH_UNDERWATER_SECONDS)
		breath_recovery_delay = BREATH_RECOVERY_PAUSE
		if breath <= 0.0:
			drowning_damage_clock += dt
			if drowning_damage_clock >= 1.0:
				drowning_damage_clock -= 1.0
				health = maxi(0,health - 10)
				if health <= 0:
					respawn()
	else:
		drowning_damage_clock = 0.0
		breath_recovery_delay = maxf(0.0,breath_recovery_delay - dt)
		if breath_recovery_delay <= 0.0:
			breath = minf(100.0,breath + dt * 100.0 / BREATH_RECOVERY_SECONDS)

func clear_menu() -> void:
	center_panel.call_deferred()
	for child in menu.get_children():
		menu.remove_child(child)
		child.queue_free()

func center_panel() -> void:
	if not is_instance_valid(panel):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var available := Vector2(maxf(320.0,viewport_size.x-24.0),maxf(240.0,viewport_size.y-24.0))
	if inventory:
		# Tamanho logico da interface completa; escala uniforme e rolagem interna.
		var desired := Vector2(1290,710)
		var fit := minf(1.0,minf(available.x/desired.x,available.y/desired.y))
		panel.scale = Vector2.ONE*fit
		panel.offset_left = -desired.x/2.0
		panel.offset_right = desired.x/2.0
		panel.offset_top = -desired.y/2.0
		panel.offset_bottom = desired.y/2.0
		panel.pivot_offset = desired/2.0
	else:
		var minimum := menu.get_combined_minimum_size()+Vector2(40,40)
		var desired := Vector2(maxf(490.0,minimum.x),maxf(360.0,minimum.y))
		var fit := minf(1.0,minf(available.x/desired.x,available.y/desired.y))
		panel.scale = Vector2.ONE*fit
		panel.offset_left = -desired.x/2.0
		panel.offset_right = desired.x/2.0
		panel.offset_top = -desired.y/2.0
		panel.offset_bottom = desired.y/2.0
		panel.pivot_offset = desired/2.0

func label(text_value: String) -> void:
	var l := Label.new()
	l.text = text_value
	menu.add_child(l)

func button(title: String, callback: Callable, use_craft_style: bool = false) -> void:
	var b := Button.new()
	b.text = title
	b.pressed.connect(callback)
	if use_craft_style:
		style_craft_button(b)
	menu.add_child(b)

func set_gameplay_overlays_visible(visible_now: bool) -> void:
	for overlay in gameplay_overlays:
		if is_instance_valid(overlay):
			overlay.visible = visible_now

func _refresh_update_status(current_status: Dictionary) -> void:
	if is_instance_valid(medieval_menu):
		medieval_menu.refresh_update_state(current_status)

func _install_verified_update() -> void:
	# O jogo fecha apenas depois de baixar, validar e salvar o progresso.
	if not save_game():
		updater.abort_install("Não foi possível salvar o progresso. Atualização cancelada.")
		return
	if updater.launch_installer():
		get_tree().quit()


func show_menu(starting_page: String = "home") -> void:
	moving = false
	inventory = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.hide()
	set_gameplay_overlays_visible(false)
	var ips := lan_local_ipv4_addresses()
	var message := net_session_message
	if message.is_empty():
		message = feedback
	medieval_menu.rebuild({
		"role": net_role,
		"connected": net_connected,
		"world_ready": net_world_ready,
		"ip": net_address,
		"last_connected_ip": last_connected_lan_ip,
		"host_ips": ", ".join(ips) if ips.size()>0 else "verifique em ipconfig",
		"players": multiplayer.get_peers().size()+1,
		"message": message,
		"worlds": world_storage.list_worlds(),
		"active_world_id": world_storage.active_id,
		"active_world_name": world_storage.active_name(),
		"updater": updater.get_state()
	}, {
		"play": Callable(self,"begin"),
		"host": Callable(self,"host_game"),
		"join": Callable(self,"join_game"),
		"disconnect": Callable(self,"disconnect_and_show_menu"),
		"lab": Callable(self,"open_goblin_skin_test"),
		"create_world": Callable(self,"create_named_world"),
		"rename_world": Callable(self,"rename_named_world"),
		"select_world": Callable(self,"select_named_world"),
		"check_update": Callable(updater,"check_updates"),
		"install_update": Callable(updater,"download_and_install"),
		"quit": func(): save_game(); get_tree().quit()
	},starting_page)
	medieval_menu.show()
	address = null


func world_action_available() -> bool:
	if net_role=="solo":
		return true
	net_session_message = ""
	notice("Desconecte-se da partida LAN antes de trocar de mundo.")
	show_menu("worlds")
	return false

func world_action_error() -> void:
	net_session_message = ""
	notice(world_storage.last_error if not world_storage.last_error.is_empty() else "Não foi possível atualizar o mundo.")
	show_menu("worlds")

func create_named_world(name: String) -> void:
	if not world_action_available():
		return
	if not save_game():
		net_session_message = ""
		notice("Não foi possível salvar o mundo atual. Nenhum mundo foi trocado.")
		show_menu("worlds")
		return
	var previous_id: String = str(world_storage.active_id)
	if not world_storage.create_world(name):
		world_action_error()
		return
	var new_id: String = str(world_storage.active_id)
	if get_tree().reload_current_scene()!=OK:
		world_storage.select_world(previous_id)
		net_session_message = ""
		notice("Falha ao abrir o novo mundo: %s." % new_id)
		show_menu("worlds")

func rename_named_world(id: String, name: String) -> void:
	if not world_action_available():
		return
	if not world_storage.rename_world(id,name):
		world_action_error()
		return
	net_session_message = ""
	notice("Nome do mundo atualizado.")
	show_menu("worlds")

func select_named_world(id: String) -> void:
	if not world_action_available():
		return
	if id==world_storage.active_id:
		begin()
		return
	if not save_game():
		net_session_message = ""
		notice("Não foi possível salvar o mundo atual. Nenhum mundo foi trocado.")
		show_menu("worlds")
		return
	var previous_id: String = str(world_storage.active_id)
	if not world_storage.select_world(id):
		world_action_error()
		return
	get_tree().set_meta(PLAY_AFTER_WORLD_CHANGE,id)
	if get_tree().reload_current_scene()!=OK:
		get_tree().remove_meta(PLAY_AFTER_WORLD_CHANGE)
		world_storage.select_world(previous_id)
		net_session_message = ""
		notice("Falha ao carregar o mundo selecionado.")
		show_menu("worlds")


func open_goblin_skin_test() -> void:
	# So entra no laboratorio em modo solo; nao interfere no servidor ou no save.
	if net_role!="solo":
		notice("A comparacao de skin esta disponivel somente fora de partidas LAN.")
		return
	save_game()
	get_tree().change_scene_to_packed(GOBLIN_SKIN_TEST_SCENE)


func begin() -> void:
	close_chest_visual()
	if net_role=="client" and not net_world_ready:
		notice("Aguarde o anfitrião enviar o mundo antes de começar.")
		show_menu()
		return
	panel.hide()
	if is_instance_valid(medieval_menu):
		medieval_menu.hide()
	set_gameplay_overlays_visible(true)
	inventory = false
	moving = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func open_craft(mode: String) -> void:
	inventory = true
	craft_mode = mode
	craft_material = -1
	craft_cells.resize(4 if mode=="basic" else (25 if mode=="carpentry" else 9))
	craft_cells.fill(Vector2i(-1,0))
	show_inventory()

func apply_player_equipment() -> void:
	if not is_instance_valid(player_model):
		return
	var rig_node := player_model.get_node_or_null("GoblinRig")
	if rig_node != null:
		rig_node.call("set_equipment",sword_equipped,shield_equipped)


func toggle_player_equipment(which: String) -> void:
	if which=="sword":
		sword_equipped = not sword_equipped
	elif which=="shield":
		shield_equipped = not shield_equipped
	else:
		return
	apply_player_equipment()
	save_game()
	show_inventory()


func player_equipment_mask() -> int:
	return (1 if sword_equipped else 0) | (2 if shield_equipped else 0)


func show_inventory() -> void:
	if is_instance_valid(medieval_menu):
		medieval_menu.hide()
	set_gameplay_overlays_visible(true)
	sync_inventory_slots()
	if not inventory:
		craft_mode = "basic"
		craft_cells.resize(4)
		craft_cells.fill(Vector2i(-1,0))
	inventory = true
	moving = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var surface := craft_relief(Color("#30291f"),Color("#a88652"),true)
	surface.shadow_size = 7
	surface.content_margin_left = 18
	surface.content_margin_right = 18
	surface.content_margin_top = 14
	surface.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel",surface)
	panel.show()
	clear_menu()
	var title := Label.new()
	title.text = "Inventário e fabricação"
	var station_label := Label.new()
	station_label.text = "Bancada de marcenaria · 5 × 5" if craft_mode=="carpentry" else ("Bancada de trabalho · Nível %d" % station_level if craft_mode=="station" else "Inventário e fabricação básica")
	station_label.modulate = Color("#cfb791")
	menu.add_child(station_label)
	title.add_theme_font_size_override("font_size",23)
	title.modulate = Color("#ffe29c")
	menu.add_child(title)
	# Tres paineis: personagem/equipamento, itens, e fabricacao.
	# Largura ampliada para nao sobrepor grade e resultado do craft.
	# A centralizacao responsiva cuida do tamanho final apos montar a interface.
	center_panel.call_deferred()
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",10)
	menu.add_child(columns)
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	var equipment_side := VBoxContainer.new()
	equipment_side.custom_minimum_size = Vector2(350,390)
	columns.add_child(equipment_side)
	var equipment_title := Label.new()
	equipment_title.text = "Equipamento do personagem"
	equipment_title.add_theme_font_size_override("font_size",20)
	equipment_title.modulate = Color("#ffe29c")
	equipment_side.add_child(equipment_title)
	var equipment_row := HBoxContainer.new()
	equipment_row.add_theme_constant_override("separation",6)
	equipment_side.add_child(equipment_row)
	var left_slots := VBoxContainer.new()
	equipment_row.add_child(left_slots)
	var preview := SubViewportContainer.new()
	preview.custom_minimum_size = Vector2(146,285)
	preview.stretch = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	equipment_row.add_child(preview)
	var portrait_view := SubViewport.new()
	portrait_view.size = Vector2i(256,450)
	portrait_view.transparent_bg = true
	# Cena 3D isolada: nunca herdar terreno, ceu ou paisagem da partida.
	portrait_view.own_world_3d = true
	portrait_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview.add_child(portrait_view)
	var portrait_stage := Node3D.new()
	portrait_view.add_child(portrait_stage)
	var portrait_goblin := Node3D.new()
	portrait_stage.add_child(portrait_goblin)
	goblin_npc(portrait_goblin,Color("#895938"),"player")
	var portrait_rig := portrait_goblin.get_node_or_null("GoblinRig")
	if portrait_rig != null:
		portrait_rig.call("set_equipment",sword_equipped,shield_equipped)
	var portrait_camera := Camera3D.new()
	portrait_camera.position = Vector3(0,1.12,3.5)
	portrait_stage.add_child(portrait_camera)
	portrait_camera.look_at(Vector3(0,0.97,0),Vector3.UP)
	portrait_camera.current = true
	var portrait_light := DirectionalLight3D.new()
	portrait_light.rotation_degrees = Vector3(-35,30,0)
	portrait_light.light_energy = 1.8
	portrait_stage.add_child(portrait_light)
	var right_slots := VBoxContainer.new()
	equipment_row.add_child(right_slots)
	for kind in ["Capacete","Blusa","Calça","Bota","Costas"]:
		var equipment_slot := Button.new()
		equipment_slot.custom_minimum_size = Vector2(75,52)
		equipment_slot.text = kind
		equipment_slot.tooltip_text = "Espaço reservado para " + kind.to_lower()
		if kind=="Costas":
			equipment_slot.text = "" if backpack_equipped else "Costas"
			equipment_slot.icon = ITEM_ICONS[BACKPACK_ITEM] if backpack_equipped else null
			equipment_slot.tooltip_text = "Arraste uma mochila até aqui. Clique para retirar se estiver vazia."
			equipment_slot.disabled = false
			equipment_slot.pressed.connect(toggle_backpack_from_slot)
			equipment_slot.set_drag_forwarding(backpack_equipment_drag.bind(equipment_slot),can_drop_backpack_equipment,drop_backpack_equipment)
		else:
			equipment_slot.disabled = true # Tipos de armadura ainda nao existem no sistema de itens.
		style_craft_button(equipment_slot)
		if kind=="Costas":
			left_slots.add_child(equipment_slot)
		else:
			right_slots.add_child(equipment_slot)
	if backpack_equipped:
		var bag_caption := Label.new()
		bag_caption.text = "Mochila · 12"
		bag_caption.add_theme_font_size_override("font_size",13)
		left_slots.add_child(bag_caption)
		var bag_grid := GridContainer.new()
		bag_grid.columns = 3
		bag_grid.add_theme_constant_override("h_separation",2)
		bag_grid.add_theme_constant_override("v_separation",2)
		left_slots.add_child(bag_grid)
		for bag_index in range(BACKPACK_SIZE):
			var bag_entry: Vector2i = backpack_slots[bag_index]
			var bag_button := Button.new()
			bag_button.custom_minimum_size = Vector2(38,43)
			bag_button.text = "×%d" % bag_entry.y if bag_entry.y>0 else ""
			bag_button.tooltip_text = ITEMS[bag_entry.x] if bag_entry.x>=0 else "Arraste um item para guardar"
			if bag_entry.x>=0:
				bag_button.icon = ITEM_ICONS[bag_entry.x]
			bag_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bag_button.pressed.connect(backpack_slot_inline_click.bind(bag_index))
			bag_button.gui_input.connect(backpack_slot_inline_input.bind(bag_index))
			bag_button.set_drag_forwarding(backpack_inline_drag.bind(bag_button,bag_index),can_drop_backpack_inline.bind(bag_index),drop_backpack_inline.bind(bag_index))
			style_craft_button(bag_button)
			bag_grid.add_child(bag_button)
	var inventory_side := VBoxContainer.new()
	inventory_side.custom_minimum_size = Vector2(360,390)
	columns.add_child(inventory_side)
	var inventory_grid := GridContainer.new()
	inventory_grid.columns = 5
	var caption := Label.new()
	caption.text = "Inventário"
	caption.add_theme_font_size_override("font_size",20)
	caption.modulate = Color("#ffe29c")
	inventory_side.add_child(caption)
	inventory_side.add_child(inventory_grid)
	var gear_title := Label.new()
	gear_title.text = "Armas e escudo"
	inventory_side.add_child(gear_title)
	var gear_row := HBoxContainer.new()
	inventory_side.add_child(gear_row)
	for gear in ["sword","shield"]:
		var gear_button := Button.new()
		var is_on := sword_equipped if gear=="sword" else shield_equipped
		gear_button.text = ("Retirar " if is_on else "Equipar ") + ("espada" if gear=="sword" else "escudo")
		gear_button.tooltip_text = "Exibir ou ocultar equipamento original na mao do personagem."
		gear_button.pressed.connect(toggle_player_equipment.bind(gear))
		style_craft_button(gear_button)
		gear_row.add_child(gear_button)
	for slot_index in range(inventory_slots.size()):
		var kind: int = inventory_slots[slot_index]
		var item := Button.new()
		item.custom_minimum_size = Vector2(66,48)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		if kind>=0:
			var available := craft_available(kind)
			if kind==BACKPACK_ITEM and backpack_equipped:
				available = maxi(0,available-1)
			item.text = "×%d" % available if available>0 else ""
			if TOOL_MAX_DURABILITY.has(kind) and available>0:
				item.text += "\n%d%%" % roundi(100.0*tool_remaining(kind)/float(TOOL_MAX_DURABILITY[kind]))
			item.tooltip_text = ITEMS[kind]
			if TOOL_MAX_DURABILITY.has(kind):
				item.tooltip_text += " · Durabilidade %d/%d" % [tool_remaining(kind),int(TOOL_MAX_DURABILITY[kind])]
			if reserve[kind]>0:
				item.tooltip_text += " · %d na reserva" % reserve[kind]
			if available>0:
				item.icon = ITEM_ICONS[kind]
			item.toggle_mode = true
			item.set_pressed_no_signal(craft_material==kind)
			item.pressed.connect(select_craft_material.bind(kind))
			item.gui_input.connect(inventory_storage_input.bind(kind))
		else:
			item.tooltip_text = "Slot vazio · arraste um item para cá"
		item.set_drag_forwarding(inventory_drag.bind(item,slot_index),can_drop_inventory.bind(slot_index),drop_inventory.bind(slot_index))
		style_craft_button(item)
		inventory_grid.add_child(item)
	var crafting_panel := VBoxContainer.new()
	crafting_panel.custom_minimum_size = Vector2(400,390)
	columns.add_child(crafting_panel)
	var craft_caption := Label.new()
	craft_caption.text = "Marcenaria · 25 espaços" if craft_mode=="carpentry" else "Fabricação"
	craft_caption.add_theme_font_size_override("font_size",20)
	craft_caption.modulate = Color("#ffe29c")
	crafting_panel.add_child(craft_caption)
	var craft_side := HBoxContainer.new()
	craft_side.custom_minimum_size = Vector2(390,155)
	craft_side.add_theme_constant_override("separation",18)
	craft_side.alignment = BoxContainer.ALIGNMENT_CENTER
	crafting_panel.add_child(craft_side)
	var grid := GridContainer.new()
	grid.columns = 2 if craft_mode=="basic" else (5 if craft_mode=="carpentry" else 3)
	craft_side.add_child(grid)
	for i in range(craft_cells.size()):
		var slot := Button.new()
		var cell := craft_cells[i]
		slot.custom_minimum_size = Vector2(48,48) if craft_mode=="carpentry" else Vector2(68,68)
		if craft_mode=="carpentry":
			slot.expand_icon = true
			slot.add_theme_constant_override("icon_max_width",30)
		slot.tooltip_text = "Clique com o botão direito para retirar uma unidade"
		slot.text = "" if cell.y==0 else "×%d" % cell.y
		if cell.y>0:
			slot.icon = ITEM_ICONS[cell.x]
		slot.set_drag_forwarding(craft_drag.bind(slot,cell.x,i),can_drop_craft.bind(i),drop_craft.bind(i))
		if cell.y>0:
			slot.tooltip_text = ITEMS[cell.x] + "\n" + slot.tooltip_text
		slot.gui_input.connect(craft_cell_input.bind(i))
		slot.pressed.connect(fill_craft_cell.bind(i,true))
		style_craft_button(slot)
		grid.add_child(slot)
	var arrow := Label.new()
	arrow.text = "➜"
	arrow.add_theme_font_size_override("font_size",29)
	arrow.modulate = Color("#bc965e")
	craft_side.add_child(arrow)
	var result := Button.new()
	var recipe := basic_recipe()
	result.text = ""
	result.tooltip_text = CRAFT_OUTPUT[recipe] if not recipe.is_empty() else ""
	var output_item := ITEM_KINDS.find(recipe)
	if output_item>=0:
		result.icon = ITEM_ICONS[output_item]
	result.custom_minimum_size = Vector2(110,83)
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	result.add_theme_font_size_override("font_size",14)
	result.disabled = recipe.is_empty()
	result.pressed.connect(craft_basic)
	style_craft_button(result)
	result.add_theme_stylebox_override("normal",craft_relief(Color("#4a3724"),Color("#ba9257"),true))
	craft_side.add_child(result)
	var explanation := Label.new()
	explanation.text = craft_status(recipe)
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crafting_panel.add_child(explanation)
	var recipes := GridContainer.new()
	recipes.columns = 4
	crafting_panel.add_child(recipes)
	var names: Array = CARPENTRY_PATTERNS.keys() if craft_mode=="carpentry" else ["plank","fire","bench","rope"]
	if craft_mode=="station":
		for station_recipe: String in STATION_PATTERNS.keys():
			if station_level>=2 or station_recipe not in LEVEL_2_RECIPES:
				names.append(station_recipe)
	for kind: String in names:
		var recipe_button := Button.new()
		# As receitas mostram a imagem do item, sem texto ocupando o botao.
		# Icones maiores que os do inventario (27 px), sem ampliar o container.
		recipe_button.custom_minimum_size = Vector2(91,43)
		recipe_button.text = ""
		recipe_button.tooltip_text = "Preparar " + CRAFT_OUTPUT[kind] + (" · exige bancada nível 2" if kind in LEVEL_2_RECIPES else "")
		var recipe_index := ITEM_KINDS.find(kind)
		if recipe_index>=0:
			recipe_button.icon = ITEM_ICONS[recipe_index]
		recipe_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		recipe_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		recipe_button.expand_icon = true
		recipe_button.pressed.connect(prepare_recipe.bind(kind))
		style_craft_button(recipe_button)
		recipe_button.add_theme_constant_override("icon_max_width",44)
		recipes.add_child(recipe_button)
	var clear_button := Button.new()
	clear_button.text = "Limpar grade"
	clear_button.pressed.connect(clear_craft)
	style_craft_button(clear_button)
	recipes.add_child(clear_button)
	menu.add_child(HSeparator.new())
	var hotbar_title := Label.new()
	hotbar_title.text = "Atalhos 1–9 · arraste ou clique para organizar"
	menu.add_child(hotbar_title)
	var shortcut_row := HBoxContainer.new()
	shortcut_row.alignment = BoxContainer.ALIGNMENT_CENTER
	menu.add_child(shortcut_row)
	for slot_index in range(HOTBAR_SIZE):
		var shortcut := Button.new()
		shortcut.custom_minimum_size = Vector2(53,39)
		shortcut.text = str(slot_index+1)
		var mapped: int = bar_items[slot_index]
		shortcut.tooltip_text = ITEMS[mapped] if mapped>=0 else "Espaço vazio"
		if mapped>=0:
			shortcut.icon = ITEM_ICONS[mapped]
		shortcut.pressed.connect(assign_hotbar.bind(slot_index))
		shortcut.set_drag_forwarding(hotbar_drag.bind(shortcut,slot_index),can_drop_hotbar.bind(slot_index),drop_hotbar.bind(slot_index))
		style_craft_button(shortcut)
		shortcut_row.add_child(shortcut)
	label("Clique: colocar 1 · Arraste: mover pilha · Direito: retirar 1 / alternar reserva")
	# A mochila e os seus 12 espacos ficam integrados ao painel esquerdo.
	if craft_mode in ["station","carpentry"]:
		button("Fabricação básica",open_craft.bind("basic"),true)
	if not feedback.is_empty():
		label(feedback)
	button("Voltar",begin,true)

func assign_hotbar(slot_index: int) -> void:
	hotbar_manual = true
	if craft_material>=0 and stock[craft_material]>0:
		var old_index := bar_items.find(craft_material)
		if old_index>=0:
			bar_items[old_index] = -1
		bar_items[slot_index] = craft_material
	else:
		bar_items[slot_index] = -1
	sync_hotbar()
	save_game()
	show_inventory()

func toggle_backpack_from_slot() -> void:
	if backpack_equipped:
		unequip_backpack()
	elif stock[BACKPACK_ITEM]>0:
		backpack_equipped = true
		backpack_visual.visible = true
		backpack_selected_item = -1
		sync_inventory_slots()
		save_game()
		show_inventory.call_deferred()

func backpack_equipment_drag(_position: Vector2, source: Control) -> Variant:
	if not backpack_equipped:
		return null
	var image := TextureRect.new()
	image.texture = ITEM_ICONS[BACKPACK_ITEM]
	image.custom_minimum_size = Vector2(42,42)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	source.set_drag_preview(image)
	return {"item":BACKPACK_ITEM,"equipped_backpack":true}

func can_drop_backpack_equipment(_position: Vector2, data: Variant) -> bool:
	return not backpack_equipped and data is Dictionary and int(data.get("item",-1))==BACKPACK_ITEM and int(data.get("inventory_slot",-1))>=0 and stock[BACKPACK_ITEM]>0

func drop_backpack_equipment(position: Vector2, data: Variant) -> void:
	if not can_drop_backpack_equipment(position,data):
		return
	backpack_equipped = true
	backpack_visual.visible = true
	backpack_selected_item = -1
	sync_inventory_slots()
	save_game()
	show_inventory.call_deferred()

func backpack_inline_drag(_position: Vector2, source: Control, index: int) -> Variant:
	var entry: Vector2i = backpack_slots[index]
	if entry.x<0 or entry.y<=0:
		return null
	var image := TextureRect.new()
	image.texture = ITEM_ICONS[entry.x]
	image.custom_minimum_size = Vector2(40,40)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	source.set_drag_preview(image)
	return {"item":entry.x,"backpack_slot":index,"single":Input.is_physical_key_pressed(KEY_SHIFT)}

func can_drop_backpack_inline(_position: Vector2, data: Variant, index: int) -> bool:
	if not backpack_equipped or not data is Dictionary:
		return false
	var item := int(data.get("item",-1))
	if item<0 or item==BACKPACK_ITEM or item>=ITEMS.size():
		return false
	var entry: Vector2i = backpack_slots[index]
	if entry.y>=BACKPACK_STACK_LIMIT or (entry.x>=0 and entry.x!=item):
		return false
	var source_bag := int(data.get("backpack_slot",-1))
	if source_bag>=0:
		return source_bag!=index and source_bag<BACKPACK_SIZE and backpack_slots[source_bag].y>0
	return int(data.get("inventory_slot",-1))>=0 and stock[item]>0

func drop_backpack_inline(position: Vector2, data: Variant, index: int) -> void:
	if not can_drop_backpack_inline(position,data,index):
		return
	var item := int(data["item"])
	var source_bag := int(data.get("backpack_slot",-1))
	var entry: Vector2i = backpack_slots[index]
	var available: int = backpack_slots[source_bag].y if source_bag>=0 else int(stock[item])
	var count := mini(1 if bool(data.get("single",false)) else available,BACKPACK_STACK_LIMIT-entry.y)
	if count<=0:
		return
	backpack_slots[index] = Vector2i(item,entry.y+count)
	if source_bag>=0:
		var remaining := backpack_slots[source_bag].y-count
		backpack_slots[source_bag] = Vector2i(item,remaining) if remaining>0 else Vector2i(-1,0)
	else:
		stock[item] -= count
	sync_inventory_slots()
	sync_hotbar()
	save_game()
	show_inventory.call_deferred()

func backpack_slot_inline_click(index: int) -> void:
	if backpack_slots[index].y<=0:
		return
	withdraw_from_backpack(index,false)
	sync_inventory_slots()
	sync_hotbar()
	save_game()
	show_inventory.call_deferred()

func backpack_slot_inline_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		if backpack_slots[index].y>0:
			withdraw_from_backpack(index,true)
			sync_inventory_slots()
			sync_hotbar()
			save_game()
			show_inventory.call_deferred()

func inventory_drag(_position: Vector2, source: Control, slot_index: int) -> Variant:
	var item: int = inventory_slots[slot_index]
	if item<0 or craft_available(item)<=0 or (item==BACKPACK_ITEM and backpack_equipped and craft_available(item)<=1):
		return null
	var preview := TextureRect.new()
	preview.texture = ITEM_ICONS[item]
	preview.custom_minimum_size = Vector2(40,40)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	source.set_drag_preview(preview)
	return {"item":item,"origin":-1,"inventory_slot":slot_index,"single":Input.is_physical_key_pressed(KEY_SHIFT)}

func can_drop_inventory(_position: Vector2, data: Variant, target_index: int) -> bool:
	if not data is Dictionary or not data.has("item"):
		return false
	if int(data.get("backpack_slot",-1))>=0:
		var from_bag := int(data["backpack_slot"])
		return backpack_equipped and from_bag<BACKPACK_SIZE and (inventory_slots[target_index]<0 or inventory_slots[target_index]==backpack_slots[from_bag].x)
	if inventory_slots[target_index]>=0:
		return false
	return int(data.get("inventory_slot",-1))>=0 or int(data.get("hotbar_slot",-1))>=0 or int(data.get("origin",-1))>=0

func drop_inventory(position: Vector2, data: Variant, target_index: int) -> void:
	if not can_drop_inventory(position,data,target_index):
		return
	var item := int(data["item"])
	var from_bag := int(data.get("backpack_slot",-1))
	if from_bag>=0:
		withdraw_from_backpack(from_bag,bool(data.get("single",false)))
		inventory_slots[target_index] = item
		sync_hotbar()
		save_game()
		show_inventory.call_deferred()
		return
	var source_index := int(data.get("inventory_slot",-1))
	var origin_index := int(data.get("origin",-1))
	if origin_index>=0:
		# Retorna materiais da grade de craft para o inventário.
		remove_craft_units(origin_index,1 if data.get("single",false) else craft_cells[origin_index].y)
	elif source_index>=0:
		inventory_slots[source_index] = -1
	else:
		var shortcut_index := int(data.get("hotbar_slot",-1))
		if shortcut_index>=0:
			bar_items[shortcut_index] = -1
			hotbar_manual = true
		var existing := inventory_slots.find(item)
		if existing>=0:
			inventory_slots[existing] = -1
	inventory_slots[target_index] = item
	save_game()
	show_inventory.call_deferred()

func hotbar_drag(_position: Vector2, source: Control, slot_index: int) -> Variant:
	var item: int = bar_items[slot_index]
	if item<0 or stock[item]<=0:
		return null
	var preview := TextureRect.new()
	preview.texture = ITEM_ICONS[item]
	preview.custom_minimum_size = Vector2(40,40)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	source.set_drag_preview(preview)
	return {"item":item,"hotbar_slot":slot_index}

func can_drop_hotbar(_position: Vector2, data: Variant, target_index: int) -> bool:
	if not data is Dictionary or not data.has("item"):
		return false
	if int(data.get("hotbar_slot",-1))==target_index:
		return false
	return int(data.get("inventory_slot",-1))>=0 or int(data.get("hotbar_slot",-1))>=0

func drop_hotbar(position: Vector2, data: Variant, target_index: int) -> void:
	if not can_drop_hotbar(position,data,target_index):
		return
	var item := int(data["item"])
	var source_shortcut := int(data.get("hotbar_slot",-1))
	if source_shortcut>=0:
		# Move ou troca as duas posições, sem perder os atalhos.
		var previous: int = bar_items[target_index]
		bar_items[target_index] = item
		bar_items[source_shortcut] = previous
	else:
		var existing := bar_items.find(item)
		if existing>=0:
			bar_items[existing] = -1
		bar_items[target_index] = item
	hotbar_manual = true
	save_game()
	show_inventory.call_deferred()

func craft_drag(_position: Vector2, source: Control, item: int, origin: int) -> Variant:
	if item<0 or (origin<0 and craft_available(item)<=0):
		return null
	var preview := TextureRect.new()
	preview.texture = ITEM_ICONS[item]
	preview.custom_minimum_size = Vector2(36,36)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	source.set_drag_preview(preview)
	return {"item":item,"origin":origin,"single":Input.is_physical_key_pressed(KEY_SHIFT)}

func can_drop_craft(_position: Vector2, data: Variant, index: int) -> bool:
	if not data is Dictionary or not data.has("item") or not data.has("origin"):
		return false
	var cell := craft_cells[index]
	return data.origin!=index and (cell.y==0 or cell.x==data.item)

func drop_craft(position: Vector2, data: Variant, index: int) -> void:
	if not can_drop_craft(position,data,index):
		return
	var amount := craft_cells[data.origin].y if data.origin>=0 else craft_available(data.item)
	if data.get("single",false):
		amount = mini(amount,1)
	if amount<=0:
		return
	craft_cells[index] = Vector2i(data.item,craft_cells[index].y+amount)
	if data.origin>=0:
		remove_craft_units(data.origin,amount)
	show_inventory.call_deferred()

func can_return_craft(_position: Vector2, data: Variant, item: int) -> bool:
	return data is Dictionary and data.get("origin",-1)>=0 and data.get("item",-1)==item

func return_craft(position: Vector2, data: Variant, item: int) -> void:
	if can_return_craft(position,data,item):
		remove_craft_units(data.origin,1 if data.get("single",false) else craft_cells[data.origin].y)
		show_inventory.call_deferred()

func remove_craft_units(index: int, amount: int) -> void:
	var cell := craft_cells[index]
	craft_cells[index] = Vector2i(cell.x,cell.y-amount) if cell.y>amount else Vector2i(-1,0)

func inventory_storage_input(event: InputEvent, item: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		if craft_available(item)==stock[item]:
			toggle_stock(item)
		else:
			notice("Retire este item da grade antes de guardar.")
			show_inventory()

func craft_status(recipe: String) -> String:
	if not recipe.is_empty():
		return "Receita pronta · clique no item para fabricar"
	if craft_mode=="station" and not bench_near():
		return "Aproxime-se da bancada para fabricar os itens."
	match craft_mode:
		"carpentry":
			return "Paredes, pisos, escadas e móveis · grade 5 × 5."
		"station":
			return "Ferramentas e armas · nível 2 libera a bancada de marcenaria."
		_:
			var kinds: Array = []
			for cell in craft_cells:
				if cell.y>0 and not kinds.has(cell.x):
					kinds.append(cell.x)
			if kinds.has(VINE):
				return "Corda: coloque 2 cipós lado a lado."
			if kinds.has(2) and kinds.has(7):
				return "Pedra e tábua juntas ainda não têm receita. Use gravetos com um dos dois."
			if kinds.has(2):
				return "Fogueira: 1 pedra e 2 gravetos."
			return "Bancada: 2 tábuas em cima, 2 gravetos embaixo · 1 tronco rende 4 tábuas."

func craft_relief(fill: Color, edge: Color, raised: bool = false) -> StyleBoxFlat:
	var style := hotbar_style(fill, edge, 2)
	style.set_corner_radius_all(3)
	style.shadow_size = 0
	style.set_border_width(SIDE_TOP if raised else SIDE_BOTTOM, 3)
	style.set_border_width(SIDE_LEFT if raised else SIDE_RIGHT, 3)
	return style

func style_craft_button(control: Button) -> void:
	control.add_theme_constant_override("icon_max_width",27)
	control.add_theme_stylebox_override("normal",craft_relief(Color("#211f18"),Color("#655538")))
	control.add_theme_stylebox_override("hover",craft_relief(Color("#433824"),Color("#bb965e"),true))
	control.add_theme_stylebox_override("pressed",craft_relief(Color("#53412a"),Color("#d4ad69")))
	control.add_theme_stylebox_override("disabled",craft_relief(Color("#241f18"),Color("#685337")))

func craft_available(index: int) -> int:
	var available: int = stock[index]
	for entry in craft_cells:
		if entry.x==index:
			available -= entry.y
	return available

func select_craft_material(index: int) -> void:
	if craft_material!=index and craft_available(index)<=0:
		notice("Material na reserva: recupere com o botão direito." if reserve[index]>0 else "Nenhuma unidade disponível deste material.")
		show_inventory()
		return
	craft_material = -1 if craft_material==index else index
	show_inventory()

func clear_craft() -> void:
	craft_cells.fill(Vector2i(-1,0))
	craft_material = -1
	show_inventory()

func craft_cell_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		if craft_cells[index].y>0:
			remove_craft_units(index,1)
			show_inventory()
		else:
			fill_craft_cell(index,true)

func fill_craft_cell(index: int, single := false) -> void:
	var cell := craft_cells[index]
	if craft_material<0:
		var remaining := cell.y-1 if single else 0
		craft_cells[index] = Vector2i(cell.x,remaining) if remaining>0 else Vector2i(-1,0)
	elif cell.y==0 or cell.x==craft_material:
		var available := craft_available(craft_material)
		var amount := mini(available,1) if single else available
		if amount>0:
			craft_cells[index] = Vector2i(craft_material,cell.y+amount)
	show_inventory()

func prepare_recipe(kind: String) -> void:
	if craft_mode=="carpentry" and (not CARPENTRY_PATTERNS.has(kind) or not carpentry_near()):
		return
	if craft_mode!="carpentry" and CARPENTRY_PATTERNS.has(kind):
		return
	if kind in LEVEL_2_RECIPES and not can_craft_level_two():
		notice("Esta receita exige a bancada de trabalho nível 2.")
		show_inventory()
		return
	var pattern: Array = {"plank":[6,-1,-1,-1],"fire":FIRE_PATTERN,
		"bench":BENCH_PATTERN,"rope":[VINE,VINE,-1,-1]}.get(kind,STATION_PATTERNS.get(kind,[]))
	if craft_mode=="carpentry":
		pattern = CARPENTRY_PATTERNS.get(kind,[])
	if pattern.size()==4 and craft_mode=="station":
		pattern = expand_basic_pattern(pattern,0,0)
	if pattern.size()!=craft_cells.size():
		return
	var needed: Dictionary = {}
	for item: int in pattern:
		if item>=0:
			needed[item] = int(needed.get(item,0))+1
	for item: int in needed:
		if stock[item]<needed[item]:
			notice("Falta "+ITEMS[item].to_lower()+" para esta receita.")
			show_inventory()
			return
	for i in range(pattern.size()):
		craft_cells[i] = Vector2i(pattern[i],1) if pattern[i]>=0 else Vector2i(-1,0)
	craft_material = -1
	show_inventory()

func expand_basic_pattern(pattern: Array, row: int, col: int) -> Array:
	var expanded: Array = []
	expanded.resize(9)
	expanded.fill(-1)
	for i in range(4):
		expanded[(row + int(i / 2))*3 + col + i%2] = pattern[i]
	return expanded

func matches_basic_recipe(pattern: Array) -> bool:
	if craft_cells.size()==4:
		return matches_recipe(pattern)
	if craft_cells.size()!=9:
		return false
	for row in range(2):
		for col in range(2):
			if matches_recipe(expand_basic_pattern(pattern,row,col)):
				return true
	return false

func basic_recipe() -> String:
	var counts: Array = []
	counts.resize(ITEMS.size())
	counts.fill(0)
	for cell in craft_cells:
		if cell.y>0:
			counts[cell.x] += cell.y
	for i in range(ITEMS.size()):
		if counts[i]>stock[i]:
			return ""
	if craft_mode=="carpentry":
		if not carpentry_near():
			return ""
		for kind: String in CARPENTRY_PATTERNS:
			if matches_recipe(CARPENTRY_PATTERNS[kind]):
				return kind
		return ""
	if craft_mode=="station" and not bench_near():
		return ""
	if matches_basic_recipe(BENCH_PATTERN):
		return "bench"
	if matches_basic_recipe(FIRE_PATTERN):
		return "fire"
	if matches_basic_recipe([VINE,VINE,-1,-1]) or matches_basic_recipe([-1,-1,VINE,VINE]):
		return "rope"
	# Um tronco sozinho em qualquer posicao, com a mesma receita de 2x2.
	var total := 0
	for amount in counts:
		total += int(amount)
	if counts[TOMATO_ITEM]==1 and total==1:
		return "tomato_seeds"
	if counts[6]>=1 and total==counts[6]:
		return "plank"
	if craft_mode=="station":
		for kind: String in STATION_PATTERNS:
			if kind in LEVEL_2_RECIPES and not can_craft_level_two():
				continue
			if matches_recipe(STATION_PATTERNS[kind]):
				return kind
	return ""

func matches_recipe(pattern: Array) -> bool:
	if pattern.size()!=craft_cells.size():
		return false
	for i in range(pattern.size()):
		var expected: int = pattern[i]
		if expected==-1:
			if craft_cells[i].y!=0:
				return false
		elif craft_cells[i].x!=expected or craft_cells[i].y<1:
			return false
	return true

func craft_basic() -> void:
	var kind := basic_recipe()
	if kind.is_empty():
		if craft_mode=="station" and not bench_near():
			notice("Aproxime-se da bancada para fabricar o item.")
		return
	if kind in LEVEL_2_RECIPES and not can_craft_level_two():
		notice("Esta receita exige a bancada de trabalho nível 2.")
		return
	var costs: Dictionary = {
		"plank":{6:1},"fire":{1:2,2:1},"bench":{7:2,1:2},"spear":{2:1,1:2},"wood_spear":{1:3},"wood_axe":{1:3,7:2},"stone_axe":{1:3,2:2},"shovel":{1:2,7:1},"wood_pickaxe":{7:3,1:2},"stone_pickaxe":{2:3,1:2},"spiked_club":{1:1,6:2,WOLF_TOOTH:4},"rope":{VINE:2},"backpack":{4:7,VINE:2},"bench2":{2:3,6:4,VINE:1},"wood_wall":{7:9},"wood_doorway":{7:7},"wood_window":{7:8},"wood_floor":{7:8,6:1},"chest":{7:8,VINE:1},"stairs_straight":{7:8,1:2},"stairs_l":{7:12,1:4},"ladder":{1:6,VINE:2},"carpentry_bench":{7:6,6:2,10:1},"tomato_seeds":{TOMATO_ITEM:1}
	}[kind]
	for index: int in costs:
		if stock[index]<int(costs[index]):
			return
	for index: int in costs:
		stock[index] -= costs[index]
	for i in range(craft_cells.size()):
		var cell := craft_cells[i]
		if cell.y<=0:
			continue
		# Uma unidade de cada casa ocupada por craft, mesmo em pilhas maiores.
		var used := 1
		craft_cells[i] = Vector2i(cell.x,cell.y-used) if cell.y>used else Vector2i(-1,0)
	sync_hotbar()
	match kind:
		"tomato_seeds":
			stock[TOMATO_SEED_ITEM] += 3
			item_received(TOMATO_SEED_ITEM)
		"plank":
			stock[7] += 4
			item_received(7)
		_:
			var item := ITEM_KINDS.find(kind)
			if item>=0:
				stock[item] += 1
				item_received(item)
	# Nunca coloca estruturas automaticamente: ficam no inventario ate o jogador usa-las.
	sync_hotbar()
	notice(str(CRAFT_OUTPUT[kind])+" · fabricação concluída.")
	save_game()
	show_inventory()

func serialize_backpack() -> Array:
	var data := []
	for slot in backpack_slots:
		data.append([slot.x,slot.y])
	return data

func normalized_chest_slots(id: String) -> Array:
	var old: Array = chest_storage.get(id,[])
	var slots: Array = []
	for i in range(CHEST_SIZE):
		var cell: Variant = old[i] if i<old.size() else [-1,0]
		var item := -1
		var amount := 0
		if cell is Array and cell.size()>=2:
			item = int(cell[0])
			amount = int(cell[1])
		if item<0 or item>=ITEMS.size() or amount<=0:
			slots.append([-1,0])
		else:
			slots.append([item,mini(amount,CHEST_STACK_LIMIT)])
	return slots

func chest_has_items(id: String) -> bool:
	for cell in normalized_chest_slots(id):
		if int(cell[1])>0:
			return true
	return false

var cached_chest_open_sound: AudioStreamWAV
var cached_chest_close_sound: AudioStreamWAV

func play_chest_lid_sound(at: Vector3, opening: bool) -> void:
	if opening and cached_chest_open_sound==null:
		cached_chest_open_sound = preload("res://chest_lid_sound.gd").make_stream(true)
	if not opening and cached_chest_close_sound==null:
		cached_chest_close_sound = preload("res://chest_lid_sound.gd").make_stream(false)
	var audio := AudioStreamPlayer3D.new()
	audio.name = "SomBauAbrindo" if opening else "SomTampaBauFechando"
	add_child(audio)
	audio.global_position = at+Vector3.UP*0.45
	audio.stream = cached_chest_open_sound if opening else cached_chest_close_sound
	audio.unit_size = 5.0
	audio.max_distance = 20.0
	audio.volume_db = -2.0 if opening else 0.0
	audio.pitch_scale = randf_range(0.96,1.04)
	audio.finished.connect(audio.queue_free)
	audio.play()

func close_chest_visual() -> void:
	if open_chest_id.is_empty():
		return
	var old: Node3D = objects.get(open_chest_id,null)
	if is_instance_valid(old):
		var lid := old.get_node_or_null("Tampa") as Node3D
		if lid!=null:
			var closing := lid.create_tween()
			closing.tween_property(lid,"rotation:x",0.0,0.23)
			# Pancada somente quando a tampa atinge a caixa.
			closing.tween_callback(play_chest_lid_sound.bind(old.global_position,false))
	open_chest_id = ""
	chest_selected_item = -1
	# A resposta do anfitriao ainda pode estar a caminho.

func open_chest(o: Node3D) -> void:
	if not is_instance_valid(o) or str(o.get_meta("kind",""))!="chest":
		return
	close_chest_visual()
	open_chest_id = str(o.get_meta("id",""))
	chest_storage[open_chest_id] = normalized_chest_slots(open_chest_id)
	var lid := o.get_node_or_null("Tampa") as Node3D
	if lid!=null:
		lid.create_tween().tween_property(lid,"rotation:x",-1.15,0.28)
		play_chest_lid_sound(o.global_position,true)
	show_chest()

func show_chest() -> void:
	if open_chest_id.is_empty():
		return
	if not objects.has(open_chest_id):
		close_chest_visual()
		begin()
		return
	if is_instance_valid(medieval_menu):
		medieval_menu.hide()
	set_gameplay_overlays_visible(true)
	inventory = true
	moving = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.show()
	panel.add_theme_stylebox_override("panel",craft_relief(Color("#30291f"),Color("#b18a51"),true))
	clear_menu()
	label("Baú de madeira · 16 espaços · pilhas de até 64")
	label("Selecione um item abaixo e clique no espaço do baú para guardar.")
	label("Sem seleção: clique para retirar tudo · botão direito retira/guarda 1.")
	var chest_grid := GridContainer.new()
	chest_grid.columns = 4
	menu.add_child(chest_grid)
	var slots := normalized_chest_slots(open_chest_id)
	for index in range(CHEST_SIZE):
		var slot: Array = slots[index]
		var button_slot := Button.new()
		button_slot.custom_minimum_size = Vector2(94,60)
		button_slot.text = "×%d" % int(slot[1]) if int(slot[1])>0 else ""
		button_slot.tooltip_text = ITEMS[int(slot[0])] if int(slot[0])>=0 else "Espaço vazio"
		if int(slot[0])>=0:
			button_slot.icon = ITEM_ICONS[int(slot[0])]
		button_slot.disabled = chest_pending
		button_slot.pressed.connect(chest_slot_clicked.bind(index,false))
		button_slot.gui_input.connect(chest_slot_input.bind(index))
		style_craft_button(button_slot)
		chest_grid.add_child(button_slot)
	menu.add_child(HSeparator.new())
	label("Inventário · selecione o item para depositar")
	var item_grid := GridContainer.new()
	item_grid.columns = 6
	menu.add_child(item_grid)
	for i in range(ITEMS.size()):
		if stock[i]<=0 or i==CHEST_ITEM:
			continue
		var item_button := Button.new()
		item_button.custom_minimum_size = Vector2(67,49)
		item_button.text = "×%d" % stock[i]
		item_button.tooltip_text = ITEMS[i]
		item_button.icon = ITEM_ICONS[i]
		item_button.toggle_mode = true
		item_button.set_pressed_no_signal(chest_selected_item==i)
		item_button.disabled = chest_pending
		item_button.pressed.connect(chest_select_item.bind(i))
		style_craft_button(item_button)
		item_grid.add_child(item_button)
	button("Fechar baú",begin,true)

func chest_select_item(item: int) -> void:
	chest_selected_item = -1 if chest_selected_item==item else item
	show_chest()

func chest_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		chest_slot_clicked(index,true)

func chest_slot_clicked(index: int, single: bool) -> void:
	if open_chest_id.is_empty() or chest_pending or index<0 or index>=CHEST_SIZE:
		return
	var chest: Node3D = objects.get(open_chest_id,null)
	if not is_instance_valid(chest) or player.global_position.distance_to(chest.global_position)>6.0:
		notice("Aproxime-se do baú.")
		return
	var slots := normalized_chest_slots(open_chest_id)
	var cell: Array = slots[index]
	var deposit := chest_selected_item>=0
	var item := chest_selected_item if deposit else int(cell[0])
	if item<0 or item>=ITEMS.size():
		return
	if deposit and item==CHEST_ITEM:
		notice("Não é permitido guardar baús dentro de baús.")
		return
	var count := 1 if single else (mini(stock[item],CHEST_STACK_LIMIT-int(cell[1])) if deposit else int(cell[1]))
	if deposit:
		if stock[item]<=0 or (int(cell[0])>=0 and int(cell[0])!=item):
			notice("Selecione um espaço vazio ou com o mesmo item.")
			return
		count = mini(count,stock[item])
	if count<=0:
		return
	if net_role=="client":
		if not net_world_ready:
			return
		chest_pending = true
		pending_chest_id = open_chest_id
		net_chest_action.rpc_id(1,open_chest_id,index,item,count,deposit)
		show_chest()
		return
	chest_apply_transfer(open_chest_id,index,item,count,deposit)
	save_game()
	show_chest()

func chest_apply_transfer(id: String,index: int,item: int,count: int,deposit: bool) -> int:
	if index<0 or index>=CHEST_SIZE or count<=0:
		return 0
	var slots := normalized_chest_slots(id)
	var cell: Array = slots[index]
	var amount := 0
	if deposit:
		if stock[item]<=0 or (int(cell[0])>=0 and int(cell[0])!=item):
			return 0
		amount = mini(count,mini(stock[item],CHEST_STACK_LIMIT-int(cell[1])))
		if amount<=0:
			return 0
		stock[item] -= amount
		slots[index] = [item,int(cell[1])+amount]
	else:
		if int(cell[0])!=item:
			return 0
		amount = mini(count,int(cell[1]))
		stock[item] += amount
		slots[index] = [item,int(cell[1])-amount] if int(cell[1])>amount else [-1,0]
		item_received(item)
	chest_storage[id] = slots
	sync_hotbar()
	if net_role=="host":
		net_chest_snapshot.rpc(id,slots)
	return amount

@rpc("any_peer","call_remote","reliable")
func net_chest_action(id: String,index: int,item: int,count: int,deposit: bool) -> void:
	if net_role!="host":
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if not objects.has(id):
		net_chest_confirm.rpc_id(peer_id,id,item,0,deposit,normalized_chest_slots(id))
		return
	var chest: Node3D = objects[id]
	if not is_instance_valid(chest) or str(chest.get_meta("kind",""))!="chest" or not remote_can_interact(peer_id,chest.global_position,5.5):
		net_chest_confirm.rpc_id(peer_id,id,item,0,deposit,normalized_chest_slots(id))
		return
	if index<0 or index>=CHEST_SIZE or item<0 or item>=ITEMS.size() or count<=0 or count>CHEST_STACK_LIMIT or (deposit and item==CHEST_ITEM):
		net_chest_confirm.rpc_id(peer_id,id,item,0,deposit,normalized_chest_slots(id))
		return
	var slots := normalized_chest_slots(id)
	var cell: Array = slots[index]
	var moved := 0
	if deposit:
		if int(cell[0])<0 or int(cell[0])==item:
			moved = mini(count,CHEST_STACK_LIMIT-int(cell[1]))
			if moved>0:
				slots[index] = [item,int(cell[1])+moved]
	else:
		if int(cell[0])==item:
			moved = mini(count,int(cell[1]))
			if moved>0:
				slots[index] = [item,int(cell[1])-moved] if int(cell[1])>moved else [-1,0]
	if moved>0:
		chest_storage[id] = slots
		net_chest_snapshot.rpc(id,slots)
		save_game()
	net_chest_confirm.rpc_id(peer_id,id,item,moved,deposit,slots)

@rpc("authority","call_remote","reliable")
func net_chest_snapshot(id: String,slots: Array) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1 or slots.size()!=CHEST_SIZE:
		return
	chest_storage[id] = slots
	if open_chest_id==id and not chest_pending:
		show_chest()

@rpc("authority","call_remote","reliable")
func net_chest_confirm(id: String,item: int,moved: int,deposit: bool,slots: Array) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1 or pending_chest_id!=id:
		return
	chest_pending = false
	pending_chest_id = ""
	if item>=0 and item<ITEMS.size() and moved>0 and slots.size()==CHEST_SIZE:
		if deposit:
			stock[item] = maxi(0,stock[item]-moved)
		else:
			stock[item] += moved
			item_received(item)
		chest_storage[id] = slots
		sync_hotbar()
		save_game()
	if open_chest_id==id:
		show_chest()

func open_backpack() -> void:
	if not backpack_equipped:
		if stock[BACKPACK_ITEM]>0:
			backpack_equipped = true
			backpack_visual.visible = true
			backpack_selected_item = -1
		else:
			notice("Você ainda não tem uma mochila.")
			show_inventory()
			return
	backpack_selected_item = -1
	save_game()
	show_backpack()

func show_backpack() -> void:
	if is_instance_valid(medieval_menu):
		medieval_menu.hide()
	set_gameplay_overlays_visible(true)
	inventory = true
	moving = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.show()
	panel.add_theme_stylebox_override("panel",craft_relief(Color("#30291f"),Color("#a88652"),true))
	clear_menu()
	label("Mochila equipada · 12 espaços extras (pilhas de até 64)")
	label("Escolha um item do inventário e depois clique em um espaço da mochila.")
	label("Sem item selecionado: clique para retirar pilha; direito retira uma unidade.")
	var bag_grid := GridContainer.new()
	bag_grid.columns = 6
	menu.add_child(bag_grid)
	for i in range(BACKPACK_SIZE):
		var entry := backpack_slots[i]
		var button_slot := Button.new()
		button_slot.custom_minimum_size = Vector2(83,61)
		button_slot.text = "×%d" % entry.y if entry.y>0 else ""
		button_slot.tooltip_text = ITEMS[entry.x] if entry.x>=0 else "Espaço vazio"
		if entry.x>=0:
			button_slot.icon = ITEM_ICONS[entry.x]
		button_slot.pressed.connect(backpack_slot_clicked.bind(i))
		button_slot.gui_input.connect(backpack_slot_input.bind(i))
		style_craft_button(button_slot)
		bag_grid.add_child(button_slot)
	menu.add_child(HSeparator.new())
	label("Inventário principal · clique para selecionar o que guardar")
	var all_items := GridContainer.new()
	all_items.columns = 6
	menu.add_child(all_items)
	for i in range(ITEMS.size()):
		if i==BACKPACK_ITEM:
			continue
		var item_button := Button.new()
		item_button.custom_minimum_size = Vector2(83,55)
		item_button.text = "×%d" % stock[i] if stock[i]>0 else ""
		item_button.tooltip_text = ITEMS[i]
		item_button.toggle_mode = true
		item_button.set_pressed_no_signal(backpack_selected_item==i)
		if stock[i]>0:
			item_button.icon = ITEM_ICONS[i]
		item_button.disabled = stock[i]<=0
		item_button.pressed.connect(backpack_select_item.bind(i))
		style_craft_button(item_button)
		all_items.add_child(item_button)
	button("Retirar mochila",unequip_backpack,true)
	button("Voltar ao inventário",show_inventory,true)

func backpack_select_item(item: int) -> void:
	backpack_selected_item = -1 if backpack_selected_item==item else item
	show_backpack()

func backpack_slot_clicked(index: int) -> void:
	var entry := backpack_slots[index]
	if backpack_selected_item>=0:
		var item := backpack_selected_item
		if stock[item]>0 and (entry.x<0 or entry.x==item):
			var amount := mini(stock[item],BACKPACK_STACK_LIMIT-entry.y)
			if amount>0:
				stock[item] -= amount
				backpack_slots[index] = Vector2i(item,entry.y+amount)
			else:
				notice("Este espaço está cheio.")
		else:
			notice("Esse espaço já contém outro tipo de item.")
	else:
		withdraw_from_backpack(index,false)
	sync_hotbar()
	save_game()
	show_backpack()

func backpack_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		withdraw_from_backpack(index,true)
		sync_hotbar()
		save_game()
		show_backpack()

func withdraw_from_backpack(index: int, single: bool) -> void:
	var entry := backpack_slots[index]
	if entry.x<0 or entry.y<=0:
		return
	var amount := 1 if single else entry.y
	stock[entry.x] += amount
	item_received(entry.x)
	backpack_slots[index] = Vector2i(entry.x,entry.y-amount) if entry.y>amount else Vector2i(-1,0)

func unequip_backpack() -> void:
	for entry in backpack_slots:
		if entry.y>0:
			notice("Esvazie a mochila antes de retirar.")
			show_inventory()
			return
	backpack_equipped = false
	backpack_visual.visible = false
	backpack_selected_item = -1
	save_game()
	show_inventory()

func build_base_ground(point: Vector3, yaw: float, is_wall: bool) -> float:
	# A construcao fica nivelada pelo ponto MAIS alto do relevo sob o modulo.
	# Em encostas, as partes mais baixas recebem pilares de fundacao.
	var maximum := ground(point.x,point.z)
	var axis := Basis(Vector3.UP,yaw).x
	for fraction in [-.50,-.25,0.0,.25,.50]:
		var sample: Vector3 = point+axis*(WALL_SIZE*float(fraction))
		maximum = maxf(maximum,ground(sample.x,sample.z))
		if not is_wall:
			for offset in [-.5,.5]:
				var corner: Vector3 = sample+Vector3(0,0,WALL_SIZE*float(offset))
				maximum = maxf(maximum,ground(corner.x,corner.z))
	return maximum


func build_reference_base(point: Vector3, default_base: float) -> float:
	# Casas antigas nao tem campo level: sao tratadas como terreo.
	# Usar uma origem vertical compartilhada impede degraus entre modulos.
	var best := WALL_SIZE*3.0
	var base := default_base
	for entry in placed:
		if entry.get("kind","") not in ["wood_wall","wood_doorway","wood_window","wood_floor"]:
			continue
		var p: Array = entry["p"]
		var at := Vector3(float(p[0]),float(p[1]),float(p[2]))
		var dist := Vector2(at.x-point.x,at.z-point.z).length()
		if dist<best:
			best = dist
			base = at.y-float(entry.get("level",0))*WALL_SIZE
	return base


func find_wall_snap(point: Vector3, yaw: float) -> Vector3:
	# Permite fileiras, cantos e paredes exatamente empilhadas.
	var axis := Basis(Vector3.UP,yaw).x.normalized()
	var best := point
	var best_distance := WALL_SIZE*.92
	for entry in placed:
		if entry.get("kind","") not in ["wood_wall","wood_doorway","wood_window"]:
			continue
		var p: Array = entry["p"]
		var old := Vector3(float(p[0]),float(p[1]),float(p[2]))
		var old_level := int(entry.get("level",0))
		var raised := old+Vector3.UP*(float(build_level-old_level)*WALL_SIZE)
		if absf(raised.y-point.y)>.34:
			continue
		if old_level!=build_level:
			var stack_distance := Vector2(point.x-raised.x,point.z-raised.z).length()
			if stack_distance<best_distance:
				best_distance = stack_distance
				best = raised
		var other_axis := Basis(Vector3.UP,float(entry.get("r",0.0))).x.normalized()
		for old_sign in [-1.0,1.0]:
			for new_sign in [-1.0,1.0]:
				var candidate: Vector3 = raised+other_axis*(float(old_sign)*WALL_SIZE*.5)-axis*(float(new_sign)*WALL_SIZE*.5)
				var distance := Vector2(point.x-candidate.x,point.z-candidate.z).length()
				if distance<best_distance:
					best_distance = distance
					best = candidate
	return best


func floor_target_from_aim(fallback: Vector3) -> Vector3:
	# Clique na borda de um painel para criar o proximo; clique numa
	# parede para fechar o teto por cima, mesmo estando no terreo.
	var hit := ray(5.8)
	if hit.is_empty():
		return fallback
	var obj := hit["collider"] as CollisionObject3D
	if obj==null:
		return fallback
	var kind := str(obj.get_meta("kind",""))
	var aimed: Vector3 = hit["position"]
	if kind=="wood_floor":
		var center: Vector3 = obj.global_position
		var source_level := 0
		for entry in placed:
			if str(entry.get("id",""))==str(obj.get_meta("id","")):
				source_level = int(entry.get("level",0))
				break
		if source_level<build_level:
			return Vector3(center.x,fallback.y,center.z)
		if source_level==build_level:
			var direction := Vector2(aimed.x-center.x,aimed.z-center.z)
			if direction.length()<WALL_SIZE*.18:
				var look := -camera.global_basis.z
				direction = Vector2(look.x,look.z)
			if absf(direction.x)>absf(direction.y):
				return Vector3(center.x+signf(direction.x)*WALL_SIZE,fallback.y,center.z)
			return Vector3(center.x,fallback.y,center.z+signf(direction.y)*WALL_SIZE)
	if kind in ["wood_wall","wood_doorway","wood_window"]:
		var wp: Vector3 = obj.global_position
		var side: Vector3 = hit["normal"]
		if Vector2(side.x,side.z).length()>.5:
			return Vector3(wp.x+side.x*WALL_SIZE*.5,fallback.y,wp.z+side.z*WALL_SIZE*.5)
	return fallback


func find_floor_snap(point: Vector3) -> Vector3:
	# Encaixa sempre num espaco LIVRE, em vez de duplicar painel existente.
	var best := point
	var best_score := INF
	for entry in placed:
		var kind := str(entry.get("kind",""))
		if kind not in ["wood_wall","wood_doorway","wood_window","wood_floor"]:
			continue
		var p: Array = entry["p"]
		var at := Vector3(float(p[0]),float(p[1]),float(p[2]))
		var level := int(entry.get("level",0))
		var candidates: Array[Vector3] = []
		if kind=="wood_floor" and level==build_level:
			for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
				candidates.append(at+direction*WALL_SIZE)
		elif kind=="wood_floor" and level==build_level-1:
			candidates.append(at)
		elif kind!="wood_floor" and level in [build_level,build_level-1]:
			var other_side := Basis(Vector3.UP,float(entry.get("r",0.0))).z
			candidates.append(at+other_side*WALL_SIZE*.5)
			candidates.append(at-other_side*WALL_SIZE*.5)
		for candidate in candidates:
			candidate.y = point.y
			if floor_intersects_other_floor(candidate):
				continue
			if not upper_build_supported(candidate):
				continue
			var distance := Vector2(candidate.x-point.x,candidate.z-point.z).length()
			var player_distance := Vector2(candidate.x-player.position.x,candidate.z-player.position.z).length()
			var score := distance+player_distance*.025
			if distance<WALL_SIZE*2.5 and score<best_score:
				best = candidate
				best_score = score
	if best_score!=INF:
		return best
	return point


func wall_intersects_other_wall(point: Vector3, yaw: float) -> bool:
	var axis := Vector2(cos(yaw),-sin(yaw))
	for entry in placed:
		if entry.get("kind","") not in ["wood_wall","wood_doorway","wood_window"]:
			continue
		var p: Array = entry["p"]
		if absf(float(p[1])-point.y)>.25:
			continue # Outro andar, nao e sobreposicao.
		var old := Vector2(float(p[0]),float(p[2]))
		var this := Vector2(point.x,point.z)
		var old_axis := Vector2(cos(float(entry.get("r",0.0))),-sin(float(entry.get("r",0.0))))
		var delta := this-old
		if absf(axis.dot(old_axis))>.95:
			if absf(delta.dot(axis))<WALL_SIZE-.12 and absf(delta.cross(axis))<.17:
				return true
		elif absf(delta.dot(old_axis))<WALL_SIZE*.5-.14 and absf(delta.dot(axis))<WALL_SIZE*.5-.14:
			return true
	return false


func floor_intersects_other_floor(point: Vector3) -> bool:
	for entry in placed:
		if entry.get("kind","")!="wood_floor":
			continue
		var p: Array = entry["p"]
		if absf(float(p[1])-point.y)>.25:
			continue
		if absf(float(p[0])-point.x)<WALL_SIZE-.1 and absf(float(p[2])-point.z)<WALL_SIZE-.1:
			return true
	return false


func upper_build_supported(point: Vector3) -> bool:
	if build_level==0:
		return true
	for entry in placed:
		var kind := str(entry.get("kind",""))
		if kind not in ["wood_wall","wood_doorway","wood_window","wood_floor"]:
			continue
		var level := int(entry.get("level",0))
		var p: Array = entry["p"]
		var at := Vector3(float(p[0]),float(p[1]),float(p[2]))
		if kind=="wood_floor" and level==build_level and absf(at.y-point.y)<.30:
			var dx := absf(at.x-point.x)
			var dz := absf(at.z-point.z)
			# Placas vizinhas estao afastadas exatamente WALL_SIZE.
			if dx<=WALL_SIZE+.08 and dz<=WALL_SIZE+.08 and (dx<.14 or dz<.14):
				return true
		if kind!="wood_floor" and level==build_level-1 and absf((at.y+WALL_SIZE)-point.y)<.30:
			if Vector2(at.x-point.x,at.z-point.z).length()<WALL_SIZE*1.15:
				return true
	return false


func construction_surface(point: Vector3, ceiling: float) -> float:
	var height := ground(point.x,point.z)+.008
	for entry in placed:
		if entry.get("kind","")!="wood_floor":
			continue
		var p: Array = entry["p"]
		var top := float(p[1])+.116
		if top<=ceiling and absf(float(p[0])-point.x)<=WALL_SIZE*.5 and absf(float(p[2])-point.z)<=WALL_SIZE*.5:
			height = maxf(height,top)
	return height

func construction_candidate(kind: String) -> Dictionary:
	var is_wall := kind in ["wood_wall","wood_doorway","wood_window"]
	var is_floor := kind=="wood_floor"
	var is_stair := kind in STAIR_KINDS
	var yaw := snappedf(player.rotation.y,PI/2.0)+float(build_rotation)*PI*.5 if is_wall else (player.rotation.y+float(build_rotation)*PI*.5 if kind=="chest" else 0.0)
	# O lado frontal do bau (fechadura, +Z local) aponta para o jogador por padrao.
	# R gira a pre-visualizacao em passos de 90 graus sem perder essa orientacao inicial.
	if is_stair or kind=="carpentry_bench":
		yaw = snappedf(player.rotation.y,PI/2.0)+float(build_rotation)*PI*.5
	var point := player.position-player.basis.z*2.15
	var hit := ray(5.8)
	build_level = 0
	var support: CollisionObject3D = null
	if not hit.is_empty():
		point = hit["position"]
		support = hit["collider"] as CollisionObject3D
	var support_kind := str(support.get_meta("kind","")) if support!=null else ""
	var support_level := 0
	if support!=null:
		for entry in placed:
			if str(entry.get("id",""))==str(support.get_meta("id","")):
				support_level = int(entry.get("level",0))
				break
	if is_wall or is_floor:
		if support_kind=="wood_floor":
			build_level = support_level
			var center := support.global_position
			var delta := point-center
			var side := Vector3(signf(delta.x),0,0) if absf(delta.x)>absf(delta.z) else Vector3(0,0,signf(delta.z))
			if side==Vector3.ZERO:
				side = Vector3.FORWARD
			point = center+side*WALL_SIZE*(.5 if is_wall else 1.0)
			if is_wall:
				yaw = PI*.5 if absf(side.x)>.5 else 0.0
				yaw += float(build_rotation)*PI*.5
		elif support_kind in ["wood_wall","wood_doorway","wood_window"]:
			var center := support.global_position
			var upper := point.y-center.y>WALL_SIZE*.65
			build_level = mini(support_level+(1 if upper else 0),BUILD_MAX_LEVEL)
			if is_floor:
				var normal: Vector3 = hit["normal"]
				var side := support.global_basis.z
				if absf(normal.dot(side))>.2:
					side *= signf(normal.dot(side))
				elif (player.position-center).dot(side)<0:
					side = -side
				point = center+side*WALL_SIZE*.5
				point.y = center.y+float(build_level-support_level)*WALL_SIZE
				point = find_floor_snap(point)
			else:
				point.y = center.y+float(build_level-support_level)*WALL_SIZE
				point = find_wall_snap(point,yaw)
		else:
			point.y = build_reference_base(point,build_base_ground(point,yaw,is_wall)-.105)
			if is_wall:
				point = find_wall_snap(point,yaw)
			else:
				point = find_floor_snap(point)
	else:
		point.y = construction_surface(point,point.y+.25)
	var valid := not hit.is_empty()
	if is_stair:
		valid = valid and (support_kind=="wood_floor" or support_kind=="")
	if is_wall:
		valid = valid and build_level<BUILD_MAX_LEVEL and not wall_intersects_other_wall(point,yaw)
	if is_floor:
		valid = valid and not floor_intersects_other_floor(point)
	if is_wall or is_floor:
		valid = valid and upper_build_supported(point)
	var shape := BoxShape3D.new()
	shape.size = Vector3(WALL_SIZE*.94,WALL_SIZE*.96,.16) if is_wall else (Vector3(WALL_SIZE*.99,.18,WALL_SIZE*.99) if is_floor else Vector3(1.05,.84,.8))
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(Vector3.UP,yaw),point+Vector3.UP*(WALL_SIZE*.5 if is_wall else (.01 if is_floor else .48)))
	if kind=="carpentry_bench":
		shape.size = Vector3(1.56,1.02,.84)
		query.transform = Transform3D(Basis(Vector3.UP,yaw),point+Vector3.UP*.54)
	if is_stair:
		shape.size = Vector3(.95,.18,.23)
		query.transform = Transform3D(Basis(Vector3.UP,yaw),point+Vector3.UP*.15)
	query.collision_mask = (TARGET|4) if is_floor and build_level==0 else SOLID|TARGET|4
	var excluded: Array[RID] = []
	for obj in objects.values():
		if is_instance_valid(obj) and obj is CollisionObject3D:
			var object_kind := str(obj.get_meta("kind",""))
			if (is_wall or is_floor) and object_kind in ["wood_wall","wood_doorway","wood_window","wood_floor"]:
				excluded.append(obj.get_rid())
			elif not is_wall and not is_floor and object_kind=="wood_floor" and absf(obj.global_position.y+.116-point.y)<.04:
				excluded.append(obj.get_rid())
	query.exclude = excluded
	valid = valid and get_world_3d().direct_space_state.intersect_shape(query,12).is_empty()
	return {"kind":kind,"point":point,"yaw":yaw,"level":build_level if is_wall or is_floor else 0,"valid":valid}

func update_construction_ghost() -> void:
	var item: int = bar_items[selected]
	if not moving or item not in [BENCH_ITEM,BENCH2_ITEM,FIRE_ITEM,WALL_ITEM,DOORWAY_ITEM,WINDOW_ITEM,FLOOR_ITEM,CHEST_ITEM,30,31,32,CARPENTRY_ITEM] or stock[item]<=0:
		if is_instance_valid(construction_ghost):
			construction_ghost.hide()
		construction_preview = {}
		return
	var kind: String = ITEM_KINDS[item]
	construction_preview = construction_candidate(kind)
	if not is_instance_valid(construction_ghost) or construction_ghost.get_meta("kind","")!=kind:
		if is_instance_valid(construction_ghost):
			construction_ghost.queue_free()
		var ghost := StaticBody3D.new()
		ghost.collision_layer = 0
		ghost.collision_mask = 0
		ghost.set_meta("kind",kind)
		add_child(ghost)
		ghost.global_position = construction_preview["point"]
		if kind=="carpentry_bench":
			build_carpentry_bench(ghost)
		elif kind in STAIR_KINDS:
			build_stairs(ghost,kind)
			ghost.collision_layer = 0
		elif kind=="chest":
			preload("res://chest_model.gd").build(ghost)
		elif kind=="wood_floor":
			build_wood_floor(ghost)
		elif kind in ["wood_wall","wood_doorway","wood_window"]:
			build_wood_wall(ghost,kind)
		else:
			box(ghost,Vector3.UP*.45,Vector3(1.05,.84,.8),"construction_preview",Color.WHITE)
		for child in ghost.get_children():
			if child is CollisionShape3D:
				child.disabled = true
			elif child is MeshInstance3D and child.name.begins_with("wall_foundation"):
				child.hide()
		construction_ghost = ghost
	construction_ghost.show()
	construction_ghost.global_position = construction_preview["point"]
	construction_ghost.rotation.y = construction_preview["yaw"]
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(.25,1,.45,.38) if construction_preview["valid"] else Color(1,.22,.18,.38)
	for child in construction_ghost.get_children():
		if child is MeshInstance3D:
			child.material_override = mat

func place_craft(kind: String) -> bool:
	if net_role=="client" and not net_world_ready:
		return false
	var candidate := construction_preview if construction_preview.get("kind","")==kind else construction_candidate(kind)
	if not candidate.get("valid",false):
		notice("Escolha uma superfície livre e com apoio.")
		return false
	build_level = int(candidate["level"])
	store_object(kind,candidate["point"],candidate["yaw"],build_level)
	construction_preview = {}
	return true

func toggle_stock(i: int) -> void:
	if reserve[i]:
		stock[i] += reserve[i]
		reserve[i] = 0
		item_received(i)
	else:
		reserve[i] = stock[i]
		stock[i] = 0
	save_game()
	show_inventory()

func construction_level_name() -> String:
	return ["piso térreo","teto térreo / piso 2","teto 2 / piso 3","teto do 3"][build_level]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:
			if moving:
				show_menu()
			else:
				begin()
			get_viewport().set_input_as_handled()
			return
		if event.keycode==KEY_E and (moving or inventory):
			if inventory:
				begin()
			else:
				show_inventory()
			return
		if not moving:
			return
		match event.keycode:
			KEY_SPACE: jump = true
			KEY_Q: drop_selected()
			KEY_C: show_inventory()
			KEY_R:
				if bar_items[selected] in [WALL_ITEM,DOORWAY_ITEM,WINDOW_ITEM,CHEST_ITEM,30,31,32,CARPENTRY_ITEM]:
					build_rotation = (build_rotation+1)%4
					notice("Rotação: %d°" % (build_rotation*90))
				else:
					eat()
			KEY_F: primary()
			KEY_V: toggle_view()
			KEY_PAGEUP:
				build_level = mini(build_level+1,BUILD_MAX_LEVEL)
				notice("Altura selecionada: %s" % construction_level_name())
			KEY_PAGEDOWN:
				build_level = maxi(build_level-1,0)
				notice("Altura selecionada: %s" % construction_level_name())
			KEY_T:
				if bar_items[selected]==FLOOR_ITEM:
					build_level = (build_level+1)%(BUILD_MAX_LEVEL+1)
					notice("Painel selecionado: %s" % construction_level_name())
				else:
					build_rotation = (build_rotation+1)%4
					notice("Girar parede: %d°" % (build_rotation*90))
		if event.keycode>=KEY_1 and event.keycode<=KEY_9:
			selected = event.keycode-KEY_1
	if not moving:
		return
	if event is InputEventMouseMotion:
		player.rotate_y(-event.relative.x*.0025)
		camera.rotation.x = clampf(camera.rotation.x-event.relative.y*.0025,-1.42,1.42)
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT: primary()
			MOUSE_BUTTON_RIGHT: secondary()
			MOUSE_BUTTON_WHEEL_UP: selected = posmod(selected-1,HOTBAR_SIZE)
			MOUSE_BUTTON_WHEEL_DOWN: selected = posmod(selected+1,HOTBAR_SIZE)

# Sobe apenas pequenos degraus de piso, sem impulso de salto.
func try_character_step(character: CharacterBody3D, dt: float) -> void:
	if not character.is_on_floor() or character.velocity.y>0.0:
		return
	var motion := Vector3(character.velocity.x,0,character.velocity.z)*dt
	if motion.length()<.001:
		return
	var start := character.global_transform
	var obstacle := KinematicCollision3D.new()
	if not character.test_move(start,motion,obstacle):
		return
	var body := obstacle.get_collider() as Node3D
	if body==null or str(body.get_meta("kind","")) not in ["wood_floor","stairs_straight","stairs_l"]:
		return
	var rise := Vector3.UP*.32
	if character.test_move(start,rise):
		return
	var raised := start
	raised.origin += rise
	if character.test_move(raised,motion):
		return
	raised.origin += motion
	var landing := KinematicCollision3D.new()
	if not character.test_move(raised,Vector3.DOWN*.38,landing):
		return
	var support := landing.get_collider() as Node3D
	if support==null or str(support.get_meta("kind","")) not in ["wood_floor","stairs_straight","stairs_l"]:
		return
	if landing.get_normal().dot(Vector3.UP)<.7:
		return
	var step_height := rise.y+landing.get_travel().y
	if step_height<=.008 or step_height>.32:
		return
	# Apenas a altura muda: move_and_slide executa o movimento horizontal normal.
	character.global_position += Vector3.UP*(step_height+.003)
	character.velocity.y = 0.0

func nearby_ladder() -> Node3D:
	for obj in objects.values():
		if not is_instance_valid(obj) or str(obj.get_meta("kind",""))!="ladder":
			continue
		var local := (obj as Node3D).to_local(player.global_position)
		if absf(local.x)<.58 and absf(local.z)<.65 and local.y>-.25 and local.y<WALL_SIZE+.15:
			return obj
	return null

func _physics_process(dt: float) -> void:
	elapsed += dt
	update_npc_daylight(dt)
	if moving:
		var input_axis := movement_axis()
		var crouch := update_crouch(Input.is_physical_key_pressed(KEY_X) or Input.is_key_pressed(KEY_X))
		var in_water := player_in_water()
		var running := sprint_step(not in_water and not crouch and input_axis.y<0 and (Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_SHIFT)),dt)
		var speed := 2.4 if in_water else 2. if crouch else RUN_SPEED if running else WALK_SPEED
		var requested := player.basis*Vector3(input_axis.x,0,input_axis.y)*speed
		player.velocity.x = move_toward(player.velocity.x,requested.x,dt*28)
		player.velocity.z = move_toward(player.velocity.z,requested.z,dt*28)
		if in_water:
			# Espaco sobe/nada; X afunda; sem comando o corpo afunda devagar.
			var swim_up := Input.is_physical_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SPACE)
			var swim_down := Input.is_physical_key_pressed(KEY_X) or Input.is_key_pressed(KEY_X)
			var swim_vertical := 3.2 if swim_up else -2.2 if swim_down else -0.42
			player.velocity.y = move_toward(player.velocity.y,swim_vertical,dt*7.0)
		elif not player.is_on_floor():
			player.velocity.y -= dt*15
		elif jump and not crouch:
			player.velocity.y = 5.2
		var ladder := nearby_ladder()
		if ladder!=null and not in_water and absf(input_axis.y)>.1:
			player.velocity.y = -input_axis.y*1.8
			player.velocity.x = 0.0
			player.velocity.z = 0.0
		elif not in_water and not jump:
			try_character_step(player,dt)
		jump = false
		player.move_and_slide()
		if not in_water and ladder==null and player.velocity.y<=0.0:
			player.apply_floor_snap()
		# Nao ha cavernas: nunca permitir um save antigo ou uma falha de fisica
		# deixar a camera abaixo do relevo.
		var ground_level := ground(player.position.x,player.position.z)
		if player.position.y < ground_level-.18:
			player.position.y = ground_level+.65
			player.velocity.y = 0.0
		# O jogador pode mergulhar ate o leito; oxigenio e dano sao locais
		# a cada personagem, inclusive em partidas multiplayer.
		update_breath(dt)
		animate_npc_model(player_model,player.get_real_velocity(),dt,player.is_on_floor())
		eye_height = move_toward(eye_height,.96 if crouch else 1.49,dt*4.5)
		update_camera()
		var cell := chunk_from_position(player.global_position)
		if cell!=get_meta("chunk_center",Vector2i(100000,100000)):
			set_meta("chunk_center",cell)
			load_chunks()
		if net_role!="client":
			update_wolf_spawns(dt)
			update_mobs(dt)
		if elapsed>next_save:
			next_save = elapsed+8
			save_game()
	update_construction_ghost()
	# Animacao continua em idle nos menus; clientes interpolam animacoes recebidas da rede.
	if not moving:
		animate_npc_model(player_model,Vector3.ZERO,dt,true)
	if net_role=="client":
		for npc in villagers:
			if is_instance_valid(npc):
				var net_vel: Vector3 = npc.get_meta("net_animation_velocity",Vector3.ZERO)
				animate_npc_model(npc.get_node("Visual"),net_vel,dt,true)
				npc.set_meta("net_animation_velocity",net_vel.move_toward(Vector3.ZERO,dt*3.5))
		for mob in mobs:
			if is_instance_valid(mob) and str(mob.get_meta("kind",""))=="guardian":
				var net_vel: Vector3 = mob.get_meta("net_animation_velocity",Vector3.ZERO)
				animate_npc_model(mob.get_node("Visual"),net_vel,dt,true)
				mob.set_meta("net_animation_velocity",net_vel.move_toward(Vector3.ZERO,dt*3.5))
	if net_role!="client":
		update_villagers(dt)
	tree_regrowth_clock += dt
	if tree_regrowth_clock >= 2.0:
		tree_regrowth_clock = 0.0
		update_regrowing_trees()
		update_all_tomato_crops()
		update_tomato_fruit_regrowth()
	if net_role!="solo" and multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status()==MultiplayerPeer.CONNECTION_CONNECTED and elapsed>next_net:
		next_net = elapsed+.10
		if net_role=="host" or net_connected:
			send_position.rpc(player.global_position,player.rotation.y,player_equipment_mask())
	if net_role=="host" and multiplayer.get_peers().size()>0:
		net_entities_clock += dt
		if net_entities_clock>=.15:
			net_entities_clock = 0.0
			net_sync_entities.rpc(net_capture_entities())
	for remote in remotes.values():
		var destination: Vector3 = remote.get_meta("destination",remote.position)
		var next: Vector3 = remote.position.lerp(destination,1.-exp(-dt*16.))
		animate_npc_model(remote.get_child(0),(next-remote.position)/maxf(dt,.001),dt,true)
		remote.position = next
	var held: int = bar_items[selected]
	spear.visible = not third_person and held in [0,8]
	if spear.visible:
		spear_tip.material_override = materials["rock"] if held==0 else material("wood",Color("#855b36"))
	axe.visible = not third_person and held in [WOOD_AXE,STONE_AXE,SHOVEL_ITEM,SPIKED_CLUB,WOOD_PICKAXE,STONE_PICKAXE]
	wood_axe_head.visible = held==WOOD_AXE
	# Machado de pedra aprovado: usar a arte dedicada, e nao a malha
	# volumosa de rocha que escondia o formato correto na primeira pessoa.
	stone_axe_head.visible = false
	shovel_head.visible = axe.visible and held==SHOVEL_ITEM
	spiked_club_head.visible = axe.visible and held==SPIKED_CLUB
	wood_pickaxe_head.visible = axe.visible and held==WOOD_PICKAXE
	stone_pickaxe_head.visible = axe.visible and held==STONE_PICKAXE
	stone_axe_sprite.visible = axe.visible and held==STONE_AXE
	# O sprite do machado de pedra ja inclui cabo; somente a pa usa o cabo 3D compartilhado.
	axe.get_node("CaboMachadoMadeira").visible = false
	# Corte frontal: preparacao elevada, descida rapida com o fio, retorno neutro.
	var chop_t := 1.0-clampf((next_attack-elapsed)/.46,0.0,1.0)
	var chop_angle := -.44
	if next_attack>elapsed:
		if chop_t<.25:
			chop_angle = lerpf(-.44,-1.35,chop_t/.25)
		elif chop_t<.67:
			chop_angle = lerpf(-1.35,.60,(chop_t-.25)/.42)
		else:
			chop_angle = lerpf(.60,-.44,(chop_t-.67)/.33)
	axe.rotation = Vector3(chop_angle,0.0,-.08)
	axe.position = Vector3(.40,-.43,-.76) + Vector3(0.0,.07,-.09)*sin(chop_t*PI) if next_attack>elapsed else Vector3(.40,-.43,-.76)
	spear.position.z = -.77-sin(clampf((next_attack-elapsed)/.46,0,1)*PI)*.31
	if elapsed>feedback_until and moving:
		feedback = ""
	hud.text = "Clareira dos Goblins  ·  "+("Vale conquistado" if won else "Explore o vale" if hut else "Construa a bancada e o abrigo")
	if net_role=="host":
		hud.text += "  ·  Rede: anfitrião (%d conectados)" % multiplayer.get_peers().size()
	elif net_role=="client":
		hud.text += "  ·  Rede: conectado" if net_connected else "  ·  Rede: conectando..."
	update_player_hud()
	if moving and elapsed>=next_interaction_hint:
		next_interaction_hint = elapsed+.12
		var hit := ray()
		interaction_hint = "E Inventário  ·  Esc Menu"
		if bar_items[selected] in [WALL_ITEM,DOORWAY_ITEM,WINDOW_ITEM,FLOOR_ITEM,CHEST_ITEM,30,31,32,CARPENTRY_ITEM]:
			interaction_hint = "Aponte para posicionar · Clique: instalar · R: girar"
		if not hit.is_empty() and bar_items[selected] not in [WALL_ITEM,DOORWAY_ITEM,WINDOW_ITEM,FLOOR_ITEM]:
			match hit["collider"].get_meta("kind",""):
				"bench","bench2": interaction_hint = "Botão direito · Usar bancada de trabalho"
				"carpentry_bench": interaction_hint = "Botão direito · Usar marcenaria 5 × 5"
				"chest": interaction_hint = "Botão direito · Abrir baú"
				"vine_bush": interaction_hint = "Botão direito · Colher cipó"
				"tomato_plant","tomato_crop": interaction_hint = "Botão direito · Colher 1 tomate · Pá para retirar pé"
				"Bruma": interaction_hint = "Botão direito · Conversar com Bruma"
				"Talo": interaction_hint = "Botão direito · Conversar com Talo"
				"stump": interaction_hint = "Pá + clique esquerdo · desenterrar toco"
	hint.text = feedback if not feedback.is_empty() else interaction_hint
	if player.position.y < -12:
		respawn()

func update_crouch(requested: bool) -> bool:
	var col := player.get_node("Corpo") as CollisionShape3D
	var capsule := col.shape as CapsuleShape3D
	if not requested and capsule.height < 1.64:
		var clearance := BoxShape3D.new()
		clearance.size = Vector3(.52,.59,.52)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = clearance
		query.transform.origin = player.global_position+Vector3.UP*1.35
		query.collision_mask = SOLID
		requested = not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
	var height := 1.06 if requested else 1.64
	if not is_equal_approx(capsule.height,height):
		capsule.height = height
		col.position.y = height/2
	return requested

func update_wolf_spawns(dt: float) -> void:
	# Um lobo aparece numa area segura da floresta depois de poucos segundos.
	# Nao exige mais andar 20 m e esperar dois minutos para encontra-lo.
	if is_instance_valid(roaming_wolf) and not roaming_wolf.is_queued_for_deletion():
		if nearest_player_distance(roaming_wolf.position)>43.0:
			roaming_wolf.queue_free()
			wolf_spawn_timer = 12.0
		return
	wolf_spawn_timer -= dt
	if wolf_spawn_timer>0.0:
		return
	var space := get_world_3d().direct_space_state
	var clearance := SphereShape3D.new()
	clearance.radius = .48
	for attempt in range(24):
		var offset := Vector3.FORWARD.rotated(Vector3.UP,randf()*TAU)*randf_range(15.,22.)
		var position := player.position+offset
		if Vector2(position.x,position.z).length()<12.0 or TERRAIN.is_river(position.x,position.z):
			continue
		var h := ground(position.x,position.z)
		if absf(ground(position.x+.65,position.z)-h)>.46 or absf(ground(position.x,position.z+.65)-h)>.46:
			continue
		position.y = h+.06
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = clearance
		query.transform.origin = position+Vector3.UP*.85
		query.collision_mask = SOLID|TARGET|4
		query.exclude = [player.get_rid()]
		if not space.intersect_shape(query,1).is_empty():
			continue
		roaming_wolf = creature("wolf","lobo-errante",position,self)
		roaming_wolf.set_meta("wolf_home",position)
		roaming_wolf.set_meta("wander_direction",Vector3.FORWARD.rotated(Vector3.UP,randf()*TAU))
		wolf_spawn_timer = randf_range(50.0,80.0)
		return
	wolf_spawn_timer = 8.0

func mob_has_clear_hit(mob: CharacterBody3D) -> bool:
	# Raycast separado do calculo horizontal: evita ataques atraves do terreno
	# e de paredes. O primeiro alvo atingido deve ser o corpo do jogador.
	if not is_instance_valid(mob) or not is_instance_valid(player):
		return false
	var begin_ray := mob.global_position+Vector3.UP*.85
	var end_ray := player.global_position+Vector3.UP*.85
	var query := PhysicsRayQueryParameters3D.create(
		begin_ray,end_ray,SOLID|4,[mob.get_rid()])
	var contact := get_world_3d().direct_space_state.intersect_ray(query)
	return not contact.is_empty() and contact.get("collider",null)==player


func update_mobs(dt: float) -> void:
	for i in range(mobs.size()-1,-1,-1):
		var mob := mobs[i]
		if not is_instance_valid(mob) or mob.is_queued_for_deletion():
			mobs.remove_at(i)
			continue
		var target_id := nearest_player_id(mob.global_position)
		var target_pos: Vector3 = player.global_position if target_id==1 else (remotes[target_id].global_position if remotes.has(target_id) else player.global_position)
		var npc_target: CharacterBody3D
		if mob.get_meta("kind","")=="wolf":
			var nearest: float = target_pos.distance_to(mob.global_position)
			for candidate in villagers:
				if not is_instance_valid(candidate) or candidate.is_queued_for_deletion() or elapsed<float(candidate.get_meta("recover_until",0.0)):
					continue
				var d: float = candidate.global_position.distance_to(mob.global_position)
				if d<nearest and d<10.0:
					nearest = d
					npc_target = candidate
			if is_instance_valid(npc_target):
				target_pos = npc_target.global_position
		var direction: Vector3 = target_pos-mob.global_position
		direction.y = 0
		var distance: float = direction.length()
		if distance>28:
			continue
		var kind: String = mob.get_meta("kind")
		var speed := 0.0
		if kind=="rabbit":
			update_rabbit(mob,direction,distance,dt)
			continue
		var wander := Vector3.ZERO
		if kind=="wolf" and distance>=10.0:
			var home: Vector3 = mob.get_meta("wolf_home",mob.position)
			if elapsed>=float(mob.get_meta("wolf_next_turn",0.0)) or mob.is_on_wall() or mob.position.distance_to(home)>13.0:
				wander = (home-mob.position).normalized() if mob.position.distance_to(home)>13.0 else Vector3.FORWARD.rotated(Vector3.UP,randf()*TAU)
				wander.y = 0.0
				mob.set_meta("wander_direction",wander)
				mob.set_meta("wolf_next_turn",elapsed+randf_range(2.0,5.0))
			wander = mob.get_meta("wander_direction",Vector3.FORWARD)
			speed = 1.15
		if distance<10:
			speed = 2.25
			# Inimigos soterrados, em outro nivel ou atras de objetos
			# nao devem causar dano apenas pela distancia horizontal.
			if distance<1.35 and absf(target_pos.y-mob.global_position.y)<1.35:
				if is_instance_valid(npc_target):
					if elapsed>=float(mob.get_meta("npc_bite_at",0.0)) and npc_clear_combat_hit(mob,npc_target):
						mob.set_meta("npc_bite_at",elapsed+1.0)
						npc_target.set_meta("attacker_id",str(mob.get_meta("id","")))
						var hp := maxi(0,int(npc_target.get_meta("npc_health",100))-15)
						npc_target.set_meta("npc_health",hp)
						if hp<=0:
							npc_target.set_meta("recover_until",elapsed+30.0)
							npc_target.set_meta("npc_health",100)
							npc_target.set_meta("attacker_id","")
				elif target_id==1 and elapsed>next_hurt and mob_has_clear_hit(mob):
					next_hurt = elapsed+1.0
					health -= 15 if kind=="wolf" else 23
					if health<=0:
						respawn()
				elif target_id>1 and elapsed-float(net_last_hurt_by_peer.get(target_id,-100.0))>1.0:
					net_last_hurt_by_peer[target_id] = elapsed
					net_receive_damage.rpc_id(target_id,15 if kind=="wolf" else 23)
		if elapsed<float(mob.get_meta("stagger_until",0.0)):
			speed = 0.0
		var stride: Vector3 = (wander if kind=="wolf" and distance>=10.0 else direction.normalized())*speed
		mob.velocity.x = stride.x
		mob.velocity.z = stride.z
		if stride.length_squared()>.01:
			# Goblins GLB olham para +Z; animais mantem orientacao original -Z.
			mob.rotation.y = atan2(stride.x,stride.z) if kind=="guardian" else atan2(-stride.x,-stride.z)
		if not mob.is_on_floor():
			mob.velocity.y -= dt*15
		if kind=="guardian":
			try_character_step(mob,dt)
		mob.move_and_slide()
		if kind=="guardian" and mob.velocity.y<=0.0:
			mob.apply_floor_snap()
		var mob_visual: Node3D = mob.get_node("Visual")
		walk_pose(mob_visual,mob.get_real_velocity(),dt,mob.is_on_floor())
		if kind=="guardian":
			animate_npc_model(mob_visual,mob.get_real_velocity(),dt,mob.is_on_floor())

func update_rabbit(mob: CharacterBody3D, toward_player: Vector3, distance: float, dt: float) -> void:
	var fleeing := distance<6.0
	var startled := fleeing and not bool(mob.get_meta("fleeing",false))
	mob.set_meta("fleeing",fleeing)
	if not mob.is_on_floor():
		mob.velocity.y -= dt*15.
	elif elapsed<float(mob.get_meta("stagger_until",0.0)):
		mob.velocity = Vector3.ZERO
	elif startled or elapsed>=float(mob.get_meta("next_hop",0.0)):
		var heading: Vector3 = mob.get_meta("wander_direction",Vector3.FORWARD)
		if fleeing:
			if distance>.01:
				heading = -toward_player/distance
			heading = heading.rotated(Vector3.UP,randf_range(-.29,.29))
		elif elapsed>=float(mob.get_meta("next_turn",0.0)) or mob.is_on_wall():
			heading = Vector3.FORWARD.rotated(Vector3.UP,randf()*TAU)
			mob.set_meta("wander_direction",heading)
			mob.set_meta("next_turn",elapsed+randf_range(.9,2.8))
		var pace := RABBIT_ESCAPE_SPEED if fleeing else randf_range(.85,1.45)
		mob.velocity = heading*pace
		mob.velocity.y = 2.85 if fleeing else randf_range(1.35,1.75)
		mob.rotation.y = atan2(-heading.x,-heading.z)
		mob.set_meta("next_hop",elapsed+randf_range(.42,.53) if fleeing else elapsed+randf_range(.68,1.28))
	else:
		mob.velocity = Vector3.ZERO
	mob.move_and_slide()
	if mob.is_on_wall():
		mob.set_meta("next_turn",0.)
		mob.set_meta("next_hop",elapsed)
	walk_pose(mob.get_node("Visual"),mob.get_real_velocity(),dt,true)

func respawn() -> void:
	health = 100
	stamina = 100.0
	exhausted = false
	recovery_delay = 0.0
	breath = 100.0
	breath_recovery_delay = 0.0
	drowning_damage_clock = 0.0
	player.position = Vector3(0,.6,0)
	player.velocity = Vector3.ZERO
	notice("Você voltou à clareira.")

func toggle_view() -> void:
	third_person = not third_person
	player_model.visible = third_person
	if not third_person:
		camera.position = Vector3.UP*eye_height

func update_camera() -> void:
	var eye := Vector3.UP*eye_height
	if not third_person:
		camera.position = eye
		return
	var shoulder := camera.basis.z*2.65+Vector3.RIGHT*.43
	var start := player.to_global(eye)
	var finish := player.to_global(eye+shoulder)
	var q := PhysicsRayQueryParameters3D.create(start,finish,SOLID,[player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var fraction := 1.0
	if not hit.is_empty():
		var position: Vector3 = hit["position"]
		fraction = clampf((start.distance_to(position)-.14)/shoulder.length(),0.,1.)
	camera.position = eye+shoulder*fraction
	player_model.visible = fraction>.22

func ray(distance := 3.5) -> Dictionary:
	var start := camera.global_position
	var direction := -camera.global_basis.z
	var eye := player.to_global(Vector3.UP*eye_height)
	var camera_offset := eye.distance_to(start) if third_person else 0.0
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(start,start+direction*(distance+camera_offset),SOLID|TARGET,[player.get_rid()])
	var hit := space.intersect_ray(query)
	if not third_person or hit.is_empty():
		return hit
	var destination: Vector3 = hit["position"]
	if eye.distance_to(destination)>distance+.15:
		return {}
	query.from = eye
	query.to = destination+eye.direction_to(destination)*.04
	return space.intersect_ray(query)

func primary() -> void:
	if elapsed<next_attack:
		return
	next_attack = elapsed+.46
	var held: int = bar_items[selected]
	if held in [BENCH_ITEM,BENCH2_ITEM,FIRE_ITEM,WALL_ITEM,DOORWAY_ITEM,WINDOW_ITEM,FLOOR_ITEM,CHEST_ITEM,30,31,32,CARPENTRY_ITEM] and stock[held]>0:
		if place_craft(ITEM_KINDS[held]):
			stock[held] -= 1
			if held in [BENCH_ITEM,BENCH2_ITEM]:
				bench = true
			sync_hotbar()
			save_game()
			notice("Baú colocado." if held==CHEST_ITEM else (("Painel colocado: %s." % construction_level_name()) if held==FLOOR_ITEM else ("Estrutura colocada no pavimento %d." % (build_level+1))))
		return
	var hit := ray()
	if hit.is_empty():
		return
	var o: Node3D = hit["collider"]
	var kind: String = o.get_meta("kind","")
	if held==TOMATO_SEED_ITEM and stock[TOMATO_SEED_ITEM]>0:
		if kind!="" or (hit["normal"] as Vector3).y<0.70:
			notice("Plante sementes em terra livre.")
			return
		var spot: Vector3 = hit["position"]
		spot.y = ground(spot.x,spot.z)
		if TERRAIN.is_river(spot.x,spot.z) or player.global_position.distance_to(spot)>6.0:
			notice("Procure terra seca perto de voce.")
			return
		for obj in objects.values():
			if is_instance_valid(obj) and str(obj.get_meta("kind","")) in ["tomato_crop","tomato_plant","tree","stump"] and obj.global_position.distance_to(spot)<1.15:
				notice("Ja existe vegetacao neste local.")
				return
		if net_role=="client":
			if not net_world_ready:
				notice("Aguarde a sincronizacao do mapa.")
				return
			net_request_plant_tomato.rpc_id(1,spot)
		else:
			plant_tomato_at(spot)
		stock[TOMATO_SEED_ITEM] -= 1
		sync_hotbar()
		save_game()
		notice("Semente plantada: tomates em 5 minutos.")
		return
	if held==SAPLING_ITEM and stock[SAPLING_ITEM]>0:
		if kind!="" or (hit["normal"] as Vector3).y < .60:
			notice("Plante a muda sobre um terreno livre.")
			return
		var spot: Vector3 = hit["position"]
		spot.y = ground(spot.x,spot.z)
		if TERRAIN.is_river(spot.x,spot.z) or spot.distance_to(player.position)<1.5:
			notice("Escolha um local seco e afastado.")
			return
		var clearance := SphereShape3D.new()
		clearance.radius = .50
		var check := PhysicsShapeQueryParameters3D.new()
		check.shape = clearance
		check.transform.origin = spot + Vector3.UP*1.0
		check.collision_mask = SOLID|TARGET
		check.exclude = [player.get_rid()]
		if not get_world_3d().direct_space_state.intersect_shape(check,1).is_empty():
			notice("Existe um obstáculo neste local.")
			return
		if net_role=="client":
			if not net_world_ready:
				notice("Aguarde a sincronizacao do mundo.")
				return
			net_request_plant_sapling.rpc_id(1,spot)
		else:
			plant_sapling_at(spot)
		stock[SAPLING_ITEM]-=1
		sync_hotbar()
		save_game()
		notice("Muda plantada! A árvore crescerá com o tempo.")
		return
	if kind in ["tomato_plant","tomato_crop"] and held==SHOVEL_ITEM:
		uproot_tomato(o)
		return
	if kind in ["stone","block"]:
		mine_stone(o,held,hit["position"],hit["normal"])
		return
	if kind=="chest":
		if chest_has_items(str(o.get_meta("id",""))):
			notice("Esvazie o baú antes de desmontar.")
			return
	if kind in ["chest","bench","bench2","carpentry_bench","fire","hut","wood_wall","wood_doorway","wood_window","wood_floor","stairs_straight","stairs_l","ladder"]:
		if held not in [WOOD_AXE,STONE_AXE]:
			notice("Use um machado para desmontar esta estrutura.")
			return
		if net_role=="client":
			if net_world_ready:
				use_tool(held)
				net_request_dismantle.rpc_id(1,str(o.get_meta("id","")),held)
			return
		use_tool(held)
		var hits: int = int(o.get_meta("break_hits",0))+(2 if held==STONE_AXE else 1)
		var needed := 12 if kind=="hut" else (4 if kind in ["wood_wall","wood_doorway","wood_window","wood_floor","bench2","carpentry_bench"] else (3 if kind=="bench" else 2))
		if hits<needed:
			o.set_meta("break_hits",hits)
			impact(hit["position"],hit["normal"],true)
			notice("Desmontando estrutura: %d/%d" % [hits,needed])
			return
		remove_object(o)
		var item_id := ITEM_KINDS.find(kind)
		if item_id>=0:
			stock[item_id] += 1
			item_received(item_id)
		bench = any_bench_placed()
		sync_hotbar()
		save_game()
		notice("Abrigo inicial removido deste mundo." if kind=="hut" else "Estrutura recuperada para o inventário.")
		return
	if o.has_meta("hp"):
		if bar_items[selected] not in [0,8,WOOD_AXE,STONE_AXE,SPIKED_CLUB]:
			notice("Equipe uma lança ou machado para atacar.")
			return
		if net_role=="client":
			if net_world_ready:
				var damage: int = 3 if held==SPIKED_CLUB else 2 if held==STONE_AXE else 1
				use_tool(held)
				net_request_hit_mob.rpc_id(1,str(o.get_meta("id","")),damage)
			return
		var hp := maxi(0, int(o.get_meta("hp"))-(3 if held==SPIKED_CLUB else 2 if held==STONE_AXE else 1))
		use_tool(held)
		o.set_meta("hp",hp)
		impact(hit["position"],hit["normal"],false)
		stagger(o,-camera.global_basis.z)
		o.set_meta("stagger_until",elapsed+.20)
		notice("%d pontos de vida restantes" % hp)
		if hp<=0:
			var pos := o.global_position
			remove_object(o)
			if kind=="guardian":
				won = true
				notice("Você conquistou o Vale da Névoa.")
			else:
				store_object("meat_rabbit" if kind=="rabbit" else "meat_wolf",pos)
				if kind=="wolf" and randf()<0.50:
					store_object("wolf_tooth",pos+Vector3(.36,0,0))
				if kind=="rabbit":
					store_object("hide",pos+Vector3(.41,0,0))
					if randf()<.05:
						store_object("foot",pos+Vector3(-.41,0,0))
		return
	if kind=="stump":
		dig_stump(o,held,hit["position"],hit["normal"])
		return
	if kind=="tree":
		chop_tree(o,held,hit["position"],hit["normal"])
		return
	if bar_items[selected]==2 and stock[2]>0 and (kind=="" or kind=="block" or kind=="stone"):
		var point: Vector3 = hit["position"]
		var normal: Vector3 = hit["normal"]
		var pos: Vector3
		if kind=="block" or kind=="stone":
			var axis := normal.abs().max_axis_index()
			var direction := Vector3.ZERO
			direction[axis] = signf(normal[axis])
			pos = o.global_position+direction*CELL
		else:
			pos = Vector3(snappedf(point.x,CELL),point.y,snappedf(point.z,CELL))
			pos.y = ground(pos.x,pos.z)
		var shape := BoxShape3D.new()
		shape.size = Vector3.ONE*(CELL-.035)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform.origin = pos+Vector3.UP*CELL*.52
		query.collision_mask = SOLID|4
		if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
			store_object("block",pos)
			stock[2] -= 1
		else:
			notice("Escolha um espaço livre para a pedra.")

func chop_tree(tree: Node3D, tool: int, pos: Vector3, normal: Vector3) -> bool:
	# Mao livre: 10 golpes, custa 2 de vida por golpe confirmado.
	# Machado de madeira: 5 golpes; machado de pedra: 4.
	if tool not in [-1,WOOD_AXE,STONE_AXE]:
		notice("Use a mão vazia ou um machado para cortar esta árvore.")
		return false
	if not is_instance_valid(tree) or str(tree.get_meta("kind",""))!="tree":
		return false
	if net_role=="client" and not net_apply_in_progress:
		if net_world_ready:
			use_tool(tool)
			net_request_chop_tree.rpc_id(1,str(tree.get_meta("id","")),tool)
		else:
			notice("Aguarde a sincronização do mundo.")
		return false
	if not net_apply_in_progress:
		use_tool(tool)
	var needed := 10 if tool==-1 else (4 if tool==STONE_AXE else 5)
	var cuts := int(tree.get_meta("cuts",0))+1
	if tool == -1:
		var remote_peer := int(tree.get_meta("damage_peer",0))
		if net_role=="host" and remote_peer>1:
			net_receive_damage.rpc_id(remote_peer,2)
		else:
			health = maxi(0,health-2)
			if health<=0:
				respawn()
	tree.set_meta("cuts",cuts)
	impact(pos,normal,true)
	if tool!=-1:
		play_tree_chop_sound(pos,tool)
	var tree_pos := tree.global_position
	var attacker_pos: Vector3 = tree.get_meta("fall_from",player.global_position)
	timber(tree,cuts>=needed)
	if net_role=="host" and not net_apply_in_progress:
		net_tree_chopped.rpc(str(tree.get_meta("id","")),cuts,cuts>=needed,float(tree_regrowth.get(str(tree.get_meta("id","")),0.0)),attacker_pos)
	if cuts>=needed:
		for i in range(3):
			store_object("log",tree_pos+Vector3((i-1)*.65,0,.39))
		# 50% de chance por arvore abatida: caem de 1 a 3 gravetos.
		if randf() < 0.50:
			var twigs := randi_range(1,3)
			for twig_index in range(twigs):
				var angle := TAU * float(twig_index) / float(twigs) + randf_range(-0.30,0.30)
				var radius := randf_range(0.85,1.45)
				var twig_pos := tree_pos + Vector3(cos(angle)*radius,0,sin(angle)*radius)
				store_object("stick",Vector3(twig_pos.x,ground(twig_pos.x,twig_pos.z)+0.06,twig_pos.z))
		if randf()<.35:
			store_object("sapling",tree_pos+Vector3(.82,0,.55))
		notice("Árvore derrubada. O mesmo tronco com raízes ficou no chão.")
		save_game()
		return true
	notice("Cortando a árvore: %d/%d golpes%s" % [cuts,needed," · -2 de vida" if tool==-1 else ""])
	return false


func dig_stump(stump: Node3D, tool: int, pos: Vector3, normal: Vector3) -> bool:
	if tool!=SHOVEL_ITEM:
		notice("Equipe a pá de madeira para desenterrar o toco e liberar espaço.")
		return false
	if not is_instance_valid(stump) or str(stump.get_meta("kind",""))!="stump":
		return false
	if net_role=="client" and not net_apply_in_progress:
		if net_world_ready:
			use_tool(tool)
			net_request_dig_stump.rpc_id(1,str(stump.get_meta("id","")),tool)
		else:
			notice("Aguarde a sincronização do mundo.")
		return false
	if not net_apply_in_progress:
		use_tool(tool)
	var digs := int(stump.get_meta("dig_hits",0))+1
	stump.set_meta("dig_hits",digs)
	impact(pos,normal,true)
	if digs<2:
		if net_role=="host":
			net_stump_dug.rpc(str(stump.get_meta("id","")),digs,false)
		notice("Arrancando raízes com a pá: 1/2")
		return false
	var stump_id: String = str(stump.get_meta("id",""))
	var age: float = Time.get_unix_time_from_system()-float(tree_regrowth.get(stump_id,0))
	var got_sapling := age>=TREE_BUD_DELAY and age<TREE_BUD_DELAY+TREE_GROW_SECONDS
	cleared_stumps[stump_id] = true
	tree_regrowth.erase(stump_id)
	if net_role=="host":
		net_stump_dug.rpc(stump_id,digs,true)
	remove_object(stump)
	stock[6] += 1
	item_received(6)
	if got_sapling:
		stock[SAPLING_ITEM] += 1
		item_received(SAPLING_ITEM)
	sync_hotbar()
	save_game()
	notice("Toco removido! +1 tronco" + (" e +1 muda" if got_sapling else "") + ".")
	return true


func mine_stone(rock: Node3D, tool: int, pos: Vector3, normal: Vector3) -> void:
	if tool not in [WOOD_PICKAXE,STONE_PICKAXE] or stock[tool]<=0:
		notice("Equipe uma picareta de madeira ou pedra para minerar.")
		return
	if net_role=="client":
		if net_world_ready:
			use_tool(tool)
			net_request_mine_stone.rpc_id(1,str(rock.get_meta("id","")),tool)
		else:
			notice("Aguarde a sincronização do mundo.")
		return
	use_tool(tool)
	apply_mining_hit(rock,tool,1)

func apply_mining_hit(rock: Node3D, tool: int, miner_peer: int) -> void:
	if not is_instance_valid(rock) or str(rock.get_meta("kind","")) not in ["stone","block"]:
		return
	var count: int = int(rock.get_meta("mine_hits",0))+1
	var required: int = 2 if tool==STONE_PICKAXE else 4
	rock.set_meta("mine_hits",count)
	impact(rock.global_position+Vector3.UP*0.4,Vector3.UP,true)
	if count<required:
		if miner_peer==1:
			notice("Minerando pedra: %d/%d golpes" % [count,required])
		else:
			net_mining_feedback.rpc_id(miner_peer,false,count,required)
		return
	remove_object(rock)
	if miner_peer==1:
		stock[2] += 1
		item_received(2)
		sync_hotbar()
		notice("Pedra minerada! +1 pedra.")
	else:
		net_mining_feedback.rpc_id(miner_peer,true,count,required)
	save_game()

@rpc("any_peer","call_remote","reliable")
func net_request_mine_stone(id: String, tool: int) -> void:
	if net_role!="host" or tool not in [WOOD_PICKAXE,STONE_PICKAXE] or not objects.has(id):
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id<=1 or not multiplayer.get_peers().has(peer_id):
		return
	var rock: Node3D = objects[id]
	if not is_instance_valid(rock) or str(rock.get_meta("kind","")) not in ["stone","block"] or not remote_can_interact(peer_id,rock.global_position,5.0):
		return
	apply_mining_hit(rock,tool,peer_id)

@rpc("authority","call_remote","reliable")
func net_mining_feedback(completed: bool, hits: int, required: int) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1:
		return
	if completed:
		stock[2] += 1
		item_received(2)
		sync_hotbar()
		notice("Pedra minerada! +1 pedra.")
	else:
		notice("Minerando pedra: %d/%d golpes" % [hits,required])

func collectible_item_for_kind(kind: String) -> int:
	if kind in ["meat_wolf","meat_rabbit"]:
		return 3
	if kind=="vine_bush":
		return VINE
	# Bancadas, estruturas, arvores e rochas exigem mecanicas proprias.
	if kind in ["tree","stump","stone","block","chest","bench","bench2","carpentry_bench","fire","hut","wood_wall","wood_doorway","wood_window","wood_floor","stairs_straight","stairs_l","ladder","tomato_plant","tomato_crop"]:
		return -1
	return ITEM_KINDS.find(kind)

func secondary() -> void:
	var hit := ray()
	if not hit.is_empty():
		var o: Node3D = hit["collider"]
		var kind: String = o.get_meta("kind","")
		var item := collectible_item_for_kind(kind)
		if kind=="tree_vine":
			harvest_tree_vine(o)
			return
		if kind in ["tomato_plant","tomato_crop"]:
			harvest_tomatoes(o)
			return
		if kind in ["Bruma","Talo"]:
			speak_to_goblin(o)
			return
		if kind=="chest":
			open_chest(o)
			return
		if kind=="carpentry_bench":
			open_craft("carpentry")
			return
		if kind in ["bench","bench2"]:
			station_level = 2 if kind=="bench2" else 1
			open_craft("station")
			return
		if kind in ["fire","wood_wall","wood_doorway","wood_window","wood_floor","stairs_straight","stairs_l","ladder"]:
			notice("Use um machado para desmontar esta estrutura.")
			return
		if kind in ["stone","block"]:
			notice("Não é possível pegar pedras com a mão. Use uma picareta.")
			return
		if item>=0:
			if net_role=="client":
				if net_world_ready:
					# Nao entregar itens antes de o servidor confirmar a retirada.
					net_request_collect.rpc_id(1,str(o.get_meta("id","")))
				else:
					notice("Aguarde a sincronizacao do mundo.")
				return
			stock[item] += 2 if kind=="vine_bush" else 1
			item_received(item)
			sync_hotbar()
			remove_object(o)
			notice("Você recolheu "+ITEMS[item].to_lower()+".")
			return
		if kind=="Bruma" or kind=="Talo":
			notice("Monte uma bancada e um abrigo com os materiais da floresta.")
			return
	if bar_items[selected]==TOMATO_ITEM:
		eat_tomato()
	elif bar_items[selected]==3:
		eat()

@rpc("any_peer","call_remote","reliable")
func net_request_collect(id: String) -> void:
	if net_role!="host" or not objects.has(id):
		return
	var peer_id := multiplayer.get_remote_sender_id()
	var obj: Node3D = objects[id]
	if not is_instance_valid(obj) or not remote_can_interact(peer_id,obj.global_position,5.5):
		return
	var kind := str(obj.get_meta("kind",""))
	var item := collectible_item_for_kind(kind)
	if item<0:
		return
	var amount := 2 if kind=="vine_bush" else 1
	remove_object(obj) # atualiza mundo persistido e notifica todos os clientes
	net_collect_reward.rpc_id(peer_id,item,amount)
	save_game()

@rpc("authority","call_remote","reliable")
func net_collect_reward(item: int, amount: int) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1:
		return
	if item<0 or item>=ITEMS.size() or amount<1 or amount>2:
		return
	stock[item] += amount
	item_received(item)
	sync_hotbar()
	save_game()
	notice("Você recolheu "+ITEMS[item].to_lower()+".")

func any_bench_placed() -> bool:
	for entry in placed:
		if entry["kind"] in ["bench","bench2"]:
			return true
	return false

func drop_selected() -> void:
	var item: int = bar_items[selected]
	if item<0 or stock[item]==0:
		return
	if item==BACKPACK_ITEM and backpack_equipped:
		notice("Retire a mochila antes de largá-la.")
		return
	if item in [BENCH_ITEM,BENCH2_ITEM,FIRE_ITEM,WALL_ITEM,DOORWAY_ITEM,WINDOW_ITEM,FLOOR_ITEM,CHEST_ITEM,30,31,32,CARPENTRY_ITEM]:
		if place_craft(ITEM_KINDS[item]):
			stock[item] -= 1
			if item in [BENCH_ITEM,BENCH2_ITEM]:
				bench = true
			sync_hotbar()
			save_game()
		return
	var p := player.position-player.basis.z*1.2
	p.y = construction_surface(p,player.position.y+.35)
	store_object(ITEM_KINDS[item],p)
	stock[item] -= 1

func eat_tomato() -> void:
	if stock[TOMATO_ITEM]>0 and health<100:
		stock[TOMATO_ITEM] -= 1
		health = mini(100,health+TOMATO_HEAL)
		sync_hotbar()
		save_game()
		notice("Tomate consumido: +%d de vida." % TOMATO_HEAL)

func update_tomato_crop(crop: Node3D) -> void:
	if not is_instance_valid(crop):
		return
	var visual := crop.get_node_or_null("Horta") as Node3D
	if visual==null:
		return
	var id := str(crop.get_meta("id",""))
	var planted := float(tomato_crop_times.get(id,Time.get_unix_time_from_system()))
	var age := maxf(0.0,Time.get_unix_time_from_system()-planted)
	var progress := clampf(age/TOMATO_GROW_SECONDS,0.0,1.0)
	visual.scale = Vector3.ONE*lerpf(0.18,1.0,progress)
	crop.set_meta("ready",progress>=1.0)

func update_all_tomato_crops() -> void:
	for id in tomato_crop_times.keys():
		if objects.has(id):
			update_tomato_crop(objects[id])

func plant_sapling_at(pos: Vector3) -> void:
	var tree_id := "item-" + str(Time.get_ticks_usec()) + "-" + str(randi())
	var regrowth_time := Time.get_unix_time_from_system()-TREE_BUD_DELAY-1.0
	placed.append({"kind":"tree","id":tree_id,"p":[pos.x,pos.y,pos.z],"r":0.0})
	tree_regrowth[tree_id] = regrowth_time
	spawn_object("tree",tree_id,pos,self)
	if net_role=="host":
		net_shared_place.rpc("tree",tree_id,pos,0.0,0)
		net_sapling_planted.rpc(tree_id,regrowth_time)
	save_game()

@rpc("any_peer","call_remote","reliable")
func net_request_plant_sapling(pos: Vector3) -> void:
	if net_role!="host" or not pos.is_finite():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if not remote_can_interact(peer_id,pos,6.0):
		return
	if TERRAIN.is_river(pos.x,pos.z) or absf(ground(pos.x,pos.z)-pos.y)>.3:
		return
	for obj in objects.values():
		if is_instance_valid(obj) and str(obj.get_meta("kind","")) in ["tree","stump","tomato_crop","tomato_plant","wood_wall","wood_floor"] and obj.global_position.distance_to(pos)<1.15:
			return
	plant_sapling_at(pos)

@rpc("authority","call_remote","reliable")
func net_sapling_planted(id: String,regrowth_time: float) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1 or not net_world_ready:
		return
	tree_regrowth[id] = regrowth_time
	if objects.has(id):
		update_tree_visual(objects[id])

func plant_tomato_at(pos: Vector3) -> void:
	if net_role=="client":
		return
	store_object("tomato_crop",pos)
	for entry in placed:
		if str(entry.get("kind",""))!="tomato_crop":
			continue
		var p: Array = entry["p"]
		if Vector3(float(p[0]),float(p[1]),float(p[2])).distance_to(pos)<0.01:
			var id := str(entry["id"])
			if not tomato_crop_times.has(id):
				tomato_crop_times[id] = Time.get_unix_time_from_system()
				if objects.has(id):
					update_tomato_crop(objects[id])
				if net_role=="host":
					net_tomato_crop_time.rpc(id,float(tomato_crop_times[id]))
				break
	save_game()

@rpc("any_peer","call_remote","reliable")
func net_request_plant_tomato(pos: Vector3) -> void:
	if net_role!="host" or not pos.is_finite():
		return
	var peer := multiplayer.get_remote_sender_id()
	var avatar: Node3D = remotes.get(peer,null)
	if not remote_can_interact(peer,pos,6.0):
		return
	if TERRAIN.is_river(pos.x,pos.z) or absf(ground(pos.x,pos.z)-pos.y)>0.3:
		return
	for obj in objects.values():
		if is_instance_valid(obj) and str(obj.get_meta("kind","")) in ["tomato_crop","tomato_plant","tree","stump"] and obj.global_position.distance_to(pos)<1.15:
			return
	plant_tomato_at(pos)

@rpc("authority","call_remote","reliable")
func net_tomato_crop_time(id: String, planted: float) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1:
		return
	tomato_crop_times[id] = planted
	if objects.has(id):
		update_tomato_crop(objects[id])

func tomato_available(plant: Node3D) -> int:
	var id := str(plant.get_meta("id",""))
	var state: Dictionary = tomato_fruits.get(id,{})
	return clampi(int(state.get("count",TOMATO_MAX_FRUITS)),0,TOMATO_MAX_FRUITS)

func update_tomato_fruits(plant: Node3D) -> void:
	if not is_instance_valid(plant):
		return
	var id := str(plant.get_meta("id",""))
	var visual: Node3D = plant.get_node_or_null("Horta") as Node3D
	if visual==null:
		visual = plant
	var count := tomato_available(plant)
	var fruits: Array[Node3D] = []
	for child in visual.get_children():
		if child is Node3D and str(child.name).begins_with("Fruto_"):
			fruits.append(child)
	# A ordem e estavel; separar a fruta de sua estrela verde permite ocultar 1 por vez.
	for i in range(fruits.size()):
		fruits[i].visible = i<count

func take_one_tomato(plant: Node3D) -> bool:
	if not is_instance_valid(plant) or str(plant.get_meta("kind","")) not in ["tomato_plant","tomato_crop"]:
		return false
	if str(plant.get_meta("kind",""))=="tomato_crop" and not bool(plant.get_meta("ready",false)):
		return false
	var available := tomato_available(plant)
	if available<=0:
		return false
	var id := str(plant.get_meta("id",""))
	var now := Time.get_unix_time_from_system()
	var state: Dictionary = tomato_fruits.get(id,{"count":TOMATO_MAX_FRUITS,"next":now+TOMATO_FRUIT_SECONDS})
	state["count"] = available-1
	if available==TOMATO_MAX_FRUITS or float(state.get("next",0.0))<=0.0:
		state["next"] = now+TOMATO_FRUIT_SECONDS
	tomato_fruits[id] = state
	update_tomato_fruits(plant)
	if net_role=="host":
		net_tomato_fruit_state.rpc(id,state)
	return true

func update_tomato_fruit_regrowth() -> void:
	if net_role=="client":
		return
	var now := Time.get_unix_time_from_system()
	for id in tomato_fruits.keys():
		var state: Dictionary = tomato_fruits[id]
		var count := clampi(int(state.get("count",TOMATO_MAX_FRUITS)),0,TOMATO_MAX_FRUITS)
		if count>=TOMATO_MAX_FRUITS:
			continue
		var next_time := float(state.get("next",now+TOMATO_FRUIT_SECONDS))
		if now<next_time:
			continue
		# Ate se o mundo ficou fechado, cada fruto exige seu proprio intervalo.
		var steps := mini(TOMATO_MAX_FRUITS-count,1+int((now-next_time)/TOMATO_FRUIT_SECONDS))
		state["count"] = count+steps
		state["next"] = next_time+float(steps)*TOMATO_FRUIT_SECONDS
		tomato_fruits[id] = state
		if objects.has(id):
			update_tomato_fruits(objects[id])
		if net_role=="host":
			net_tomato_fruit_state.rpc(str(id),state)
		save_game()

@rpc("authority","call_remote","reliable")
func net_tomato_fruit_state(id: String, state: Dictionary) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1:
		return
	tomato_fruits[id] = state.duplicate(true)
	if objects.has(id):
		update_tomato_fruits(objects[id])

func harvest_tomatoes(plant: Node3D) -> void:
	var id := str(plant.get_meta("id",""))
	if net_role=="client":
		if net_world_ready:
			net_request_harvest_tomatoes.rpc_id(1,id)
		return
	if not take_one_tomato(plant):
		notice("Aguarde o crescimento de um tomate maduro.")
		return
	stock[TOMATO_ITEM] += 1
	item_received(TOMATO_ITEM)
	sync_hotbar()
	save_game()
	notice("Colhido 1 tomate. O pe continua crescendo.")

@rpc("any_peer","call_remote","reliable")
func net_request_harvest_tomatoes(id: String) -> void:
	if net_role!="host" or not objects.has(id):
		return
	var peer_id := multiplayer.get_remote_sender_id()
	var plant: Node3D = objects[id]
	if not is_instance_valid(plant) or not remote_can_interact(peer_id,plant.global_position,4.0):
		return
	if take_one_tomato(plant):
		net_tomato_reward.rpc_id(peer_id,1)
		save_game()

@rpc("authority","call_remote","reliable")
func net_tomato_reward(amount: int) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1 or amount!=1:
		return
	stock[TOMATO_ITEM] += 1
	item_received(TOMATO_ITEM)
	sync_hotbar()
	save_game()
	notice("Colhido 1 tomate.")

func uproot_tomato(plant: Node3D) -> void:
	if not is_instance_valid(plant) or str(plant.get_meta("kind","")) not in ["tomato_plant","tomato_crop"]:
		return
	var id := str(plant.get_meta("id",""))
	if net_role=="client":
		if net_world_ready:
			use_tool(SHOVEL_ITEM)
			net_request_uproot_tomato.rpc_id(1,id,SHOVEL_ITEM)
		return
	use_tool(SHOVEL_ITEM)
	tomato_fruits.erase(id)
	remove_object(plant)
	save_game()
	notice("Pe de tomate retirado com a pa.")

@rpc("any_peer","call_remote","reliable")
func net_request_uproot_tomato(id: String, tool: int) -> void:
	if net_role!="host" or tool!=SHOVEL_ITEM or not objects.has(id):
		return
	var peer := multiplayer.get_remote_sender_id()
	var plant: Node3D = objects[id]
	if not is_instance_valid(plant) or str(plant.get_meta("kind","")) not in ["tomato_plant","tomato_crop"]:
		return
	if not remote_can_interact(peer,plant.global_position,4.0):
		return
	tomato_fruits.erase(id)
	remove_object(plant)
	save_game()

func eat() -> void:
	if stock[3]>0 and health<100:
		stock[3] -= 1
		health = mini(100,health+35)
		notice("Você recuperou vida.")

func can_craft_level_two() -> bool:
	if craft_mode!="station" or station_level<2:
		return false
	for entry in placed:
		if str(entry.get("kind",""))=="bench2":
			var p: Array = entry["p"]
			if player.position.distance_to(Vector3(float(p[0]),float(p[1]),float(p[2])))<=4.0:
				return true
	return false

func carpentry_near() -> bool:
	for entry in placed:
		if str(entry.get("kind",""))=="carpentry_bench":
			var p: Array = entry["p"]
			if player.global_position.distance_to(Vector3(float(p[0]),float(p[1]),float(p[2])))<=4.0:
				return true
	return false

func bench_near() -> bool:
	for entry in placed:
		if entry["kind"] in ["bench","bench2"]:
			var p: Array = entry["p"]
			if player.position.distance_to(Vector3(p[0],p[1],p[2]))<=4.0:
				return true
	return false

func store_object(kind: String, pos: Vector3, yaw: float = 0.0, level: int = 0) -> void:
	if kind=="hut":
		return # Abrigo descontinuado.
	if kind in NET_SHARED_KINDS and net_role=="client" and not net_apply_in_progress:
		if net_world_ready:
			net_request_place.rpc_id(1,kind,pos,yaw,level)
		else:
			notice("Aguarde o mundo multiplayer sincronizar.")
		return
	var id := "item-"+str(Time.get_ticks_usec())+"-"+str(randi())
	placed.append({"kind":kind,"id":id,"p":[pos.x,pos.y,pos.z],"r":yaw,"level":level})
	spawn_object(kind,id,pos,self,yaw)
	if kind=="tomato_crop":
		tomato_crop_times[id] = Time.get_unix_time_from_system()
		update_tomato_crop(objects[id])
	if kind=="wood_floor" and level==0:
		refresh_door_transitions(pos)
	if kind in NET_SHARED_KINDS and net_role=="host" and not net_apply_in_progress:
		net_shared_place.rpc(kind,id,pos,yaw,level)

func remove_object(o: Node3D) -> void:
	var removed_kind := str(o.get_meta("kind",""))
	var id: String = str(o.get_meta("id",""))
	if removed_kind=="chest" and chest_has_items(id):
		notice("Esvazie o baú antes de removê-lo.")
		return
	if net_role=="client" and removed_kind in NET_SHARED_KINDS and not net_apply_in_progress:
		if net_world_ready:
			net_request_remove.rpc_id(1,id)
		return
	if o is CollisionObject3D:
		o.collision_layer = 0
	var removed_pos := o.global_position
	if id.begins_with("item-"):
		placed = placed.filter(func(entry): return entry["id"]!=id)
	elif id!="lobo-errante":
		removed[id] = true
	objects.erase(id)
	if removed_kind=="chest":
		chest_storage.erase(id)
		if open_chest_id==id:
			open_chest_id = ""
	if removed_kind=="tomato_crop":
		tomato_crop_times.erase(id)
	if removed_kind in ["tomato_crop","tomato_plant"]:
		tomato_fruits.erase(id)
	o.queue_free()
	if removed_kind=="wood_floor":
		refresh_door_transitions(removed_pos)
	if net_role=="host" and removed_kind in NET_SHARED_KINDS and not net_apply_in_progress:
		net_shared_remove.rpc(id)

func notice(message: String) -> void:
	feedback = message
	feedback_until = elapsed+4


func capture_inventory_state() -> Dictionary:
	# Dados do jogador, nunca dados da construcao/terreno do anfitriao.
	sync_hotbar()
	sync_tool_durability()
	return {
		"stock": stock.duplicate(true),
		"reserve": reserve.duplicate(true),
		"bar_items": bar_items.duplicate(true),
		"inventory_slots": inventory_slots.duplicate(true),
		"tool_durability": tool_durability.duplicate(true),
		"backpack_slots": serialize_backpack(),
		"backpack_equipped": backpack_equipped,
		"hotbar_manual": hotbar_manual,
		"sword_equipped": sword_equipped,
		"shield_equipped": shield_equipped,
		"health": health,
		"stamina": stamina,
		"selected": selected
	}

func apply_inventory_state(data: Dictionary) -> void:
	# Sempre zerar primeiro: mundo novo nao herda itens offline nem de outra sala.
	stock.fill(0)
	reserve.fill(0)
	bar_items.fill(-1)
	inventory_slots.fill(-1)
	backpack_slots.fill(Vector2i(-1,0))
	var saved_stock: Array = data.get("stock",[])
	var saved_reserve: Array = data.get("reserve",[])
	for i in range(mini(ITEMS.size(),saved_stock.size())):
		stock[i] = clampi(int(saved_stock[i]),0,999999)
	for i in range(mini(ITEMS.size(),saved_reserve.size())):
		reserve[i] = clampi(int(saved_reserve[i]),0,999999)
	var saved_bag: Array = data.get("backpack_slots",[])
	for i in range(mini(BACKPACK_SIZE,saved_bag.size())):
		if not saved_bag[i] is Array or saved_bag[i].size()!=2:
			continue
		var kind := int(saved_bag[i][0])
		var count := int(saved_bag[i][1])
		if kind>=0 and kind<ITEMS.size() and kind!=BACKPACK_ITEM and count>0:
			backpack_slots[i] = Vector2i(kind,mini(count,BACKPACK_STACK_LIMIT))
	tool_durability = (data.get("tool_durability",{}) as Dictionary).duplicate(true)
	backpack_equipped = bool(data.get("backpack_equipped",false)) and stock[BACKPACK_ITEM]>0
	sword_equipped = bool(data.get("sword_equipped",false))
	shield_equipped = bool(data.get("shield_equipped",false))
	hotbar_manual = bool(data.get("hotbar_manual",false))
	var saved_slots: Array = data.get("inventory_slots",[])
	for i in range(mini(inventory_slots.size(),saved_slots.size())):
		var kind := int(saved_slots[i])
		if kind>=0 and kind<ITEMS.size() and (stock[kind]>0 or reserve[kind]>0) and not inventory_slots.has(kind):
			inventory_slots[i] = kind
	var saved_hotbar: Array = data.get("bar_items",[])
	for i in range(mini(bar_items.size(),saved_hotbar.size())):
		var kind := int(saved_hotbar[i])
		if kind>=0 and kind<ITEMS.size() and stock[kind]>0 and not bar_items.has(kind):
			bar_items[i] = kind
	selected = clampi(int(data.get("selected",0)),0,HOTBAR_SIZE-1)
	health = clampi(int(data.get("health",100)),1,100)
	stamina = clampf(float(data.get("stamina",100.0)),0.0,100.0)
	exhausted = stamina<1.0
	recovery_delay = 0.0
	breath = 100.0
	breath_recovery_delay = 0.0
	drowning_damage_clock = 0.0
	sync_inventory_slots()
	sync_hotbar()
	sync_tool_durability()
	if is_instance_valid(backpack_visual):
		backpack_visual.visible = backpack_equipped
	apply_player_equipment()

func save_lan_inventory() -> bool:
	if net_role!="client" or not net_world_ready or not LAN_INVENTORY.valid_world_uid(net_remote_world_uid):
		return false
	var saved := LAN_INVENTORY.write_inventory(net_remote_world_uid,capture_inventory_state())
	if not saved:
		push_warning("Nao foi possivel salvar o inventario desta partida LAN.")
	return saved

func load_game() -> void:
	var save_file: String = world_storage.save_path()
	if not FileAccess.file_exists(save_file):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_file))
	if not data is Dictionary:
		return
	var saved_world_uid := str(data.get("world_uid",""))
	if LAN_INVENTORY.valid_world_uid(saved_world_uid):
		world_uid = saved_world_uid
	var saved_stock: Array = data.get("stock",[])
	var saved_reserve: Array = data.get("reserve",[])
	for i in range(mini(ITEMS.size(),saved_stock.size())):
		stock[i] = int(saved_stock[i])
	for i in range(mini(ITEMS.size(),saved_reserve.size())):
		reserve[i] = int(saved_reserve[i])
	tool_durability = data.get("tool_durability",{})
	hotbar_manual = bool(data.get("hotbar_manual",false))
	backpack_equipped = bool(data.get("backpack_equipped",false)) and stock[BACKPACK_ITEM]>0
	sword_equipped = bool(data.get("sword_equipped",false))
	shield_equipped = bool(data.get("shield_equipped",false))
	var saved_inventory: Array = data.get("inventory_slots",[])
	for index in range(mini(inventory_slots.size(),saved_inventory.size())):
		var kind := int(saved_inventory[index])
		if kind>=0 and kind<ITEMS.size() and (stock[kind]>0 or reserve[kind]>0) and not inventory_slots.has(kind):
			inventory_slots[index] = kind
	sync_inventory_slots()
	var saved_bag: Array = data.get("backpack_slots",[])
	for index in range(mini(BACKPACK_SIZE,saved_bag.size())):
		var entry: Array = saved_bag[index]
		if entry.size()==2:
			var kind := int(entry[0])
			var amount := int(entry[1])
			if kind>=0 and kind<ITEMS.size() and kind!=BACKPACK_ITEM and amount>0:
				backpack_slots[index] = Vector2i(kind,mini(amount,BACKPACK_STACK_LIMIT))
	for i in range(mini(bar_items.size(),data.get("bar_items",[]).size())):
		var item := int(data["bar_items"][i])
		if item>=0 and item<ITEMS.size() and not bar_items.has(item):
			bar_items[i] = item
	sync_hotbar()
	sync_tool_durability()
	removed = data.get("removed",{})
	cleared_stumps = data.get("cleared_stumps",{})
	tree_regrowth = data.get("tree_regrowth",{})
	tree_vines = data.get("tree_vines",{})
	tomato_crop_times = data.get("tomato_crop_times",{})
	tomato_fruits = data.get("tomato_fruits",{})
	chest_storage = data.get("chest_storage",{})
	placed = (data.get("placed",[]) as Array).filter(func(entry): return entry is Dictionary and str(entry.get("kind",""))!="hut")
	health = int(data.get("health",100))
	hut = bool(data.get("hut",false))
	bench = bool(data.get("bench",false))
	won = bool(data.get("won",false))
	set_meta("spawn",data.get("pos",[0,1,0]))

func save_game() -> bool:
	# O cliente nao salva o mundo do anfitriao sobre um arquivo local.
	if net_role=="client":
		return save_lan_inventory()
	if not is_instance_valid(player):
		return false
	if not world_storage.prepare_save():
		return false
	sync_hotbar()
	var file_path: String = world_storage.save_path()
	var file := FileAccess.open(file_path+".tmp",FileAccess.WRITE)
	if file:
		var p := player.position
		file.store_string(JSON.stringify({"world_uid":world_uid,"stock":stock,"bar_items":bar_items,"reserve":reserve,"tool_durability":tool_durability,"removed":removed,
			"placed":placed,"tree_regrowth":tree_regrowth,"tree_vines":tree_vines,"tomato_crop_times":tomato_crop_times,"tomato_fruits":tomato_fruits,"chest_storage":chest_storage,"cleared_stumps":cleared_stumps,"health":health,"hut":hut,"bench":bench,"won":won,"pos":[p.x,p.y,p.z],
			"backpack_equipped":backpack_equipped,"backpack_slots":serialize_backpack(),"hotbar_manual":hotbar_manual,"inventory_slots":inventory_slots,
			"sword_equipped":sword_equipped,"shield_equipped":shield_equipped}))
		file.flush()
		file.close()
		return DirAccess.rename_absolute(ProjectSettings.globalize_path(file_path+".tmp"),ProjectSettings.globalize_path(file_path))==OK
	return false

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func lan_local_ipv4_addresses() -> PackedStringArray:
	var addresses := PackedStringArray()
	for ip in IP.get_local_addresses():
		# Ignora IPv6, loopback, links locais e IPs publicos.
		if ip.contains(":") or not ip.is_valid_ip_address():
			continue
		var octets := ip.split(".")
		if octets.size()!=4:
			continue
		var second := int(octets[1])
		var private_range := ip.begins_with("192.168.") or ip.begins_with("10.") or (int(octets[0])==172 and second>=16 and second<=31)
		if private_range and not addresses.has(ip):
			addresses.append(ip)
	return addresses


func host_game() -> void:
	disconnect_game()
	# O ID do mapa precisa existir no disco antes de receber visitantes.
	if not save_game():
		net_session_message = "Nao foi possivel salvar o mapa para hospedar a partida."
		notice(net_session_message)
		show_menu()
		return
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(NET_PORT,7)
	if error!=OK:
		peer.close()
		net_session_message = "Porta UDP %d indisponível. Feche outro servidor ou libere o firewall." % NET_PORT
		notice(net_session_message)
		show_menu()
		return
	net_role = "host"
	net_connected = true
	var ips := lan_local_ipv4_addresses()
	net_session_message = "Compartilhe o IP local: %s (UDP %d)." % [", ".join(ips) if ips.size()>0 else "veja em ipconfig",NET_PORT]
	multiplayer.multiplayer_peer = peer
	notice("Partida hospedada. Porta UDP %d." % NET_PORT)
	begin()


func load_last_lan_ip() -> void:
	# Preferencia do computador, independente do mundo selecionado.
	var settings := ConfigFile.new()
	if settings.load(LAN_PREFS_PATH)!=OK:
		return
	var saved_ip := str(settings.get_value("lan","last_connected_ip","")).strip_edges()
	if saved_ip=="localhost" or saved_ip.is_valid_ip_address():
		last_connected_lan_ip = saved_ip
		net_address = saved_ip

func remember_connected_lan_ip() -> void:
	# Apenas salvar quando o mapa do anfitriao ja foi sincronizado.
	# Uma tentativa com IP errado nao apaga o ultimo servidor funcional.
	if net_role!="client" or not net_world_ready:
		return
	var current_ip := net_address.strip_edges()
	if current_ip!="localhost" and not current_ip.is_valid_ip_address():
		return
	var settings := ConfigFile.new()
	settings.set_value("lan","last_connected_ip",current_ip)
	var save_error := settings.save(LAN_PREFS_PATH)
	if save_error==OK:
		last_connected_lan_ip = current_ip
	else:
		push_warning("Nao foi possivel salvar o ultimo IP LAN: %d" % save_error)


func join_game() -> void:
	var ip := ""
	if is_instance_valid(medieval_menu) and is_instance_valid(medieval_menu.ip_input):
		ip = medieval_menu.ip_input.text.strip_edges()
	elif is_instance_valid(address):
		ip = address.text.strip_edges()
	join_at_address(ip)


func join_at_address(ip: String) -> void:
	if ip.is_empty() or (not ip.is_valid_ip_address() and ip!="localhost"):
		net_session_message = "Informe o IPv4 local do anfitrião. Ex.: 192.168.1.10."
		notice(net_session_message)
		show_menu()
		return
	disconnect_game()
	net_offline_inventory_backup = capture_inventory_state()
	net_address = ip
	net_world_backup = capture_net_world()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip,NET_PORT)
	if error!=OK:
		peer.close()
		net_world_backup.clear()
		net_offline_inventory_backup.clear()
		net_address = last_connected_lan_ip
		net_session_message = "Falha ao iniciar a conexão. Verifique o IP e a porta UDP %d." % NET_PORT
		notice(net_session_message)
		show_menu()
		return
	net_role = "client"
	net_connected = false
	net_world_ready = false
	net_session_message = "Conectando ao anfitrião %s..." % ip
	multiplayer.multiplayer_peer = peer
	show_menu()


func net_connected_to_server() -> void:
	if net_role!="client":
		return
	net_connected = true
	net_session_message = "Conectado. Sincronizando o mundo do anfitrião."
	net_client_hello.rpc_id(1,NET_PROTOCOL)
	notice(net_session_message)
	# Nao iniciar antes de receber a copia compartilhada das construcoes.


func net_connection_failed() -> void:
	if net_role!="client":
		return
	disconnect_game()
	net_address = last_connected_lan_ip
	net_session_message = "Não foi possível conectar. Confira o IPv4 local e o firewall UDP %d." % NET_PORT
	notice(net_session_message)
	show_menu()


func net_peer_connected(peer_id: int) -> void:
	if net_role!="host" or peer_id==1:
		return
	net_session_message = "Jogador %d entrou na sala." % peer_id
	notice(net_session_message)


func net_peer_disconnected(peer_id: int) -> void:
	remove_remote(peer_id)
	if net_role=="host":
		load_chunks() # libera apenas as regioes que nenhum jogador utiliza
		net_remove_avatar.rpc(peer_id)
		notice("Jogador %d saiu da sala." % peer_id)


@rpc("any_peer","call_remote","reliable")
func net_client_hello(version: int) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id<=1:
		return
	if version!=NET_PROTOCOL:
		net_kick_message.rpc_id(peer_id,"A versão do jogo é diferente. Atualize nos dois computadores.")
		return
	net_send_snapshot.rpc_id(peer_id,capture_net_world())


@rpc("authority","call_remote","reliable")
func net_kick_message(message: String) -> void:
	if multiplayer.get_remote_sender_id()!=1:
		return
	disconnect_game()
	net_session_message = message
	notice(message)
	show_menu()


func capture_net_world() -> Dictionary:
	return {
		"world_uid": world_uid,
		"placed": placed.duplicate(true),
		"removed": removed.duplicate(true),
		"cleared_stumps": cleared_stumps.duplicate(true),
		"tree_regrowth": tree_regrowth.duplicate(true),
		"tree_vines": tree_vines.duplicate(true),
		"tomato_crop_times": tomato_crop_times.duplicate(true),
		"tomato_fruits": tomato_fruits.duplicate(true),
		"chest_storage": chest_storage.duplicate(true),
		"hut":hut,"won":won,"bench":bench,
		"pos":[player.position.x,player.position.y,player.position.z],
		"entities":net_capture_entities()
	}


func apply_net_world(snapshot: Dictionary) -> void:
	if not snapshot.has("placed") or not snapshot.has("removed"):
		return
	net_apply_in_progress = true
	# Desfaz mobs locais antes de receber os do servidor.
	for mob in mobs:
		if is_instance_valid(mob):
			mob.queue_free()
	mobs.clear()
	roaming_wolf = null
	# Desfaz objetos do save local antes de receber o mundo hospedado.
	for entry in placed:
		var object_id := str(entry.get("id",""))
		if objects.has(object_id):
			var old: Node3D = objects[object_id]
			objects.erase(object_id)
			if is_instance_valid(old):
				if old is CollisionObject3D:
					old.collision_layer = 0
				old.queue_free()
	placed = (snapshot["placed"] as Array).filter(func(entry): return entry is Dictionary and str(entry.get("kind",""))!="hut")
	removed = (snapshot["removed"] as Dictionary).duplicate(true)
	if removed.has(STARTER_CABIN_ID) and objects.has(STARTER_CABIN_ID):
		var obsolete: Node3D = objects[STARTER_CABIN_ID]
		objects.erase(STARTER_CABIN_ID)
		if obsolete is CollisionObject3D:
			obsolete.collision_layer = 0
		obsolete.queue_free()
	elif not removed.has(STARTER_CABIN_ID) and not objects.has(STARTER_CABIN_ID):
		spawn_starter_cabin()
	cleared_stumps = (snapshot.get("cleared_stumps",{}) as Dictionary).duplicate(true)
	tree_regrowth = (snapshot.get("tree_regrowth",{}) as Dictionary).duplicate(true)
	tree_vines = (snapshot.get("tree_vines",{}) as Dictionary).duplicate(true)
	tomato_crop_times = (snapshot.get("tomato_crop_times",{}) as Dictionary).duplicate(true)
	tomato_fruits = (snapshot.get("tomato_fruits",{}) as Dictionary).duplicate(true)
	chest_storage = (snapshot.get("chest_storage",{}) as Dictionary).duplicate(true)
	hut = bool(snapshot.get("hut",false))
	won = bool(snapshot.get("won",false))
	bench = bool(snapshot.get("bench",false))
	# Reconstroi recursos naturais de acordo com o estado compartilhado.
	for key in chunks.keys():
		var chunk: Node3D = chunks[key]
		for child in chunk.get_children():
			objects.erase(child.get_meta("id",""))
		chunk.queue_free()
	chunks.clear()
	load_chunks()
	for entry in placed:
		if str(entry.get("kind",""))=="hut":
			continue
		var p: Array = entry["p"]
		spawn_object(str(entry["kind"]),str(entry["id"]),
			Vector3(float(p[0]),float(p[1]),float(p[2])),self,float(entry.get("r",0.0)))
	net_apply_in_progress = false
	if net_role=="client":
		net_apply_entities(snapshot.get("entities",[]))


@rpc("authority","call_remote","reliable")
func net_send_snapshot(snapshot: Dictionary) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1 or net_world_ready:
		return
	var incoming_world_uid := str(snapshot.get("world_uid",""))
	if not LAN_INVENTORY.valid_world_uid(incoming_world_uid):
		disconnect_game()
		net_session_message = "Anfitriao sem identificador de mundo. Atualize os dois jogos."
		notice(net_session_message)
		show_menu()
		return
	net_remote_world_uid = incoming_world_uid
	apply_net_world(snapshot)
	# O anfitriao envia somente o mundo: os itens sao carregados por visitante.
	var returning_player := LAN_INVENTORY.has_inventory(incoming_world_uid)
	apply_inventory_state(LAN_INVENTORY.read_inventory(incoming_world_uid))
	net_world_ready = true
	net_connected = true
	remember_connected_lan_ip()
	var host_position: Array = snapshot.get("pos",[0,1,0])
	var enter_x := float(host_position[0])+2.0
	var enter_z := float(host_position[2])+2.0
	player.position = Vector3(enter_x,ground(enter_x,enter_z)+.85,enter_z)
	player.velocity = Vector3.ZERO
	net_session_message = "Mundo sincronizado. Inventario restaurado." if returning_player else "Primeira visita a este mundo: inventario vazio."
	notice(net_session_message)
	begin()


func remote_can_interact(peer_id: int, pos: Vector3, max_distance: float) -> bool:
	if net_role!="host" or peer_id<=1 or not multiplayer.get_peers().has(peer_id) or not pos.is_finite():
		return false
	var avatar: Node3D = remotes.get(peer_id,null)
	if not is_instance_valid(avatar):
		return false
	# Usa o ultimo destino informado, nao a posicao interpolada que fica atrasada.
	var remote_pos: Vector3 = avatar.get_meta("destination",avatar.global_position)
	return remote_pos.distance_to(pos)<=max_distance

@rpc("any_peer","call_remote","reliable")
func net_request_dismantle(id: String,tool: int) -> void:
	if net_role!="host" or tool not in [WOOD_AXE,STONE_AXE] or not objects.has(id):
		return
	var peer_id := multiplayer.get_remote_sender_id()
	var obj: Node3D = objects[id]
	if not is_instance_valid(obj) or not remote_can_interact(peer_id,obj.global_position,5.5):
		return
	var kind := str(obj.get_meta("kind",""))
	if kind not in ["chest","bench","bench2","carpentry_bench","fire","hut","wood_wall","wood_doorway","wood_window","wood_floor","stairs_straight","stairs_l","ladder"]:
		return
	if kind=="chest" and chest_has_items(id):
		net_dismantle_feedback.rpc_id(peer_id,-2,0,-1)
		return
	var last := float(obj.get_meta("net_last_dismantle_"+str(peer_id),-100.0))
	if elapsed-last<0.30:
		return
	obj.set_meta("net_last_dismantle_"+str(peer_id),elapsed)
	var hits := int(obj.get_meta("break_hits",0))+(2 if tool==STONE_AXE else 1)
	var required := 12 if kind=="hut" else (4 if kind in ["wood_wall","wood_doorway","wood_window","wood_floor","bench2","carpentry_bench"] else (3 if kind=="bench" else 2))
	if hits<required:
		obj.set_meta("break_hits",hits)
		net_dismantle_feedback.rpc_id(peer_id,hits,required,-1)
		return
	var recovered_item := ITEM_KINDS.find(kind)
	remove_object(obj)
	bench = any_bench_placed()
	net_dismantle_feedback.rpc_id(peer_id,required,required,recovered_item)
	save_game()

@rpc("authority","call_remote","reliable")
func net_dismantle_feedback(hits: int,required: int,recovered_item: int) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1:
		return
	if recovered_item>=0 and recovered_item<ITEMS.size():
		stock[recovered_item] += 1
		item_received(recovered_item)
		sync_hotbar()
		save_game()
		notice("Estrutura recuperada para o inventario.")
	elif hits==-2:
		notice("Esvazie o baú antes de desmontar.")
	elif hits>=0 and required>0:
		notice("Desmontando estrutura: %d/%d" % [hits,required])

@rpc("any_peer","call_remote","reliable")
func net_request_place(kind: String,pos: Vector3,yaw: float,level: int) -> void:
	if net_role!="host" or kind in ["hut","tomato_crop"] or kind not in NET_SHARED_KINDS:
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id<=1 or not multiplayer.get_peers().has(peer_id):
		return
	if not pos.is_finite() or not is_finite(yaw) or level<0 or level>BUILD_MAX_LEVEL:
		return
	if not remote_can_interact(peer_id,pos,12.0):
		return
	store_object(kind,pos,yaw,level)
	save_game()


@rpc("authority","call_remote","reliable")
func net_shared_place(kind: String,id: String,pos: Vector3,yaw: float,level: int) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1:
		return
	if kind=="hut" or kind not in NET_SHARED_KINDS or id.length()>100 or not pos.is_finite():
		return
	if objects.has(id):
		return
	net_apply_in_progress = true
	placed.append({"kind":kind,"id":id,"p":[pos.x,pos.y,pos.z],"r":yaw,"level":level})
	spawn_object(kind,id,pos,self,yaw)
	if kind=="wood_floor" and level==0:
		refresh_door_transitions(pos)
	net_apply_in_progress = false


@rpc("any_peer","call_remote","reliable")
func net_request_remove(id: String) -> void:
	if net_role!="host" or not objects.has(id):
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id<=1 or not multiplayer.get_peers().has(peer_id):
		return
	var obj: Node3D = objects[id]
	if not is_instance_valid(obj) or str(obj.get_meta("kind","")) not in ["bench","bench2","carpentry_bench","fire","hut","wood_wall","wood_doorway","wood_window","wood_floor","stairs_straight","stairs_l","ladder"]:
		return
	if not remote_can_interact(peer_id,obj.global_position,6.5):
		return
	# Remocao avulsa nao pode contornar o sistema de golpes nem gerar itens.
	return


@rpc("authority","call_remote","reliable")
func net_shared_remove(id: String) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1 or not net_world_ready:
		return
	# O cliente pode estar a centenas de metros: persistir a remocao mesmo
	# quando a regiao ainda nao foi carregada localmente.
	var obj: Node3D = objects.get(id,null)
	if is_instance_valid(obj):
		net_apply_in_progress = true
		remove_object(obj)
		net_apply_in_progress = false
	elif id.begins_with("item-"):
		chest_storage.erase(id)
		placed = placed.filter(func(entry): return str(entry.get("id",""))!=id)
		tomato_crop_times.erase(id)
		tomato_fruits.erase(id)
	else:
		removed[id] = true
		tomato_fruits.erase(id)


# O anfitriao e a unica maquina que executa a IA dos mobs. O ID dos
# animais e estavel, e cada snapshot substitui posicao, rotacao e vida.
func nearest_player_id(pos: Vector3) -> int:
	var closest := player.global_position.distance_squared_to(pos)
	var chosen := 1
	if net_role=="host":
		for peer_id in remotes.keys():
			var avatar: Node3D = remotes[peer_id]
			if not is_instance_valid(avatar):
				continue
			var d := avatar.global_position.distance_squared_to(pos)
			if d < closest:
				closest = d
				chosen = int(peer_id)
	return chosen

func nearest_player_distance(pos: Vector3) -> float:
	var id := nearest_player_id(pos)
	if id==1:
		return player.global_position.distance_to(pos)
	return remotes[id].global_position.distance_to(pos)

func net_capture_entities() -> Array:
	var result: Array = []
	for npc in villagers:
		if is_instance_valid(npc) and not npc.is_queued_for_deletion():
			result.append({"id":str(npc.get_meta("id","")),"kind":str(npc.get_meta("kind","")),
				"p":npc.global_position,"r":npc.rotation.y,"hp":-1,"clock":npc_world_clock,"attack_serial":int(npc.get_meta("attack_serial",0))})
	for mob in mobs:
		if is_instance_valid(mob) and not mob.is_queued_for_deletion():
			result.append({"id":str(mob.get_meta("id","")),"kind":str(mob.get_meta("kind","")),
				"p":mob.global_position,"r":mob.rotation.y,"hp":int(mob.get_meta("hp",1))})
	return result

func net_apply_entities(states: Array) -> void:
	if net_role!="client":
		return
	var visible_ids: Dictionary = {}
	for data in states:
		if not data is Dictionary:
			continue
		var id := str(data.get("id",""))
		var kind := str(data.get("kind",""))
		var pos: Variant = data.get("p",Vector3.ZERO)
		if id.is_empty() or id.length()>100 or not pos is Vector3 or not (pos as Vector3).is_finite():
			continue
		if kind not in ["rabbit","wolf","guardian","Bruma","Talo"]:
			continue
		visible_ids[id] = true
		var obj: Node3D = objects.get(id,null)
		if not is_instance_valid(obj):
			if kind in ["Bruma","Talo"]:
				continue
			obj = creature(kind,id,pos,self)
			obj.set_meta("net_mob",true)
		var angle := float(data.get("r",0.0))
		if obj.has_meta("net_mob"):
			var delta := (pos as Vector3)-obj.global_position
			obj.set_meta("net_animation_velocity",delta*7.0)
			obj.global_position = obj.global_position.lerp(pos,.65) if delta.length()<10.0 else pos
		else:
			var delta := (pos as Vector3)-obj.global_position
			obj.set_meta("net_animation_velocity",delta*7.0)
			obj.global_position = obj.global_position.lerp(pos,.65) if delta.length()<10.0 else pos
		obj.rotation.y = angle
		if kind in ["Bruma","Talo"] and data.has("clock"):
			npc_world_clock = float(data["clock"])
			var serial := int(data.get("attack_serial",0))
			if serial>int(obj.get_meta("net_attack_serial",0)):
				obj.set_meta("net_attack_serial",serial)
				var rig := obj.get_node_or_null("Visual/GoblinRig")
				if rig!=null:
					rig.call("play_action","attack")
		if int(data.get("hp",-1))>=0:
			obj.set_meta("hp",int(data["hp"]))
	for mob in mobs:
		if is_instance_valid(mob) and mob.has_meta("net_mob"):
			if not visible_ids.has(str(mob.get_meta("id",""))):
				objects.erase(str(mob.get_meta("id","")))
				mob.queue_free()
	mobs = mobs.filter(func(m): return is_instance_valid(m) and not m.is_queued_for_deletion())

@rpc("authority","call_remote","unreliable_ordered")
func net_sync_entities(states: Array) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1 or not net_world_ready:
		return
	net_apply_entities(states)

@rpc("authority","call_remote","reliable")
func net_receive_damage(amount: int) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1:
		return
	health = maxi(0,health-clampi(amount,0,30))
	if health<=0:
		respawn()

@rpc("any_peer","call_remote","reliable")
func net_request_hit_mob(id: String,damage: int) -> void:
	if net_role!="host" or not objects.has(id):
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id<=1 or not remotes.has(peer_id):
		return
	var target: Node3D = objects[id]
	if not is_instance_valid(target) or str(target.get_meta("kind","")) not in ["rabbit","wolf","guardian"]:
		return
	if not remote_can_interact(peer_id,target.global_position,4.5):
		return
	var last := float(target.get_meta("last_hit_"+str(peer_id),-100.0))
	if elapsed-last<.35:
		return
	target.set_meta("last_hit_"+str(peer_id),elapsed)
	var hp := maxi(0,int(target.get_meta("hp",1))-clampi(damage,1,3))
	target.set_meta("hp",hp)
	if hp<=0:
		var p := target.global_position
		var kind := str(target.get_meta("kind",""))
		remove_object(target)
		if kind=="guardian":
			won = true
		else:
			store_object("meat_rabbit" if kind=="rabbit" else "meat_wolf",p)
			if kind=="wolf" and randf()<0.50:
				store_object("wolf_tooth",p+Vector3(.36,0,0))
			if kind=="rabbit":
				store_object("hide",p+Vector3(.41,0,0))
	net_sync_entities.rpc(net_capture_entities())

# O anfitriao valida os golpes e distribui o estado unico da floresta.
@rpc("any_peer","call_remote","reliable")
func net_request_chop_tree(id: String, tool: int) -> void:
	if net_role!="host" or tool not in [-1,WOOD_AXE,STONE_AXE] or not objects.has(id):
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id<=1 or not multiplayer.get_peers().has(peer_id):
		return
	var avatar: Node3D = remotes.get(peer_id,null)
	var tree: Node3D = objects[id]
	if not is_instance_valid(avatar) or not is_instance_valid(tree) or str(tree.get_meta("kind",""))!="tree":
		return
	if not remote_can_interact(peer_id,tree.global_position,5.0):
		return
	var last := float(tree.get_meta("net_last_chop_"+str(peer_id),-100.0))
	if elapsed-last<0.30:
		return
	tree.set_meta("net_last_chop_"+str(peer_id),elapsed)
	tree.set_meta("fall_from",avatar.global_position)
	tree.set_meta("damage_peer",peer_id)
	chop_tree(tree,tool,tree.global_position+Vector3.UP*0.85,Vector3.FORWARD)
	if is_instance_valid(tree):
		tree.remove_meta("damage_peer")


@rpc("authority","call_remote","reliable")
func net_tree_chopped(id: String, cuts: int, fell: bool, cut_time: float, from_position: Vector3) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1 or not net_world_ready:
		return
	if cuts<1 or cuts>10 or not from_position.is_finite():
		return
	# Registrar o corte mesmo se a arvore estiver fora dos chunks locais.
	if fell:
		tree_regrowth[id] = cut_time
		tree_vines.erase(id)
	var tree: Node3D = objects.get(id,null)
	if not is_instance_valid(tree) or str(tree.get_meta("kind",""))!="tree":
		return
	if fell:
		tree.set_meta("fall_from",from_position)
		timber(tree,true)
		# timber usa o relogio local; reestabelecer o horario do servidor.
		tree_regrowth[id] = cut_time
		update_tree_visual(tree)
	else:
		tree.set_meta("cuts",cuts)
		tree.set_meta("fall_from",from_position)
		timber(tree,false)
		play_tree_chop_sound(tree.global_position+Vector3.UP*0.85,STONE_AXE)


@rpc("any_peer","call_remote","reliable")
func net_request_dig_stump(id: String, tool: int) -> void:
	if net_role!="host" or tool!=SHOVEL_ITEM or not objects.has(id):
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id<=1 or not multiplayer.get_peers().has(peer_id):
		return
	var avatar: Node3D = remotes.get(peer_id,null)
	var stump: Node3D = objects[id]
	if not is_instance_valid(avatar) or not is_instance_valid(stump) or str(stump.get_meta("kind",""))!="stump":
		return
	if not remote_can_interact(peer_id,stump.global_position,5.0):
		return
	var last := float(stump.get_meta("net_last_dig_"+str(peer_id),-100.0))
	if elapsed-last<0.30:
		return
	stump.set_meta("net_last_dig_"+str(peer_id),elapsed)
	dig_stump(stump,tool,stump.global_position+Vector3.UP*0.30,Vector3.UP)


@rpc("authority","call_remote","reliable")
func net_stump_dug(id: String, digs: int, removed_stump: bool) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1 or not net_world_ready:
		return
	var stump: Node3D = objects.get(id,null)
	if removed_stump:
		cleared_stumps[id] = true
		tree_regrowth.erase(id)
		tree_vines.erase(id)
		if is_instance_valid(stump):
			objects.erase(id)
			stump.collision_layer = 0
			stump.queue_free()
	elif is_instance_valid(stump):
		stump.set_meta("dig_hits",digs)


func net_create_avatar(peer_id: int) -> Node3D:
	var avatar := Node3D.new()
	avatar.name = "JogadorRede_%d" % peer_id
	add_child(avatar)
	var visual := Node3D.new()
	avatar.add_child(visual)
	visual.rotation.y = PI
	goblin_npc(visual,Color("#895938"),"player")
	var remote_rig := visual.get_node_or_null("GoblinRig")
	if remote_rig != null:
		remote_rig.call("set_equipment",false,false)
	remotes[peer_id] = avatar
	return avatar


func net_apply_avatar_position(peer_id: int,pos: Vector3,facing: float,gear_mask: int) -> void:
	if peer_id==multiplayer.get_unique_id() or not pos.is_finite() or not is_finite(facing):
		return
	if pos.length()>50000:
		return
	var avatar: Node3D = remotes.get(peer_id,null)
	var created := not is_instance_valid(avatar)
	var previous_center := chunk_from_position(avatar.get_meta("destination",avatar.global_position)) if not created else Vector2i(100000,100000)
	if created:
		avatar = net_create_avatar(peer_id)
		avatar.position = pos
	if avatar.position.distance_to(pos)>15.0:
		avatar.position = pos
	avatar.set_meta("destination",pos)
	avatar.rotation.y = facing
	if net_role=="host" and (created or previous_center!=chunk_from_position(pos)):
		load_chunks()
	var avatar_visual := avatar.get_child(0) as Node3D
	var avatar_rig := avatar_visual.get_node_or_null("GoblinRig")
	if avatar_rig != null:
		avatar_rig.call("set_equipment",(gear_mask&1)!=0,(gear_mask&2)!=0)


@rpc("any_peer","call_remote","unreliable_ordered")
func send_position(pos: Vector3,facing: float,gear_mask: int) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender<1:
		return
	if net_role!="host":
		# Cliente so aceita atualizacoes do anfitriao; nao de outros clientes.
		if sender==1:
			net_apply_avatar_position(1,pos,facing,gear_mask)
		return
	if not multiplayer.get_peers().has(sender):
		return
	net_apply_avatar_position(sender,pos,facing,gear_mask)
	# O anfitriao encaminha posicoes para todos os outros clientes.
	net_relay_position.rpc(sender,pos,facing,gear_mask)


@rpc("authority","call_remote","unreliable_ordered")
func net_relay_position(peer_id: int,pos: Vector3,facing: float,gear_mask: int) -> void:
	if net_role!="client" or multiplayer.get_remote_sender_id()!=1:
		return
	net_apply_avatar_position(peer_id,pos,facing,gear_mask)


@rpc("authority","call_remote","reliable")
func net_remove_avatar(peer_id: int) -> void:
	if multiplayer.get_remote_sender_id()!=1:
		return
	remove_remote(peer_id)


func remove_remote(id: int) -> void:
	if remotes.has(id):
		if is_instance_valid(remotes[id]):
			remotes[id].queue_free()
		remotes.erase(id)


func disconnect_and_show_menu() -> void:
	disconnect_game()
	net_session_message = "Modo offline. Você pode hospedar ou entrar em outra sala."
	notice(net_session_message)
	show_menu()


func disconnect_game() -> void:
	var was_client := net_role=="client"
	if was_client and net_world_ready:
		save_lan_inventory()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	for id in remotes.keys():
		remove_remote(id)
	var restore := was_client and not net_world_backup.is_empty()
	net_role = "solo"
	net_connected = false
	net_world_ready = false
	if restore:
		apply_net_world(net_world_backup)
		var previous: Array = net_world_backup.get("pos",[0,1,0])
		player.position = Vector3(float(previous[0]),float(previous[1]),float(previous[2]))
	if was_client and not net_offline_inventory_backup.is_empty():
		apply_inventory_state(net_offline_inventory_backup)
	net_world_backup.clear()
	net_offline_inventory_backup.clear()
	net_remote_world_uid = ""


func disconnected() -> void:
	if net_role=="solo":
		return
	disconnect_game()
	net_session_message = "Anfitrião desconectado. Seu mundo offline foi restaurado."
	notice(net_session_message)
	show_menu()
