extends Node3D

const SAVE := "user://clareira-nativa.json"
const CELL := 0.85
const CHUNK := 16
const ITEMS := ["Lança de pedra", "Graveto", "Pedra", "Carne", "Couro", "Pé de coelho", "Tronco", "Tábua", "Lança de madeira", "Machado de madeira", "Machado de pedra", "Cipó", "Corda", "Bancada de trabalho", "Fogueira", "Mochila", "Parede de madeira", "Parede com porta", "Parede com janela", "Bancada de trabalho · Nível 2"]
const ITEM_KINDS := ["spear","stick","stone","meat","hide","foot","log","plank","wood_spear","wood_axe","stone_axe","vine","rope","bench","fire","backpack","wood_wall","wood_doorway","wood_window","bench2"]
const CRAFT_OUTPUT := {"bench":"Bancada de trabalho · Nível 1","fire":"Fogueira","plank":"4 tábuas","spear":"Lança de pedra","wood_spear":"Lança de madeira","wood_axe":"Machado de madeira","stone_axe":"Machado de pedra","rope":"Corda","backpack":"Mochila","wood_wall":"Parede de madeira","wood_doorway":"Parede com porta","wood_window":"Parede com janela","bench2":"Bancada de trabalho · Nível 2"}
const STATION_PATTERNS := {"spear":[-1,-1,2,-1,1,-1,1,-1,-1],"wood_spear":[-1,-1,1,-1,1,-1,1,-1,-1],"wood_axe":[1,7,-1,1,7,-1,1,-1,-1],"stone_axe":[1,2,-1,1,2,-1,1,-1,-1],"backpack":[4,11,4,4,11,4,4,4,4],"wood_wall":[7,7,7,7,7,7,7,7,7],"wood_doorway":[7,7,7,7,-1,7,7,-1,7],"wood_window":[7,7,7,7,-1,7,7,7,7],"bench2":[2,2,2,6,11,6,6,-1,6]}
const WOOD_AXE := 9
const STONE_AXE := 10
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
const WALL_SIZE := CELL * 3.0
const HOTBAR_SIZE := 9
const NPC_PATROL_RADIUS := 8.0 # Limite da patrulha em metros, medido a partir da fogueira.
const BUILD_TAG := "Atualização 21/11 · patrulha 8 m · paredes encaixadas · inventário arrastável"
const BACKPACK_SIZE := 12
const BACKPACK_STACK_LIMIT := 64
var backpack_equipped := false
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
var stock := [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
var reserve := [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
var removed: Dictionary = {}
var placed: Array = []
var objects: Dictionary = {}
var chunks: Dictionary = {}
var mobs: Array[CharacterBody3D] = []
var villagers: Array[CharacterBody3D] = [] # Bruma e Talo: NPCs amigáveis que passeiam pela clareira.
var materials: Dictionary = {}
var surface_textures: Dictionary = {}
var wolf_face_materials: Dictionary = {}
var roaming_wolf: CharacterBody3D
var wolf_spawn_timer := randf_range(95.0,175.0)
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
var wood_axe_head: MeshInstance3D
var stone_axe_head: Node3D
var crosshair: Label
var hud: Label
var hint: Label
var hotbar: HBoxContainer
const ITEM_ICONS := [preload("res://icones/0.png"),preload("res://icones/1.png"),preload("res://icones/2.png"),preload("res://icones/3.png"),preload("res://icones/4.png"),preload("res://icones/5.png"),preload("res://icones/6.png"),preload("res://icones/7.png"),preload("res://icones/8.png"),preload("res://icones/9.png"),preload("res://icones/10.png"),preload("res://icones/11.png"),preload("res://icones/12.png"),preload("res://icones/13.png"),preload("res://icones/14.png"),preload("res://icones/15.png"),preload("res://icones/16.png"),preload("res://icones/17.png"),preload("res://icones/18.png"),preload("res://icones/19.png")]
var bar_items := [-1,-1,-1,-1,-1,-1,-1,-1,-1]
var inventory_slots: Array[int] = [] # A ordem visual pode ser alterada sem perder nenhum item.
var stone_axe_sprite: Sprite3D
var hotbar_icons: Array[TextureRect] = []
var hotbar_slots: Array[Label] = []
var hotbar_frames: Array[PanelContainer] = []
var hotbar_counts: Array[Label] = []
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
const WALK_SPEED := 4.4
const RUN_SPEED := 6.7
const RABBIT_ESCAPE_SPEED := 3.45
var panel: PanelContainer
var menu: VBoxContainer
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

func _ready() -> void:
	inventory_slots.resize(ITEMS.size())
	inventory_slots.fill(-1)
	backpack_slots.resize(BACKPACK_SIZE)
	backpack_slots.fill(Vector2i(-1,0))
	setup_world()
	load_game()
	make_player()
	make_ui()
	village()
	load_chunks()
	show_menu()
	multiplayer.peer_disconnected.connect(remove_remote)
	multiplayer.server_disconnected.connect(disconnected)
	multiplayer.connection_failed.connect(disconnected)

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
	environment.fog_density = 0.014
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-47,-32,0)
	sun.light_color = Color("#fff0d6")
	sun.light_energy = .81
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 38
	add_child(sun)
	var grass := material("grass", Color("#dadbd0"))
	grass.albedo_texture = preload("res://grass.png")
	grass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var rock := material("rock", Color.WHITE)
	rock.albedo_texture = preload("res://stone.png")
	rock.uv1_triplanar = true
	rock.uv1_triplanar_sharpness = 3.5
	rock.uv1_scale = Vector3.ONE*1.45
	rock.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
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
	goblin(player_model,Color("#895938"),true)
	backpack_visual = Node3D.new()
	backpack_visual.name = "MochilaVestida"
	player_model.add_child(backpack_visual)
	box(backpack_visual,Vector3(0,.92,-.27),Vector3(.48,.57,.23),"pack_leather",Color("#815337"))
	box(backpack_visual,Vector3(0,1.14,-.40),Vector3(.49,.19,.045),"pack_flap",Color("#5e3d28"))
	for side in [-1,1]:
		box(backpack_visual,Vector3(side*.20,1.00,-.15),Vector3(.046,.48,.045),"pack_strap",Color("#ad7e52"))
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
	wood_axe_head = box(axe,Vector3(.09,.30,0),Vector3(.25,.18,.077),"plank",Color("#ac7749"))
	stone_axe_head = Node3D.new()
	axe.add_child(stone_axe_head)
	make_stone_axe_head(stone_axe_head)
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

func make_stone_axe_head(parent: Node3D) -> void:
	var blade := mesh_part(parent,rock_mesh,Vector3(.10,.30,0),Vector3(.31,.25,.108),materials["rock"])
	blade.rotation.z = -.22
	for i in range(3):
		var binding := cylinder(parent,Vector3(.009,.255+i*.029,0),.057,.014,"rope",Color("#cfb17e"))
		binding.rotation.z = .19

func ground(x: float,z: float) -> float:
	var fade := smoothstep(16.,38.,Vector2(x,z).length())
	return (sin(x*.12)*1.2+cos(z*.14)*.87+sin((x+z)*.22)*.52)*fade

func load_chunks() -> void:
	var center := Vector2i(floori(player.position.x/CHUNK), floori(player.position.z/CHUNK))
	for key: Vector2i in chunks.keys():
		if absi(key.x-center.x)>2 or absi(key.y-center.y)>2:
			var chunk: Node3D = chunks[key]
			for child in chunk.get_children():
				objects.erase(child.get_meta("id",""))
			chunk.queue_free()
			chunks.erase(key)
	for z in range(center.y-2,center.y+3):
		for x in range(center.x-2,center.x+3):
			var key := Vector2i(x,z)
			if not chunks.has(key):
				create_chunk(key)

func create_chunk(key: Vector2i) -> void:
	var chunk := Node3D.new()
	add_child(chunk)
	chunks[key] = chunk
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(8):
		for x in range(8):
			var left := float(key.x*CHUNK+x*2)
			var near := float(key.y*CHUNK+z*2)
			for corner in [Vector2(0,0),Vector2(2,0),Vector2(0,2),Vector2(2,0),Vector2(2,2),Vector2(0,2)]:
				var px: float = left+corner.x
				var pz: float = near+corner.y
				mesh.set_uv(Vector2(px,pz)/2.)
				mesh.add_vertex(Vector3(px,ground(px,pz),pz))
	mesh.generate_normals()
	var geometry := mesh.commit()
	var land := mesh_part(chunk,geometry,Vector3.ZERO,Vector3.ONE,materials["grass"])
	land.create_trimesh_collision()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	for i in range(15):
		var x := key.x*CHUNK+rng.randf_range(1,15)
		var z := key.y*CHUNK+rng.randf_range(1,15)
		if Vector2(x,z).length()<5:
			continue
		var kind := "tree" if i<6 else "stone" if i<9 else "stick" if i<12 else "rabbit" if i==12 else "vine_bush"
		var id := "%s:%s:%s" % [key.x,key.y,i]
		var at := Vector3(x,ground(x,z),z)
		if kind == "rabbit":
			if not removed.has(id):
				creature(kind,id,at,chunk)
		elif not removed.has(id):
			spawn_object(kind,id,at,chunk)

func village() -> void:
	spawn_friendly_goblin("Bruma",Vector3(-2,0,-4))
	spawn_friendly_goblin("Talo",Vector3(2,0,-5))
	if not removed.has("fire"):
		spawn_object("fire","fire",Vector3(0,0,-6))
	if hut and not won and not removed.has("guardiao"):
		creature("guardian","guardiao",Vector3(3,0,-39),self)
	for entry in placed:
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
	var visual := Node3D.new()
	visual.name = "Visual"
	npc.add_child(visual)
	goblin(visual,Color("#9b4b78") if kind=="Bruma" else Color("#866342"))
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
		if distance_home>NPC_PATROL_RADIUS-.85:
			heading = delta_home.normalized()
			walking = true
			npc.set_meta("ai_state","idle")
			npc.set_meta("ai_until",elapsed+1.0)
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
		npc.move_and_slide()
		# O limite é aplicado após a física, mesmo quando há empurrões.
		var displacement := Vector2(npc.global_position.x-campfire.x,npc.global_position.z-campfire.z)
		if displacement.length()>NPC_PATROL_RADIUS:
			var border := displacement.normalized()*(NPC_PATROL_RADIUS-.04)
			npc.global_position = Vector3(campfire.x+border.x,npc.global_position.y,campfire.z+border.y)
			npc.velocity.x = 0.0
			npc.velocity.z = 0.0
		walk_pose(npc.get_node("Visual"),npc.get_real_velocity(),dt,npc.is_on_floor())

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

func spawn_object(kind: String,id: String, pos: Vector3, parent: Node3D = self, yaw: float = 0.0) -> StaticBody3D:
	var o := StaticBody3D.new()
	o.collision_layer = TARGET
	o.set_meta("kind",kind)
	o.set_meta("id",id)
	parent.add_child(o)
	o.position = pos
	o.rotation.y = yaw
	objects[id] = o
	match kind:
		"tree":
			o.collision_layer |= SOLID
			var visual := Node3D.new()
			visual.name = "Visual"
			o.add_child(visual)
			cylinder(visual,Vector3(0,1.1,0),.18,2.2,"wood",Color("#855b36"))
			for i in range(4):
				var a := i*TAU/4
				ball(visual,Vector3(cos(a)*.42,2.24+i*.18,sin(a)*.42),Vector3(1.5,1.35,1.38),"leaf"+str(i),Color("#456a38").lightened(i*.055))
			collider(o,Vector3(.39,2.7,.39),Vector3.UP*1.35)
		"stone","block":
			o.collision_layer |= SOLID
			mesh_part(o,rock_mesh,Vector3.UP*CELL/2,Vector3.ONE,materials["rock"])
			collider(o,Vector3.ONE*CELL,Vector3.UP*CELL/2)
		"log":
			var log_mesh := cylinder(o,Vector3(0,.18,0),.17,.61,"wood",Color("#855b36"))
			log_mesh.rotation.z = PI/2
			collider(o,Vector3(.68,.39,.43),Vector3.UP*.19)
		"plank":
			box(o,Vector3(0,.04,0),Vector3(.59,.075,.26),"plank",Color("#ac7749"))
			collider(o,Vector3(.61,.21,.29),Vector3.UP*.10)
		"stick":
			var twig := cylinder(o,Vector3(0,.07,0),.06,.55,"wood",Color("#855b36"))
			twig.rotation.z = PI/2
			collider(o,Vector3(.61,.23,.29),Vector3.UP*.10)
		"bench","bench2":
			o.collision_layer |= SOLID
			for x in [-.39,.39]:
				for z in [-.25,.25]:
					cylinder(o,Vector3(x,.38,z),.08,.76,"wood",Color("#855b36"))
			if kind=="bench2":
				# Bancada reforçada: quatro pernas de tronco e tampo único de pedra.
				box(o,Vector3(0,.78,0),Vector3(1.04,.20,.77),"stone_counter",Color("#69706b"))
				for segment in [-.36,.0,.36]:
					box(o,Vector3(segment,.892,0),Vector3(.025,.018,.72),"stone_joint",Color("#454b46"))
			else:
				for i in range(3):
					box(o,Vector3(0,.81,(i-1)*.23),Vector3(1.02,.14,.22),"plank",Color("#ac7749"))
			collider(o,Vector3(1.04,.93,.80),Vector3.UP*.465)
		"hut":
			o.collision_layer |= SOLID
			box(o,Vector3(0,.73,0),Vector3(2,1.46,1.7),"plank",Color("#ac7749"))
			for side in [-1,1]:
				var roof := box(o,Vector3(side*.47,1.72,0),Vector3(1.21,.14,1.93),"roof",Color("#66432d"))
				roof.rotation.z = side*-.48
			collider(o,Vector3(2,1.95,1.7),Vector3.UP*.975)
		"Bruma","Talo":
			o.collision_layer |= SOLID
			goblin(o,Color("#9b4b78") if kind=="Bruma" else Color("#866342"))
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
		"stone_axe":
			var tool := Node3D.new()
			o.add_child(tool)
			tool.position = Vector3(0,.10,0)
			tool.rotation.x = PI/2
			cylinder(tool,Vector3.ZERO,.035,.74,"wood",Color("#855b36"))
			make_stone_axe_head(tool)
			collider(o,Vector3(.4,.22,.76),Vector3.UP*.11)
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
		var high := CELL*2.0
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
	parent.add_child(body)
	body.position = at
	body.set_meta("kind",kind)
	body.set_meta("id",id)
	body.set_meta("hp",2 if kind=="rabbit" else 5 if kind=="wolf" else 9)
	mobs.append(body)
	var visual := Node3D.new()
	visual.name = "Visual"
	body.add_child(visual)
	if kind=="guardian":
		goblin(visual,Color("#784d88"))
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

func timber(tree: Node3D, fell: bool) -> void:
	var visual := tree.get_node("Visual") as Node3D
	if visual.has_meta("reaction"):
		visual.get_meta("reaction").kill()
	var direction := tree.global_position-player.global_position
	var axis := Vector3(direction.z,0,-direction.x).normalized()
	if axis.is_zero_approx():
		axis = Vector3.RIGHT
	if fell:
		var keep := visual.global_transform
		visual.reparent(self,false)
		visual.global_transform = keep
		remove_object(tree)
		var fall := visual.create_tween()
		fall.tween_property(visual,"quaternion",Quaternion(axis,PI*.49),.57).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fall.tween_interval(.35)
		fall.tween_property(visual,"scale",Vector3.ONE*.02,.26).set_trans(Tween.TRANS_SINE)
		fall.tween_callback(visual.queue_free)
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
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel = PanelContainer.new()
	layer.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -245
	panel.offset_right = 245
	panel.offset_top = -190
	panel.offset_bottom = 170
	menu = VBoxContainer.new()
	panel.add_child(menu)

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
		if item>=0 and stock[item]<=0 and reserve[item]<=0:
			inventory_slots[index] = -1
	for item in range(ITEMS.size()):
		if (stock[item]>0 or reserve[item]>0) and not inventory_slots.has(item):
			var free := inventory_slots.find(-1)
			if free>=0:
				inventory_slots[free] = item

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
	stamina_bar.value = stamina
	life_text.text = "Vida %d/100" % health
	stamina_text.text = "Recuperando o fôlego" if exhausted else "Fôlego %d/100" % roundi(stamina)
	for i in range(HOTBAR_SIZE):
		var active := i==selected
		var style := slot_active if active else slot_idle
		if hotbar_frames[i].get_theme_stylebox("panel")!=style:
			hotbar_frames[i].add_theme_stylebox_override("panel",style)
		var item: int = bar_items[i]
		hotbar_icons[i].texture = ITEM_ICONS[item] if item>=0 else null
		hotbar_slots[i].text = ""
		hotbar_frames[i].tooltip_text = ITEMS[item] if item>=0 else "Atalho vazio"
		hotbar_counts[i].text = "×%d" % stock[item] if item>=0 else ""
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

func clear_menu() -> void:
	center_panel.call_deferred()
	for child in menu.get_children():
		menu.remove_child(child)
		child.queue_free()

func center_panel() -> void:
	var minimum := panel.get_combined_minimum_size()
	var width := maxf(490.,minimum.x)
	var height := minimum.y
	panel.offset_left = -width/2.
	panel.offset_right = width/2.
	panel.offset_top = -height/2.
	panel.offset_bottom = height/2.

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

func show_menu() -> void:
	panel.remove_theme_stylebox_override("panel")
	moving = false
	inventory = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.show()
	clear_menu()
	label("Clareira dos Goblins")
	label(BUILD_TAG)
	var portrait := TextureRect.new()
	portrait.texture = preload("res://protagonista.jpg")
	portrait.custom_minimum_size = Vector2(92,125)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	menu.add_child(portrait)
	label("WASD andar · Shift correr · Espaço pular · X agachar")
	label("Mouse para mirar · Direito pegar/usar · Esquerdo atacar/construir")
	label("E inventário · B abrigo · Q largar · V câmera · 1–9 selecionar")
	button("Jogar / continuar", begin)
	address = LineEdit.new()
	address.placeholder_text = "IP do anfitrião na rede local"
	menu.add_child(address)
	button("Hospedar na rede local", host_game)
	button("Entrar na rede local", join_game)
	if not feedback.is_empty():
		label(feedback)
	button("Salvar e sair", func(): save_game(); get_tree().quit())

func begin() -> void:
	panel.hide()
	inventory = false
	moving = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func open_craft(mode: String) -> void:
	inventory = true
	craft_mode = mode
	craft_material = -1
	craft_cells.resize(4 if mode=="basic" else 9)
	craft_cells.fill(Vector2i(-1,0))
	show_inventory()

func show_inventory() -> void:
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
	title.text = "Fabricação"
	var station_label := Label.new()
	station_label.text = "Bancada de trabalho · Nível %d" % station_level if craft_mode=="station" else "Inventário e fabricação básica"
	station_label.modulate = Color("#cfb791")
	menu.add_child(station_label)
	title.add_theme_font_size_override("font_size",23)
	title.modulate = Color("#ffe29c")
	menu.add_child(title)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",16)
	menu.add_child(columns)
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	var inventory_side := VBoxContainer.new()
	columns.add_child(inventory_side)
	var inventory_grid := GridContainer.new()
	inventory_grid.columns = 4
	var caption := Label.new()
	caption.text = "Inventário"
	caption.add_theme_font_size_override("font_size",20)
	caption.modulate = Color("#ffe29c")
	inventory_side.add_child(caption)
	inventory_side.add_child(inventory_grid)
	for slot_index in range(inventory_slots.size()):
		var kind: int = inventory_slots[slot_index]
		var item := Button.new()
		item.custom_minimum_size = Vector2(92,55)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		if kind>=0:
			var available := craft_available(kind)
			item.text = "×%d" % available if available>0 else ""
			item.tooltip_text = ITEMS[kind]
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
	var craft_side := HBoxContainer.new()
	craft_side.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_child(craft_side)
	var grid := GridContainer.new()
	grid.columns = 2 if craft_mode=="basic" else 3
	craft_side.add_child(grid)
	for i in range(craft_cells.size()):
		var slot := Button.new()
		var cell := craft_cells[i]
		slot.custom_minimum_size = Vector2(68,49)
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
	result.custom_minimum_size = Vector2(126,68)
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
	menu.add_child(explanation)
	var recipes := GridContainer.new()
	recipes.columns = 4
	menu.add_child(recipes)
	var names: Array = ["plank","fire","bench","rope"]
	if craft_mode=="station":
		names.append_array(STATION_PATTERNS.keys())
	for kind: String in names:
		var recipe_button := Button.new()
		recipe_button.text = "Preparar "+CRAFT_OUTPUT[kind]
		recipe_button.pressed.connect(prepare_recipe.bind(kind))
		style_craft_button(recipe_button)
		recipes.add_child(recipe_button)
	var clear_button := Button.new()
	clear_button.text = "Limpar grade"
	clear_button.pressed.connect(clear_craft)
	style_craft_button(clear_button)
	recipes.add_child(clear_button)
	menu.add_child(HSeparator.new())
	var hotbar_title := Label.new()
	hotbar_title.text = "Atalhos 1–9 · arraste para reorganizar ou selecione e clique"
	menu.add_child(hotbar_title)
	var shortcut_row := HBoxContainer.new()
	shortcut_row.alignment = BoxContainer.ALIGNMENT_CENTER
	menu.add_child(shortcut_row)
	for slot_index in range(HOTBAR_SIZE):
		var shortcut := Button.new()
		shortcut.custom_minimum_size = Vector2(58,43)
		shortcut.text = str(slot_index+1)
		var mapped: int = bar_items[slot_index]
		shortcut.tooltip_text = ITEMS[mapped] if mapped>=0 else "Espaço vazio"
		if mapped>=0:
			shortcut.icon = ITEM_ICONS[mapped]
		shortcut.pressed.connect(assign_hotbar.bind(slot_index))
		shortcut.set_drag_forwarding(hotbar_drag.bind(shortcut,slot_index),can_drop_hotbar.bind(slot_index),drop_hotbar.bind(slot_index))
		style_craft_button(shortcut)
		shortcut_row.add_child(shortcut)
	label("Selecione e clique para pôr 1 · Arraste para mover a pilha")
	label("Direito na grade retira 1 · Direito no inventário alterna a reserva")
	if stock[BACKPACK_ITEM]>0 or backpack_equipped:
		button("Abrir mochila (12 espaços)" if backpack_equipped else "Vestir mochila",open_backpack,true)
	if craft_mode=="station":
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

func inventory_drag(_position: Vector2, source: Control, slot_index: int) -> Variant:
	var item: int = inventory_slots[slot_index]
	if item<0 or craft_available(item)<=0:
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
	if inventory_slots[target_index]>=0:
		return false
	return int(data.get("inventory_slot",-1))>=0 or int(data.get("hotbar_slot",-1))>=0 or int(data.get("origin",-1))>=0

func drop_inventory(position: Vector2, data: Variant, target_index: int) -> void:
	if not can_drop_inventory(position,data,target_index):
		return
	var item := int(data["item"])
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
	match craft_mode:
		"station":
			return "Lanças, machados, mochila, paredes e bancada 2 com tampo de pedra."
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
	var pattern: Array = {"plank":[6,-1,-1,-1],"fire":FIRE_PATTERN,
		"bench":BENCH_PATTERN,"rope":[VINE,VINE,-1,-1]}.get(kind,STATION_PATTERNS.get(kind,[]))
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
	if counts[6]>=1 and total==counts[6]:
		return "plank"
	if craft_mode=="station":
		for kind: String in STATION_PATTERNS:
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
		return
	var costs: Dictionary = {
		"plank":{6:1},"fire":{1:2,2:1},"bench":{7:2,1:2},"spear":{2:1,1:2},"wood_spear":{1:3},"wood_axe":{1:3,7:2},"stone_axe":{1:3,2:2},"rope":{VINE:2},"backpack":{4:7,VINE:2},"bench2":{2:3,6:4,VINE:1},"wood_wall":{7:9},"wood_doorway":{7:7},"wood_window":{7:8}
	}[kind]
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
			show_backpack()
			return
	backpack_equipped = false
	backpack_visual.visible = false
	backpack_selected_item = -1
	save_game()
	show_inventory()

func find_wall_snap(point: Vector3, yaw: float) -> Vector3:
	# Novo segmento encaixa uma ponta à ponta da parede existente mais próxima.
	# Funciona tanto para paredes retas quanto para cantos em L/U.
	var new_axis := Basis(Vector3.UP,yaw).x.normalized()
	var best := point
	var best_distance := WALL_SIZE*.85
	for entry in placed:
		if entry.get("kind","") not in ["wood_wall","wood_doorway","wood_window"]:
			continue
		var p: Array = entry["p"]
		var old_position := Vector3(float(p[0]),float(p[1]),float(p[2]))
		var old_yaw := float(entry.get("r",0.0))
		var old_axis := Basis(Vector3.UP,old_yaw).x.normalized()
		for old_sign in [-1.0,1.0]:
			for new_sign in [-1.0,1.0]:
				var candidate: Vector3 = old_position+old_axis*(old_sign*WALL_SIZE*.5)-new_axis*(new_sign*WALL_SIZE*.5)
				var distance := Vector2(point.x-candidate.x,point.z-candidate.z).length()
				if distance<best_distance:
					best_distance = distance
					best = candidate
	return best

func wall_intersects_other_wall(point: Vector3, yaw: float) -> bool:
	# Impede duas paredes no mesmo lugar, mas permite os cantos de 90 graus.
	var axis := Vector2(cos(yaw),-sin(yaw))
	for entry in placed:
		if entry.get("kind","") not in ["wood_wall","wood_doorway","wood_window"]:
			continue
		var p: Array = entry["p"]
		var old := Vector2(float(p[0]),float(p[2]))
		var this := Vector2(point.x,point.z)
		var other_yaw := float(entry.get("r",0.0))
		var old_axis := Vector2(cos(other_yaw),-sin(other_yaw))
		var delta := this-old
		var aligned := absf(axis.dot(old_axis))>.95
		if aligned:
			if absf(delta.dot(axis))<WALL_SIZE-.12 and absf(delta.cross(axis))<.17:
				return true
		else:
			# Cruzes no meio da parede são bloqueados; cantos no final são permitidos.
			if absf(delta.dot(old_axis))<WALL_SIZE*.5-.14 and absf(delta.dot(axis))<WALL_SIZE*.5-.14:
				return true
	return false

func place_craft(kind: String) -> bool:
	var is_wall := kind in ["wood_wall","wood_doorway","wood_window"]
	var yaw := snappedf(player.rotation.y,PI/2.0) if is_wall else 0.0
	var forward := -Basis(Vector3.UP,yaw).z
	var point := player.position+forward*(2.15 if is_wall else 1.65)
	point.y = ground(point.x,point.z)
	if is_wall:
		point = find_wall_snap(point,yaw)
		# Evita colocar a segunda parede exatamente sobre a primeira.
		if wall_intersects_other_wall(point,yaw):
			notice("Esta posição já tem uma parede.")
			return false
	var shape := BoxShape3D.new()
	shape.size = Vector3(WALL_SIZE*.94,WALL_SIZE*.96,.16) if is_wall else Vector3(1.05,.84,.8)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(Vector3.UP,yaw),point+Vector3.UP*(WALL_SIZE*.5 if is_wall else .48))
	query.collision_mask = SOLID|TARGET|4
	if is_wall:
		# A análise geométrica acima protege contra sobreposição sem bloquear cantos.
		var skip_wall_rids: Array[RID] = []
		for obj in objects.values():
			if is_instance_valid(obj) and obj is CollisionObject3D and obj.get_meta("kind","") in ["wood_wall","wood_doorway","wood_window"]:
				skip_wall_rids.append(obj.get_rid())
		query.exclude = skip_wall_rids
	if not get_world_3d().direct_space_state.intersect_shape(query,12).is_empty():
		notice("Escolha um espaço livre à sua frente.")
		return false
	store_object(kind,point,yaw)
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
			KEY_B: build_hut()
			KEY_C: show_inventory()
			KEY_R: eat()
			KEY_F: primary()
			KEY_V: toggle_view()
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

func _physics_process(dt: float) -> void:
	elapsed += dt
	if moving:
		var f := float(Input.is_physical_key_pressed(KEY_W))-float(Input.is_physical_key_pressed(KEY_S))
		var s := float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
		var crouch := update_crouch(Input.is_physical_key_pressed(KEY_X))
		var running := sprint_step(not crouch and f>0 and Input.is_physical_key_pressed(KEY_SHIFT),dt)
		var speed := 2. if crouch else RUN_SPEED if running else WALK_SPEED
		var requested := player.basis*Vector3(s,0,-f).normalized()*speed
		player.velocity.x = move_toward(player.velocity.x,requested.x,dt*28)
		player.velocity.z = move_toward(player.velocity.z,requested.z,dt*28)
		if not player.is_on_floor():
			player.velocity.y -= dt*15
		elif jump and not crouch:
			player.velocity.y = 5.2
		jump = false
		player.move_and_slide()
		walk_pose(player_model,player.get_real_velocity(),dt,player.is_on_floor())
		eye_height = move_toward(eye_height,.96 if crouch else 1.49,dt*4.5)
		update_camera()
		var cell := Vector2i(floori(player.position.x/CHUNK),floori(player.position.z/CHUNK))
		if cell!=get_meta("chunk_center",Vector2i(100000,100000)):
			set_meta("chunk_center",cell)
			load_chunks()
		update_wolf_spawns(dt)
		update_mobs(dt)
		if elapsed>next_save:
			next_save = elapsed+8
			save_game()
	# A rotina dos NPCs é independente da movimentação do jogador e do menu.
	update_villagers(dt)
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status()==MultiplayerPeer.CONNECTION_CONNECTED and elapsed>next_net:
		next_net = elapsed+.10
		send_position.rpc(player.global_position,player.rotation.y)
	for remote in remotes.values():
		var destination: Vector3 = remote.get_meta("destination",remote.position)
		var next: Vector3 = remote.position.lerp(destination,1.-exp(-dt*16.))
		walk_pose(remote.get_child(0),(next-remote.position)/maxf(dt,.001),dt)
		remote.position = next
	var held: int = bar_items[selected]
	spear.visible = not third_person and held in [0,8]
	if spear.visible:
		spear_tip.material_override = materials["rock"] if held==0 else material("wood",Color("#855b36"))
	axe.visible = not third_person and held in [WOOD_AXE,STONE_AXE]
	wood_axe_head.visible = held==WOOD_AXE
	stone_axe_head.visible = false
	stone_axe_sprite.visible = axe.visible and held==STONE_AXE
	axe.get_node("CaboMachadoMadeira").visible = held==WOOD_AXE
	axe.rotation.x = -.44-sin(clampf((next_attack-elapsed)/.46,0,1)*PI)*.67
	spear.position.z = -.77-sin(clampf((next_attack-elapsed)/.46,0,1)*PI)*.31
	if elapsed>feedback_until and moving:
		feedback = ""
	hud.text = "Clareira dos Goblins  ·  "+("Vale conquistado" if won else "Explore o vale" if hut else "Construa a bancada e o abrigo")
	update_player_hud()
	if moving and elapsed>=next_interaction_hint:
		next_interaction_hint = elapsed+.12
		var hit := ray()
		interaction_hint = "E Inventário  ·  Esc Menu"
		if not hit.is_empty():
			match hit["collider"].get_meta("kind",""):
				"bench","bench2": interaction_hint = "Botão direito · Usar bancada de trabalho"
				"vine_bush": interaction_hint = "Botão direito · Colher cipó"
				"Bruma": interaction_hint = "Botão direito · Conversar com Bruma"
				"Talo": interaction_hint = "Botão direito · Conversar com Talo"
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
	if is_instance_valid(roaming_wolf) and not roaming_wolf.is_queued_for_deletion():
		if player.position.distance_to(roaming_wolf.position)>44.:
			roaming_wolf.queue_free()
		return
	if Vector2(player.position.x,player.position.z).length()<20.:
		return
	wolf_spawn_timer -= dt
	if wolf_spawn_timer>0.:
		return
	var space := get_world_3d().direct_space_state
	var clearance := SphereShape3D.new()
	clearance.radius = .60
	for attempt in range(8):
		var offset := Vector3.FORWARD.rotated(Vector3.UP,randf()*TAU)*randf_range(16.,24.)
		var position := player.position+offset
		if Vector2(position.x,position.z).length()<24.:
			continue
		position.y = ground(position.x,position.z)+.06
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = clearance
		query.transform.origin = position+Vector3.UP*.71
		query.collision_mask = SOLID|TARGET|4
		if not space.intersect_shape(query,1).is_empty():
			continue
		roaming_wolf = creature("wolf","lobo-errante",position,self)
		wolf_spawn_timer = randf_range(95.0,175.0)
		return
	wolf_spawn_timer = 12.0

func update_mobs(dt: float) -> void:
	for i in range(mobs.size()-1,-1,-1):
		var mob := mobs[i]
		if not is_instance_valid(mob) or mob.is_queued_for_deletion():
			mobs.remove_at(i)
			continue
		var direction := player.position-mob.global_position
		direction.y = 0
		var distance := direction.length()
		if distance>28:
			continue
		var kind: String = mob.get_meta("kind")
		var speed := 0.0
		if kind=="rabbit":
			update_rabbit(mob,direction,distance,dt)
			continue
		if distance<10:
			speed = 2.25
			if distance<1.35 and elapsed>next_hurt:
				next_hurt = elapsed+1
				health -= 15 if kind=="wolf" else 23
				if health<=0:
					respawn()
		if elapsed<float(mob.get_meta("stagger_until",0.0)):
			speed = 0.0
		var stride := direction.normalized()*speed
		mob.velocity.x = stride.x
		mob.velocity.z = stride.z
		if stride.length_squared()>.01:
			mob.rotation.y = atan2(-stride.x,-stride.z)
		if not mob.is_on_floor():
			mob.velocity.y -= dt*15
		mob.move_and_slide()
		walk_pose(mob.get_node("Visual"),mob.get_real_velocity(),dt,mob.is_on_floor())

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
	if held in [BENCH_ITEM,BENCH2_ITEM,FIRE_ITEM,WALL_ITEM,DOORWAY_ITEM,WINDOW_ITEM] and stock[held]>0:
		if place_craft(ITEM_KINDS[held]):
			stock[held] -= 1
			if held in [BENCH_ITEM,BENCH2_ITEM]:
				bench = true
			sync_hotbar()
			save_game()
			notice("Estrutura colocada no chão.")
		return
	var hit := ray()
	if hit.is_empty():
		return
	var o: Node3D = hit["collider"]
	var kind: String = o.get_meta("kind","")
	if kind in ["bench","bench2","fire","wood_wall","wood_doorway","wood_window"]:
		if held not in [WOOD_AXE,STONE_AXE]:
			notice("Use um machado para desmontar esta estrutura.")
			return
		var hits: int = int(o.get_meta("break_hits",0))+(2 if held==STONE_AXE else 1)
		var needed := 4 if kind in ["wood_wall","wood_doorway","wood_window","bench2"] else (3 if kind=="bench" else 2)
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
		notice("Estrutura recuperada para o inventário.")
		return
	if o.has_meta("hp"):
		if bar_items[selected] not in [0,8,WOOD_AXE,STONE_AXE]:
			notice("Equipe uma lança ou machado para atacar.")
			return
		var hp := maxi(0, int(o.get_meta("hp"))-(2 if bar_items[selected]==STONE_AXE else 1))
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
				store_object("meat",pos)
				if kind=="rabbit":
					store_object("hide",pos+Vector3(.41,0,0))
					if randf()<.05:
						store_object("foot",pos+Vector3(-.41,0,0))
		return
	if kind=="tree":
		var cuts_per_hit := 1
		match bar_items[selected]:
			WOOD_AXE: cuts_per_hit = 2
			STONE_AXE: cuts_per_hit = 4
		var cuts: int = o.get_meta("cuts",0)+cuts_per_hit
		o.set_meta("cuts",cuts)
		impact(hit["position"],hit["normal"],true)
		var pos := o.global_position
		timber(o,cuts>=4)
		if cuts>=4:
			for i in range(3):
				store_object("log",pos+Vector3((i-1)*.65,0,.39))
			notice("Árvore cortada. Recolha os troncos.")
		else:
			notice("Cortando a árvore: %d/4" % cuts)
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

func secondary() -> void:
	var hit := ray()
	if not hit.is_empty():
		var o: Node3D = hit["collider"]
		var kind: String = o.get_meta("kind","")
		var item := ITEM_KINDS.find(kind)
		if kind=="block":
			item = 2
		if kind=="vine_bush":
			item = VINE
		if kind in ["Bruma","Talo"]:
			speak_to_goblin(o)
			return
		if kind in ["bench","bench2"]:
			station_level = 2 if kind=="bench2" else 1
			open_craft("station")
			return
		if kind in ["fire","wood_wall","wood_doorway","wood_window"]:
			notice("Use um machado para desmontar esta estrutura.")
			return
		if item>=0:
			sync_hotbar()
			stock[item] += 2 if kind=="vine_bush" else 1
			item_received(item)
			sync_hotbar()
			remove_object(o)
			notice("Você recolheu "+ITEMS[item].to_lower()+".")
			return
		if kind=="Bruma" or kind=="Talo":
			notice("Monte uma bancada e um abrigo com os materiais da floresta.")
			return
	if bar_items[selected]==3:
		eat()

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
	if item in [BENCH_ITEM,BENCH2_ITEM,FIRE_ITEM,WALL_ITEM,DOORWAY_ITEM,WINDOW_ITEM]:
		if place_craft(ITEM_KINDS[item]):
			stock[item] -= 1
			if item in [BENCH_ITEM,BENCH2_ITEM]:
				bench = true
			sync_hotbar()
			save_game()
		return
	var p := player.position-player.basis.z*1.2
	p.y = ground(p.x,p.z)
	store_object(ITEM_KINDS[item],p)
	stock[item] -= 1

func eat() -> void:
	if stock[3]>0 and health<100:
		stock[3] -= 1
		health = mini(100,health+35)
		notice("Você recuperou vida.")

func bench_near() -> bool:
	for entry in placed:
		if entry["kind"] in ["bench","bench2"]:
			var p: Array = entry["p"]
			if player.position.distance_to(Vector3(p[0],p[1],p[2]))<3:
				return true
	return false

func build_hut() -> void:
	if hut:
		return
	if Vector2(player.position.x,player.position.z+6).length()>7:
		notice("Volte para perto da fogueira.")
		return
	if stock[1]<4 or stock[2]<2:
		notice("Abrigo: 4 gravetos e 2 pedras.")
		return
	stock[1] -= 4
	stock[2] -= 2
	hut = true
	store_object("hut",Vector3(-3,0,-7))
	creature("guardian","guardiao",Vector3(3,0,-39),self)
	notice("O guardião apareceu no Vale da Névoa.")

func store_object(kind: String, pos: Vector3, yaw: float = 0.0) -> void:
	var id := "item-"+str(Time.get_ticks_usec())+"-"+str(randi())
	placed.append({"kind":kind,"id":id,"p":[pos.x,pos.y,pos.z],"r":yaw})
	spawn_object(kind,id,pos,self,yaw)

func remove_object(o: Node3D) -> void:
	if o is CollisionObject3D:
		o.collision_layer = 0
	var id: String = o.get_meta("id")
	if id.begins_with("item-"):
		placed = placed.filter(func(entry): return entry["id"]!=id)
	elif id!="lobo-errante":
		removed[id] = true
	objects.erase(id)
	o.queue_free()

func notice(message: String) -> void:
	feedback = message
	feedback_until = elapsed+4

func load_game() -> void:
	if not FileAccess.file_exists(SAVE):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if not data is Dictionary:
		return
	var saved_stock: Array = data.get("stock",[])
	var saved_reserve: Array = data.get("reserve",[])
	for i in range(mini(ITEMS.size(),saved_stock.size())):
		stock[i] = int(saved_stock[i])
	for i in range(mini(ITEMS.size(),saved_reserve.size())):
		reserve[i] = int(saved_reserve[i])
	hotbar_manual = bool(data.get("hotbar_manual",false))
	backpack_equipped = bool(data.get("backpack_equipped",false)) and stock[BACKPACK_ITEM]>0
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
	removed = data.get("removed",{})
	placed = data.get("placed",[])
	health = int(data.get("health",100))
	hut = bool(data.get("hut",false))
	bench = bool(data.get("bench",false))
	won = bool(data.get("won",false))
	set_meta("spawn",data.get("pos",[0,1,0]))

func save_game() -> void:
	if not is_instance_valid(player):
		return
	sync_hotbar()
	var file := FileAccess.open(SAVE+".tmp",FileAccess.WRITE)
	if file:
		var p := player.position
		file.store_string(JSON.stringify({"stock":stock,"bar_items":bar_items,"reserve":reserve,"removed":removed,
			"placed":placed,"health":health,"hut":hut,"bench":bench,"won":won,"pos":[p.x,p.y,p.z],
			"backpack_equipped":backpack_equipped,"backpack_slots":serialize_backpack(),"hotbar_manual":hotbar_manual,"inventory_slots":inventory_slots}))
		file.close()
		DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE+".tmp"),ProjectSettings.globalize_path(SAVE))

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func host_game() -> void:
	disconnect_game()
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(24650,8)!=OK:
		notice("Não foi possível abrir a porta UDP 24650.")
		show_menu()
		return
	multiplayer.multiplayer_peer = peer
	notice("Rede local ativa na porta UDP 24650.")
	begin()

func join_game() -> void:
	var ip := address.text.strip_edges()
	if ip.is_empty():
		notice("Informe o IP do anfitrião.")
		show_menu()
		return
	disconnect_game()
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(ip,24650)!=OK:
		notice("Não foi possível iniciar a conexão.")
		show_menu()
		return
	multiplayer.multiplayer_peer = peer
	notice("Conectando a "+ip+"…")
	begin()

@rpc("any_peer","call_remote","unreliable_ordered")
func send_position(pos: Vector3,facing: float) -> void:
	if not pos.is_finite() or not is_finite(facing):
		return
	var id := multiplayer.get_remote_sender_id()
	if not remotes.has(id):
		var avatar := Node3D.new()
		add_child(avatar)
		var visual := Node3D.new()
		avatar.add_child(visual)
		visual.rotation.y = PI
		goblin(visual,Color("#895938"),true)
		avatar.position = pos
		remotes[id] = avatar
	var remote: Node3D = remotes[id]
	if remote.position.distance_to(pos)>15.:
		remote.position = pos
	remote.set_meta("destination",pos)
	remote.rotation.y = facing

func remove_remote(id: int) -> void:
	if remotes.has(id):
		remotes[id].queue_free()
		remotes.erase(id)

func disconnect_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	for id in remotes.keys():
		remove_remote(id)

func disconnected() -> void:
	for id in remotes.keys():
		remove_remote(id)
	multiplayer.multiplayer_peer = null
	notice("Conexão de rede encerrada.")
	show_menu()
